"""
Fingerprint Service - ZKTeco Device Integration
Uses pyzk library to communicate with ZKTeco fingerprint devices
"""

from zk import ZK, const
from zk.user import User
from zk.finger import Finger
from zk.attendance import Attendance
from zk.exception import ZKErrorResponse, ZKNetworkError
import asyncio
import logging
from typing import List, Dict, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


class FingerprintService:
    def __init__(self, ip: str, port: int = 4370, timeout: int = 5, ws_manager=None):
        """
        Initialize fingerprint service
        
        Args:
            ip: IP address of fingerprint device
            port: Port number (default 4370)
            timeout: Connection timeout in seconds
            ws_manager: WebSocket manager for broadcasting events
        """
        self.ip = ip
        self.port = port
        self.timeout = timeout
        self.ws_manager = ws_manager
        self.event_loop = None  # Store reference to event loop
        
        self.zk = ZK(ip, port=port, timeout=timeout, password=0, force_udp=False, ommit_ping=False)
        self.conn = None
        self.is_capturing = False
        
        logger.info(f"Fingerprint service initialized for {ip}:{port}")
    
    def connect(self):
        """Connect to fingerprint device"""
        try:
            if self.conn:
                logger.warning("Already connected to device")
                return True
            
            logger.info(f"Connecting to fingerprint device at {self.ip}:{self.port}...")
            self.conn = self.zk.connect()
            
            # Disable device during setup
            self.conn.disable_device()
            
            # Get device info
            firmware = self.conn.get_firmware_version()
            serialno = self.conn.get_serialnumber()
            
            # Re-enable device
            self.conn.enable_device()
            
            logger.info(f"Connected successfully. Firmware: {firmware}, Serial: {serialno}")
            return True
            
        except ZKNetworkError as e:
            logger.error(f"Network error connecting to device: {e}")
            raise Exception(f"Cannot connect to device at {self.ip}:{self.port}")
        except Exception as e:
            logger.error(f"Error connecting to device: {e}")
            raise
    
    def disconnect(self):
        """Disconnect from fingerprint device"""
        try:
            self.is_capturing = False
            if self.conn:
                self.conn.disconnect()
                self.conn = None
                logger.info("Disconnected from fingerprint device")
        except Exception as e:
            logger.error(f"Error disconnecting: {e}")
    
    def reconnect(self):
        """Reconnect to device"""
        logger.info("Attempting to reconnect to device...")
        self.disconnect()
        asyncio.sleep(2)
        self.connect()
    
    def is_connected(self) -> bool:
        """Check if connected to device"""
        return self.conn is not None
    
    def get_device_info(self) -> Dict:
        """Get device information"""
        if not self.conn:
            return {"error": "Not connected"}
        
        try:
            return {
                "firmware": self.conn.get_firmware_version(),
                "serial_number": self.conn.get_serialnumber(),
                "platform": self.conn.get_platform(),
                "device_name": self.conn.get_device_name(),
                "face_version": self.conn.get_face_version() if hasattr(self.conn, 'get_face_version') else None,
                "fp_version": self.conn.get_fp_version() if hasattr(self.conn, 'get_fp_version') else None,
                "user_count": len(self.get_users()),
                "attendance_count": len(self.get_attendance())
            }
        except Exception as e:
            logger.error(f"Error getting device info: {e}")
            return {"error": str(e)}
    
    def get_users(self) -> List[User]:
        """Get all users from device"""
        if not self.conn:
            raise Exception("Not connected to device")
        
        try:
            users = self.conn.get_users()
            logger.info(f"Retrieved {len(users)} users from device")
            return users
        except Exception as e:
            logger.error(f"Error getting users: {e}")
            raise
    
    def get_attendance(self) -> List[Attendance]:
        """Get all attendance records from device"""
        if not self.conn:
            raise Exception("Not connected to device")
        
        try:
            attendances = self.conn.get_attendance()
            logger.info(f"Retrieved {len(attendances)} attendance records")
            return attendances
        except Exception as e:
            logger.error(f"Error getting attendance: {e}")
            raise
    
    def clear_attendance(self):
        """Clear all attendance records from device"""
        if not self.conn:
            raise Exception("Not connected to device")
        
        try:
            self.conn.clear_attendance()
            logger.info("Attendance records cleared")
        except Exception as e:
            logger.error(f"Error clearing attendance: {e}")
            raise
    
    async def enroll_user(self, user_id: int, finger_id: int = 1) -> Dict:
        """
        Enroll a new fingerprint
        
        Args:
            user_id: Unique user ID
            finger_id: Finger slot number (1-10)
        
        Returns:
            Dict with enrollment result
        """
        if not self.conn:
            raise Exception("Not connected to device")
        
        try:
            logger.info(f"Starting enrollment for user {user_id}, finger {finger_id}")
            
            # Disable device for enrollment
            self.conn.disable_device()
            
            # Check if user already exists
            existing_users = self.get_users()
            user_exists = any(u.user_id == str(user_id) for u in existing_users)
            
            if user_exists:
                logger.warning(f"User {user_id} already exists, will update fingerprint")
                # Delete existing user to re-enroll
                try:
                    self.conn.delete_user(uid=user_id)
                    logger.info(f"Deleted existing user {user_id}")
                except Exception as e:
                    logger.warning(f"Could not delete existing user: {e}")
            
            # Emit enrollment started event
            await self.emit_event({
                "type": "enrollment_started",
                "user_id": user_id,
                "finger_id": finger_id,
                "instructions": "Place finger on scanner - enrollment starting..."
            })
            
            # Enable device for enrollment
            self.conn.enable_device()
            
            logger.info(f"Starting enrollment for user {user_id} using conn.enroll_user()...")
            
            # This is the CORRECT way - use pyzk's built-in enroll_user method
            # This method:
            # 1. Puts device in enrollment mode
            # 2. Waits for user to scan finger 3 times
            # 3. Captures and stores fingerprint template automatically
            # 4. Is a blocking operation (will wait for real scans)
            
            # Run the blocking enroll_user in an executor to not block the async event loop
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(None, self.conn.enroll_user, user_id, finger_id)
            
            logger.info(f"Enrollment completed for user {user_id}")
            
            # Play success sound on device (if supported)
            try:
                self.conn.test_voice(0)
                logger.info("Played success sound on device")
            except Exception as e:
                logger.warning(f"Could not play voice: {e}")
            
            # Emit success event
            await self.emit_event({
                "type": "enrollment_complete",
                "user_id": user_id,
                "finger_id": finger_id,
                "success": True
            })
            
            return {
                "success": True,
                "user_id": user_id,
                "finger_id": finger_id,
                "message": "Fingerprint enrolled successfully"
            }
            
        except Exception as e:
            logger.error(f"Error during enrollment: {e}")
            
            # Re-enable device on error
            if self.conn:
                self.conn.enable_device()
            
            await self.emit_event({
                "type": "enrollment_error",
                "user_id": user_id,
                "error": str(e)
            })
            
            return {
                "success": False,
                "error": str(e)
            }
    
    def delete_user(self, user_id: int):
        """Delete user from device"""
        if not self.conn:
            raise Exception("Not connected to device")
        
        try:
            self.conn.disable_device()
            self.conn.delete_user(uid=user_id)
            self.conn.enable_device()
            logger.info(f"User {user_id} deleted from device")
        except Exception as e:
            if self.conn:
                self.conn.enable_device()
            logger.error(f"Error deleting user: {e}")
            raise
    
    async def start_live_capture(self):
        """
        Start live capture mode to detect finger scans in real-time
        This runs in the background and emits events when fingers are scanned
        """
        if not self.conn:
            logger.error("Cannot start live capture: not connected")
            return
        
        if self.is_capturing:
            logger.warning("Live capture already running")
            return
        
        self.is_capturing = True
        logger.info("Starting live capture mode...")
        
        # Save event loop reference for thread worker
        self.event_loop = asyncio.get_event_loop()
        
        # Run the blocking live_capture in a thread executor
        await self.event_loop.run_in_executor(None, self._live_capture_worker)
    
    def _live_capture_worker(self):
        """Worker function that runs in a thread to handle blocking live_capture"""
        try:
            logger.info("Live capture worker started")
            
            # This is a blocking generator that yields attendance records
            for attendance in self.conn.live_capture():
                if not self.is_capturing:
                    break
                
                if attendance:
                    logger.info(f"Finger detected: user_id={attendance.user_id}, time={attendance.timestamp}")
                    
                    # Emit event to WebSocket clients
                    if self.ws_manager:
                        # Create event data
                        event_data = {
                            "type": "finger_scanned",
                            "user_id": attendance.user_id,
                            "timestamp": attendance.timestamp.isoformat(),
                            "punch_type": attendance.punch,
                            "punch_name": self.get_punch_name(attendance.punch)
                        }
                        
                        # Schedule emit_event in the main event loop
                        asyncio.run_coroutine_threadsafe(
                            self.emit_event(event_data),
                            self.event_loop
                        )
                    
                    # Small delay to prevent overwhelming the system
                    import time
                    time.sleep(0.1)
        
        except ZKNetworkError as e:
            logger.error(f"Network error during live capture: {e}")
            if self.ws_manager and self.event_loop:
                asyncio.run_coroutine_threadsafe(
                    self.emit_event({
                        "type": "device_disconnected",
                        "error": str(e)
                    }),
                    self.event_loop
                )
        
        except Exception as e:
            logger.error(f"Error in live capture: {e}")
            if self.ws_manager and self.event_loop:
                asyncio.run_coroutine_threadsafe(
                    self.emit_event({
                        "type": "capture_error",
                        "error": str(e)
                    }),
                    self.event_loop
                )
        
        finally:
            self.is_capturing = False
            logger.info("Live capture stopped")
    
    def stop_live_capture(self):
        """Stop live capture mode"""
        self.is_capturing = False
        logger.info("Stopping live capture...")
    
    @staticmethod
    def get_punch_name(punch_code: int) -> str:
        """Convert punch code to readable name"""
        punch_types = {
            0: "check_in",
            1: "check_out",
            2: "break_out",
            3: "break_in",
            4: "ot_in",
            5: "ot_out"
        }
        return punch_types.get(punch_code, "unknown")
    
    async def emit_event(self, event: Dict):
        """Emit event to all connected WebSocket clients"""
        if self.ws_manager:
            await self.ws_manager.broadcast({
                **event,
                "timestamp": datetime.now().isoformat()
            })
        else:
            logger.warning(f"No WebSocket manager, cannot emit event: {event}")
