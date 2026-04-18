from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from typing import Dict, List
import json
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Echo-Sync Signaling Server")

class ConnectionManager:
    def __init__(self):
        # Maps room_id to a list of WebSockets
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, room_id: str):
        await websocket.accept()
        if room_id not in self.active_connections:
            self.active_connections[room_id] = []
        self.active_connections[room_id].append(websocket)
        logger.info(f"Client connected to room: {room_id}")

    def disconnect(self, websocket: WebSocket, room_id: str):
        if room_id in self.active_connections:
            if websocket in self.active_connections[room_id]:
                self.active_connections[room_id].remove(websocket)
            if len(self.active_connections[room_id]) == 0:
                del self.active_connections[room_id]
        logger.info(f"Client disconnected from room: {room_id}")

    async def broadcast_to_room_except(self, message: str, room_id: str, sender: WebSocket):
        if room_id in self.active_connections:
            for connection in self.active_connections[room_id]:
                if connection != sender:
                    await connection.send_text(message)

manager = ConnectionManager()

@app.websocket("/ws/{room_id}")
async def websocket_endpoint(websocket: WebSocket, room_id: str):
    await manager.connect(websocket, room_id)
    try:
        while True:
            data = await websocket.receive_text()
            # The FastAPI backend strictly forwards offers and candidates to peers in the same room.
            logger.debug(f"Received message in {room_id}")
            await manager.broadcast_to_room_except(data, room_id, websocket)
    except WebSocketDisconnect:
        manager.disconnect(websocket, room_id)

@app.get("/")
def health_check():
    return {"status": "Signaling server is running"}
