"""WebSocket connection manager partagé pour le support chat."""
from typing import Any
from fastapi import WebSocket


class WsManager:
    def __init__(self) -> None:
        self._rooms: dict[str, list[WebSocket]] = {}

    async def connect(self, room_id: str, ws: WebSocket) -> None:
        await ws.accept()
        self._rooms.setdefault(room_id, []).append(ws)

    def disconnect(self, room_id: str, ws: WebSocket) -> None:
        room = self._rooms.get(room_id, [])
        try:
            room.remove(ws)
        except ValueError:
            pass

    async def broadcast(self, room_id: str, payload: dict[str, Any]) -> None:
        for ws in list(self._rooms.get(room_id, [])):
            try:
                await ws.send_json(payload)
            except Exception:
                self.disconnect(room_id, ws)


ticket_ws_manager = WsManager()
