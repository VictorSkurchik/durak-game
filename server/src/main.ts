import cors from "cors";
import express from "express";
import { createServer } from "node:http";
import { Server } from "socket.io";
import { RoomService } from "./application/room-service.js";
import { createRoomsRouter } from "./infrastructure/http/rooms-router.js";
import { registerGameGateway } from "./infrastructure/socket/game-gateway.js";

const PORT = Number(process.env.PORT ?? 3000);

const app = express();
app.use(cors());
app.use(express.json());

const roomService = new RoomService();

app.get("/api/health", (_req, res) => res.json({ status: "ok" }));
app.use("/api", createRoomsRouter(roomService));

const httpServer = createServer(app);
const io = new Server(httpServer, { cors: { origin: "*" } });
registerGameGateway(io, roomService);

httpServer.listen(PORT, () => {
  console.log(`Durak server listening on http://localhost:${PORT}`);
});
