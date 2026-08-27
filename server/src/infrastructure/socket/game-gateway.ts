import type { Server, Socket } from "socket.io";
import { RoomService } from "../../application/room-service.js";
import { GameAction } from "../../domain/durak-engine.js";
import { GameState } from "../../domain/game-state.js";
import { toGameView } from "../game-view.js";

interface JoinRoomPayload {
  roomId: string;
  playerId: string;
  playerName: string;
}

interface GameActionPayload {
  roomId: string;
  action: GameAction;
}

/**
 * Tracks which socket currently represents which player in which room, so we
 * can push each player their own redacted view instead of one shared broadcast.
 */
class ConnectionRegistry {
  private byRoom = new Map<string, Map<string, string>>();

  register(roomId: string, playerId: string, socketId: string): void {
    const players = this.byRoom.get(roomId) ?? new Map();
    players.set(playerId, socketId);
    this.byRoom.set(roomId, players);
  }

  socketsFor(roomId: string): Map<string, string> {
    return this.byRoom.get(roomId) ?? new Map();
  }

  drop(socketId: string): void {
    for (const players of this.byRoom.values()) {
      for (const [playerId, sid] of players) {
        if (sid === socketId) players.delete(playerId);
      }
    }
  }
}

export function registerGameGateway(io: Server, roomService: RoomService): void {
  const registry = new ConnectionRegistry();

  function broadcastState(roomId: string, game: GameState): void {
    for (const [playerId, socketId] of registry.socketsFor(roomId)) {
      io.to(socketId).emit("game_state", toGameView(game, playerId));
    }
  }

  io.on("connection", (socket: Socket) => {
    socket.on("join_room", (payload: JoinRoomPayload) => {
      const { roomId, playerId, playerName } = payload;
      const room = roomService.getRoom(roomId);
      if (!room) {
        socket.emit("room_error", { message: "Room not found" });
        return;
      }

      const isHost = room.hostId === playerId;
      const isReturningGuest = room.guest?.id === playerId;
      if (!isHost && !isReturningGuest) {
        try {
          roomService.joinRoom(roomId, playerId, playerName);
        } catch (err) {
          socket.emit("room_error", { message: (err as Error).message });
          return;
        }
      }

      registry.register(roomId, playerId, socket.id);
      socket.join(roomId);

      const updated = roomService.getRoom(roomId);
      if (updated?.game) {
        broadcastState(roomId, updated.game);
      } else {
        socket.emit("waiting_for_opponent", { roomId });
      }
    });

    socket.on("game_action", ({ roomId, action }: GameActionPayload) => {
      let result;
      try {
        result = roomService.applyAction(roomId, action);
      } catch (err) {
        socket.emit("action_error", { message: (err as Error).message });
        return;
      }
      if (!result.ok) {
        socket.emit("action_error", { message: result.error });
        return;
      }
      broadcastState(roomId, result.state);
    });

    socket.on("disconnect", () => {
      registry.drop(socket.id);
    });
  });
}
