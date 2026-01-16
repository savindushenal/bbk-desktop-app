"""
BBK Gym Hardware Bridge - Python Service
FastAPI-based service for hardware communication
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import asyncio
import logging
from datetime import datetime
from typing import Dict, List, Optional
import json
from pathlib import Path

from fingerprint_service import FingerprintService
from doorlock_service import DoorLockService
from websocket_manager import WebSocketManager

# Create logs directory if it doesn't exist
import os
os.makedirs('logs', exist_ok=True)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/python-bridge.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Global services
fingerprint_service: Optional[FingerprintService] = None
doorlock_service: Optional[DoorLockService] = None
ws_manager: WebSocketManager = WebSocketManager()

# WebSocket connection tracking
mirror_connections = set()
attendance_connections = set()


# Load configuration
def load_config():
    """Load configuration from config.json"""
    config_path = Path(__file__).parent.parent / "config.json"
    if config_path.exists():
        with open(config_path, 'r') as f:
            return json.load(f)
    return None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifecycle manager"""
    global fingerprint_service, doorlock_service
    
    # Startup
    logger.info("Starting Python Hardware Bridge...")
    
    # Load config
    config = load_config()
    
    try:
        # Initialize door lock service (optional)
        try:
            doorlock_port = "COM7"  # default
            doorlock_baudrate = 9600  # default
            if config and "hardware" in config and "doorlock" in config["hardware"]:
                doorlock_port = config["hardware"]["doorlock"].get("port", "COM7")
                doorlock_baudrate = config["hardware"]["doorlock"].get("baudrate", 9600)
            
            logger.info(f"Initializing door lock on {doorlock_port} @ {doorlock_baudrate} baud")
            doorlock_service = DoorLockService(port=doorlock_port, baudrate=doorlock_baudrate)
            if doorlock_service.connect():
                logger.info("[OK] Door lock service initialized")
            else:
                logger.warning("[WARN] Door lock not available - continuing without it")
                doorlock_service = None
        except Exception as e:
            logger.warning(f"[WARN] Door lock not available: {e}")
            doorlock_service = None
        
        # Initialize fingerprint service (optional)
        try:
            fingerprint_ip = "192.168.1.201"  # default
            fingerprint_port = 4370  # default
            if config and "hardware" in config and "fingerprint" in config["hardware"]:
                fingerprint_ip = config["hardware"]["fingerprint"].get("ip", "192.168.1.201")
                fingerprint_port = config["hardware"]["fingerprint"].get("port", 4370)
            
            logger.info(f"Initializing fingerprint device at {fingerprint_ip}:{fingerprint_port}")
            fingerprint_service = FingerprintService(ip=fingerprint_ip, port=fingerprint_port)
            if fingerprint_service.connect():
                logger.info("[OK] Fingerprint service initialized")
            else:
                logger.warning("[WARN] Fingerprint device not connected")
                fingerprint_service = None
        except Exception as e:
            logger.warning(f"[WARN] Fingerprint service not available: {e}")
            fingerprint_service = None
        
        logger.info("[STARTED] Python Bridge started (hardware optional mode)")
        
        yield
        
    except Exception as e:
        logger.error(f"Failed to initialize services: {e}")
        # Continue anyway - hardware is optional
        yield
    finally:
        # Shutdown
        logger.info("Shutting down services...")
        if fingerprint_service:
            fingerprint_service.disconnect()
        if doorlock_service:
            doorlock_service.disconnect()
        logger.info("Services stopped")


# Create FastAPI app
app = FastAPI(
    title="BBK Hardware Bridge",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== Health Check ====================

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat(),
        "services": {
            "fingerprint": {
                "connected": fingerprint_service.is_connected() if fingerprint_service else False,
                "device_info": fingerprint_service.get_device_info() if fingerprint_service else None
            },
            "doorlock": {
                "connected": doorlock_service.is_connected() if doorlock_service else False,
                "port": doorlock_service.port if doorlock_service else None
            }
        }
    }


# ==================== WebSocket Endpoint ====================

@app.websocket("/ws/events")
async def websocket_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for real-time hardware events
    Electron connects here to receive finger scans, device status, etc.
    """
    await ws_manager.connect(websocket)
    logger.info(f"WebSocket client connected: {websocket.client}")
    
    try:
        while True:
            # Keep connection alive and listen for commands from Electron
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Handle commands from Electron
            await handle_electron_command(message, websocket)
            
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
        logger.info(f"WebSocket client disconnected: {websocket.client}")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        ws_manager.disconnect(websocket)


async def handle_electron_command(message: Dict, websocket: WebSocket):
    """Handle commands from Electron"""
    command = message.get("action")
    payload = message.get("payload", {})
    request_id = message.get("request_id")
    
    try:
        if command == "enroll_fingerprint":
            result = await enroll_fingerprint_command(payload)
        elif command == "get_users":
            result = await get_users_command()
        elif command == "delete_user":
            result = await delete_user_command(payload)
        elif command == "sync_user":
            result = await sync_user_command(payload)
        elif command == "reconnect_device":
            result = await reconnect_device_command()
        else:
            result = {"success": False, "error": "Unknown command"}
        
        # Send response back to Electron
        await websocket.send_json({
            "type": "response",
            "request_id": request_id,
            "data": result
        })
        
    except Exception as e:
        await websocket.send_json({
            "type": "response",
            "request_id": request_id,
            "data": {"success": False, "error": str(e)}
        })


# ==================== Fingerprint Endpoints ====================

@app.post("/fingerprint/connect")
async def connect_fingerprint(ip: str = "192.168.1.201", port: int = 4370):
    """Connect to fingerprint device"""
    try:
        fingerprint_service.ip = ip
        fingerprint_service.port = port
        fingerprint_service.connect()
        return {
            "success": True,
            "message": "Connected to fingerprint device",
            "device_info": fingerprint_service.get_device_info()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/fingerprint/disconnect")
async def disconnect_fingerprint():
    """Disconnect from fingerprint device"""
    try:
        fingerprint_service.disconnect()
        return {"success": True, "message": "Disconnected from fingerprint device"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/fingerprint/enroll")
async def enroll_fingerprint(user_id: int, finger_id: int = 1):
    """
    Enroll a new fingerprint
    user_id: Unique member ID
    finger_id: Finger slot (1-10)
    """
    try:
        result = await fingerprint_service.enroll_user(user_id, finger_id)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/fingerprint/users")
async def get_users():
    """Get all users from fingerprint device"""
    try:
        users = fingerprint_service.get_users()
        return {
            "success": True,
            "count": len(users),
            "users": [
                {
                    "uid": user.uid,
                    "user_id": user.user_id,
                    "name": user.name,
                    "privilege": user.privilege
                }
                for user in users
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/fingerprint/user/{user_id}")
async def delete_user(user_id: int):
    """Delete user from fingerprint device"""
    try:
        result = fingerprint_service.delete_user(user_id)
        return {"success": True, "message": f"User {user_id} deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/fingerprint/attendance")
async def get_attendance():
    """Get attendance records from device"""
    try:
        records = fingerprint_service.get_attendance()
        return {
            "success": True,
            "count": len(records),
            "records": [
                {
                    "user_id": record.user_id,
                    "timestamp": record.timestamp.isoformat(),
                    "punch_type": record.punch
                }
                for record in records
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/fingerprint/clear-attendance")
async def clear_attendance():
    """Clear all attendance records from device"""
    try:
        fingerprint_service.clear_attendance()
        return {"success": True, "message": "Attendance cleared"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Door Lock Endpoints ====================

@app.post("/doorlock/open")
async def open_door(duration: int = 5):
    """
    Open door lock for specified duration (seconds)
    """
    try:
        result = doorlock_service.open_door(duration)
        return {
            "success": True,
            "message": f"Door opened for {duration} seconds",
            "duration": duration
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/doorlock/close")
async def close_door():
    """Close door lock immediately"""
    try:
        doorlock_service.close_door()
        return {"success": True, "message": "Door closed"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/doorlock/status")
async def door_status():
    """Get door lock status"""
    try:
        return {
            "success": True,
            "connected": doorlock_service.is_connected(),
            "port": doorlock_service.port,
            "baudrate": doorlock_service.baudrate
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Command Handlers ====================

async def enroll_fingerprint_command(payload: Dict):
    """Handle enrollment command from Electron"""
    user_id = payload.get("user_id")
    finger_id = payload.get("finger_id", 1)
    
    if not user_id:
        return {"success": False, "error": "user_id is required"}
    
    result = await fingerprint_service.enroll_user(user_id, finger_id)
    return result


async def get_users_command():
    """Handle get users command"""
    users = fingerprint_service.get_users()
    return {
        "success": True,
        "users": [{"uid": u.uid, "user_id": u.user_id, "name": u.name} for u in users]
    }


async def delete_user_command(payload: Dict):
    """Handle delete user command"""
    user_id = payload.get("user_id")
    if not user_id:
        return {"success": False, "error": "user_id is required"}
    
    fingerprint_service.delete_user(user_id)
    return {"success": True, "message": f"User {user_id} deleted"}


async def sync_user_command(payload: Dict):
    """Handle sync user command (add user with template)"""
    # This would require template data from cloud
    # Implementation depends on your cloud API structure
    return {"success": True, "message": "Sync not yet implemented"}


async def reconnect_device_command():
    """Handle device reconnection"""
    try:
        fingerprint_service.reconnect()
        return {"success": True, "message": "Device reconnected"}
    except Exception as e:
        return {"success": False, "error": str(e)}


# ==================== Screen Mirror WebSocket ====================

@app.websocket("/ws/mirror")
async def mirror_websocket(websocket: WebSocket):
    """Screen mirroring WebSocket for employee dashboard → member screen"""
    global mirror_connections
    await websocket.accept()
    mirror_connections.add(websocket)
    logger.info(f"[Mirror] New connection. Total: {len(mirror_connections)}")
    
    try:
        while True:
            data = await websocket.receive_json()
            logger.info(f"[Mirror] Broadcasting: {data.get('action')} - {data.get('type')}")
            
            # Broadcast to all OTHER connected screens (don't send back to sender)
            disconnected = set()
            for conn in mirror_connections:
                if conn != websocket:
                    try:
                        await conn.send_json(data)
                        logger.info(f"[Mirror] Sent to connection successfully")
                    except Exception as e:
                        logger.warning(f"[Mirror] Failed to send to connection: {e}")
                        disconnected.add(conn)
            
            # Remove disconnected clients
            for conn in disconnected:
                mirror_connections.discard(conn)
    
    except WebSocketDisconnect:
        mirror_connections.discard(websocket)
        logger.info(f"[Mirror] Client disconnected. Remaining: {len(mirror_connections)}")
    except Exception as e:
        logger.error(f"[Mirror] Error: {e}")
        mirror_connections.discard(websocket)


@app.websocket("/ws/attendance")
async def attendance_websocket(websocket: WebSocket):
    """Attendance WebSocket for fingerprint events"""
    global attendance_connections
    await websocket.accept()
    attendance_connections.add(websocket)
    logger.info(f"[Attendance] New connection. Total: {len(attendance_connections)}")
    
    try:
        # Keep connection alive, just receive data but don't process
        while True:
            await websocket.receive_text()
    
    except WebSocketDisconnect:
        attendance_connections.discard(websocket)
        logger.info(f"[Attendance] Client disconnected. Remaining: {len(attendance_connections)}")
    except Exception as e:
        logger.error(f"[Attendance] Error: {e}")
        attendance_connections.discard(websocket)


# ==================== Root Endpoint ====================

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "BBK Hardware Bridge",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "health": "/health",
            "websocket": "/ws/events",
            "docs": "/docs"
        }
    }


if __name__ == "__main__":
    import uvicorn
    
    # Use simple logging config to avoid stdout.isatty() errors in frozen EXE
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info",
        access_log=False,
        log_config=None  # Disable uvicorn's custom log config
    )
