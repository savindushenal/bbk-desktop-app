"""
WebSocket Manager - Manages WebSocket connections and broadcasts events
"""

from fastapi import WebSocket
from typing import List, Dict
import json
import logging

logger = logging.getLogger(__name__)


class WebSocketManager:
    def __init__(self):
        """Initialize WebSocket manager"""
        self.active_connections: List[WebSocket] = []
        logger.info("WebSocket manager initialized")
    
    async def connect(self, websocket: WebSocket):
        """Accept new WebSocket connection"""
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(f"New WebSocket connection. Total active: {len(self.active_connections)}")
    
    def disconnect(self, websocket: WebSocket):
        """Remove WebSocket connection"""
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
            logger.info(f"WebSocket disconnected. Total active: {len(self.active_connections)}")
    
    async def broadcast(self, message: Dict):
        """
        Broadcast message to all connected clients
        
        Args:
            message: Dictionary to send as JSON
        """
        if not self.active_connections:
            logger.warning("No active WebSocket connections to broadcast to")
            return
        
        # Convert message to JSON string
        json_message = json.dumps(message)
        
        # Send to all connections
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_text(json_message)
            except Exception as e:
                logger.error(f"Error sending to WebSocket: {e}")
                disconnected.append(connection)
        
        # Remove dead connections
        for conn in disconnected:
            self.disconnect(conn)
    
    async def send_to(self, websocket: WebSocket, message: Dict):
        """
        Send message to specific WebSocket connection
        
        Args:
            websocket: Target WebSocket
            message: Dictionary to send as JSON
        """
        try:
            await websocket.send_json(message)
        except Exception as e:
            logger.error(f"Error sending to specific WebSocket: {e}")
            self.disconnect(websocket)
    
    def get_connection_count(self) -> int:
        """Get number of active connections"""
        return len(self.active_connections)
