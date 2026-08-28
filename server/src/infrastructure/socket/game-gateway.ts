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
  private bySocket = new Map<string, { roomId: string; playerId: string }>();

  register(roomId: string, playerId: string, socketId: string): void {
    const players = this.byRoom.get(roomId) ?? new Map();
    players.set(playerId, socketId);
    this.byRoom.set(roomId, players);
    this.bySocket.set(socketId, { roomId, playerId });
  }

  socketsFor(roomId: string): Map<string, string> {
    return this.byRoom.get(roomId) ?? new Map();
  }

  /** Looks up which (roomId, playerId) a given socket is currently registered as. */
  find(socketId: string): { roomId: string; playerId: string } | undefined {
    return this.bySocket.get(socketId);
  }

  drop(socketId: string): void {
    const entry = this.bySocket.get(socketId);
    if (!entry) return;
    const players = this.byRoom.get(entry.roomId);
    if (players && players.get(entry.playerId) === socketId) {
      players.delete(entry.playerId);
    }
    this.bySocket.delete(socketId);
  }

  /** Removes a single player's registration from a room, e.g. on explicit leave. */
  unregister(roomId: string, playerId: string): void {
    const players = this.byRoom.get(roomId);
    const socketId = players?.get(playerId);
    if (socketId !== undefined) {
      this.bySocket.delete(socketId);
    }
    players?.delete(playerId);
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
    socket.on("join_room", (payload: any) => {
      try {
        const { roomId, playerId, playerName } = (payload ?? {}) as Partial<JoinRoomPayload>;
        const room = roomService.getRoom(roomId as string);
        if (!room) {
          socket.emit("room_error", { message: "Room not found" });
          return;
        }

        const isHost = room.hostId === playerId;
        const isReturningGuest = room.guest?.id === playerId;
        if (!isHost && !isReturningGuest) {
          try {
            roomService.joinRoom(roomId as string, playerId as string, playerName as string);
          } catch (err) {
            socket.emit("room_error", { message: (err as Error).message });
            return;
          }
        }

        registry.register(roomId as string, playerId as string, socket.id);
        socket.data.playerId = playerId;
        socket.data.roomId = roomId;

        if (room.game) {
          broadcastState(roomId as string, room.game);
        } else {
          socket.emit("waiting_for_opponent", { roomId });
        }
      } catch (err) {
        socket.emit("room_error", { message: (err as Error).message ?? "Invalid join_room payload" });
      }
    });

    socket.on("game_action", (payload: any) => {
      try {
        const { roomId, action } = (payload ?? {}) as Partial<GameActionPayload>;

        if (socket.data.playerId !== action?.playerId) {
          socket.emit("action_error", { message: "Cannot act as another player" });
          return;
        }

        let result;
        try {
          result = roomService.applyAction(roomId as string, action as GameAction);
        } catch (err) {
          socket.emit("action_error", { message: (err as Error).message });
          return;
        }
        if (!result.ok) {
          socket.emit("action_error", { message: result.error });
          return;
        }
        broadcastState(roomId as string, result.state);
      } catch (err) {
        socket.emit("action_error", { message: (err as Error).message ?? "Invalid game_action payload" });
      }
    });

    socket.on("leave_room", (payload: any) => {
      try {
        const { roomId, playerId } = (payload ?? {}) as { roomId?: string; playerId?: string };
        registry.unregister(roomId as string, playerId as string);
      } catch {
        // best-effort cleanup only
      }
    });

    socket.on("disconnect", () => {
      const entry = registry.find(socket.id);
      if (entry) {
        for (const [, socketId] of registry.socketsFor(entry.roomId)) {
          if (socketId !== socket.id) {
            io.to(socketId).emit("opponent_disconnected", {});
          }
        }
      }
      registry.drop(socket.id);
    });
  });
}
