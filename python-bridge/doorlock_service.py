"""
Door Lock Service - Serial Communication
Controls door lock via serial port (Arduino/relay)
"""

import serial
import time
import logging
import asyncio
from typing import Optional

logger = logging.getLogger(__name__)


class DoorLockService:
    def __init__(self, port: str = "COM7", baudrate: int = 9600, timeout: float = 1.0):
        """
        Initialize door lock service
        
        Args:
            port: Serial port (COM7 on Windows, /dev/ttyUSB0 on Linux)
            baudrate: Baud rate (default 9600)
            timeout: Serial timeout in seconds
        """
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.ser: Optional[serial.Serial] = None
        self.is_door_open = False
        
        logger.info(f"Door lock service initialized for port {port}")
    
    def connect(self):
        """Connect to serial port"""
        try:
            if self.ser and self.ser.is_open:
                logger.warning("Serial port already open")
                return True
            
            logger.info(f"Opening serial port {self.port} at {self.baudrate} baud...")
            self.ser = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                timeout=self.timeout,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE
            )
            
            # Give device time to initialize
            time.sleep(2)
            
            logger.info(f"Serial port {self.port} opened successfully")
            return True
            
        except serial.SerialException as e:
            logger.warning(f"Door lock not available on {self.port}: {e}")
            return False
        except Exception as e:
            logger.warning(f"Could not connect to door lock: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from serial port"""
        try:
            if self.ser and self.ser.is_open:
                self.ser.close()
                logger.info(f"Serial port {self.port} closed")
            self.ser = None
        except Exception as e:
            logger.error(f"Error closing serial port: {e}")
    
    def is_connected(self) -> bool:
        """Check if serial port is connected"""
        return self.ser is not None and self.ser.is_open
    
    def open_door(self, duration: int = 5):
        """
        Open door lock for specified duration
        
        Args:
            duration: How long to keep door open (seconds)
        
        Returns:
            Dict with operation result
        """
        if not self.is_connected():
            raise Exception("Serial port not connected")
        
        try:
            logger.info(f"Opening door for {duration} seconds...")
            
            # Send 'o' command to open door
            self.ser.write(b'o')
            self.ser.flush()
            self.is_door_open = True
            
            # Schedule automatic close after duration
            asyncio.create_task(self._auto_close(duration))
            
            return {
                "success": True,
                "message": f"Door opened for {duration} seconds"
            }
            
        except serial.SerialException as e:
            logger.error(f"Serial error while opening door: {e}")
            raise Exception(f"Failed to open door: {e}")
        except Exception as e:
            logger.error(f"Error opening door: {e}")
            raise
    
    async def _auto_close(self, duration: int):
        """Auto-close door after specified duration"""
        await asyncio.sleep(duration)
        if self.is_door_open:
            self.close_door()
    
    def close_door(self):
        """Close door lock immediately"""
        if not self.is_connected():
            raise Exception("Serial port not connected")
        
        try:
            logger.info("Closing door...")
            
            # Send 'c' command to close door
            self.ser.write(b'c')
            self.ser.flush()
            self.is_door_open = False
            
            return {
                "success": True,
                "message": "Door closed"
            }
            
        except serial.SerialException as e:
            logger.error(f"Serial error while closing door: {e}")
            raise Exception(f"Failed to close door: {e}")
        except Exception as e:
            logger.error(f"Error closing door: {e}")
            raise
    
    def get_status(self) -> dict:
        """Get door lock status"""
        return {
            "connected": self.is_connected(),
            "port": self.port,
            "baudrate": self.baudrate,
            "is_open": self.is_door_open
        }
