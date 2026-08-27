import { randomUUID } from "node:crypto";
import { applyAction, createGame, GameAction } from "../domain/durak-engine.js";
import { GameState } from "../domain/game-state.js";

export interface Room {
  id: string;
  hostId: string;
  hostName: string;
  guest?: { id: string; name: string };
  game?: GameState;
}

/**
 * Holds active rooms in memory. Good enough for a demo/single-instance server;
 * a real deployment would swap this for a Redis- or DB-backed implementation
 * behind the same interface.
 */
export class RoomService {
  private rooms = new Map<string, Room>();

  createRoom(hostId: string, hostName: string): Room {
    const room: Room = { id: randomUUID().slice(0, 6).toUpperCase(), hostId, hostName };
    this.rooms.set(room.id, room);
    return room;
  }

  getRoom(roomId: string): Room | undefined {
    return this.rooms.get(roomId);
  }

  joinRoom(roomId: string, guestId: string, guestName: string): Room {
    const room = this.rooms.get(roomId);
    if (!room) throw new Error("Room not found");
    if (room.guest) throw new Error("Room is already full");
    if (room.hostId === guestId) throw new Error("Cannot join your own room twice");

    room.guest = { id: guestId, name: guestName };
    room.game = createGame(room.id, { id: room.hostId, name: room.hostName }, { id: guestId, name: guestName });
    return room;
  }

  applyAction(roomId: string, action: GameAction) {
    const room = this.rooms.get(roomId);
    if (!room?.game) throw new Error("Game has not started yet");
    const result = applyAction(room.game, action);
    if (result.ok) {
      room.game = result.state;
    }
    return result;
  }

  removeRoom(roomId: string): void {
    this.rooms.delete(roomId);
  }
}
