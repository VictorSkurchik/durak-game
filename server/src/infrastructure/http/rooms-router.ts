import { Router } from "express";
import { RoomService } from "../../application/room-service.js";

export function createRoomsRouter(roomService: RoomService): Router {
  const router = Router();

  router.post("/rooms", (req, res) => {
    const hostName = typeof req.body?.hostName === "string" ? req.body.hostName : "Player 1";
    const hostId = typeof req.body?.hostId === "string" ? req.body.hostId : undefined;
    if (!hostId) {
      res.status(400).json({ error: "hostId is required" });
      return;
    }
    const room = roomService.createRoom(hostId, hostName);
    res.status(201).json({ roomId: room.id, hostName: room.hostName });
  });

  router.get("/rooms/:roomId", (req, res) => {
    const room = roomService.getRoom(req.params.roomId);
    if (!room) {
      res.status(404).json({ error: "Room not found" });
      return;
    }
    res.json({
      roomId: room.id,
      hostName: room.hostName,
      hasGuest: Boolean(room.guest),
      started: Boolean(room.game),
    });
  });

  return router;
}
