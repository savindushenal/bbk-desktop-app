# BBK Gym Hardware Bridge

> Desktop application that bridges ZKTeco fingerprint devices and door locks with cloud-based gym management system

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Electron](https://img.shields.io/badge/Electron-33.2.1-blue)](https://www.electronjs.org/)
[![Python](https://img.shields.io/badge/Python-3.9--3.11-green)](https://www.python.org/)

## 🎯 Overview

BBK Hardware Bridge is an Electron-based desktop application designed to connect local gym hardware devices (fingerprint scanners, door locks) with a cloud-based dashboard. It provides:

- **Multi-Screen Support**: Employee dashboard + Member kiosk display
- **Real-Time Hardware Events**: Fingerprint scans, door access, attendance tracking
- **ZKTeco Integration**: Full support for ZKTeco fingerprint devices via Python (pyzk)
- **Door Lock Control**: Serial communication for Arduino/relay-based door systems
- **Offline Resilience**: Event queuing when cloud is unreachable
- **Secure Architecture**: Hardware access isolated from browser, IPC-only communication

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│      Electron Desktop App                   │
│  ┌──────────────┐    ┌──────────────┐      │
│  │  Employee    │    │   Member     │      │
│  │  Screen      │    │   Kiosk      │      │
│  └──────────────┘    └──────────────┘      │
│          │                    │             │
│          └────────┬───────────┘             │
│                   │                         │
│          ┌────────▼────────┐                │
│          │  WebSocket Hub  │                │
│          └────────┬────────┘                │
└───────────────────┼─────────────────────────┘
                    │
          ┌─────────▼─────────┐
          │  Python Bridge    │
          │  (FastAPI + WS)   │
          └─────────┬─────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────▼────────┐      ┌──────▼──────┐
│   ZKTeco       │      │  Door Lock  │
│   Fingerprint  │      │  (Serial)   │
│   Device       │      │  COM7       │
└────────────────┘      └─────────────┘
```

## ✨ Features

### 🖥️ Multi-Screen System
- **Employee Screen**: Loads cloud dashboard for staff
- **Member Screen**: Fullscreen kiosk for member check-ins
- Automatic display detection and assignment
- Configurable screen URLs and modes

### 🔐 Biometric Integration
- ZKTeco device support via Python (pyzk library)
- Real-time finger scan detection
- User enrollment (3-scan template capture)
- Attendance tracking with punch types
- Auto-reconnect on device disconnect

### 🚪 Door Access Control
- Serial communication (Arduino/relay control)
- Configurable open duration (default 5 seconds)
- Manual open/close commands
- Integration with member verification

### 🌐 Cloud Integration
- WebSocket connection to cloud dashboard
- Real-time event broadcasting
- Command reception from web app
- Offline event queuing

### 🛡️ Security
- No direct hardware access from browser
- Secure IPC via contextBridge
- Python bridge as isolated service
- Token-based WebSocket authentication

## 📦 Installation

### Prerequisites
- **Windows 10/11** (64-bit)
- **Node.js** 18+ ([Download](https://nodejs.org/))
- **Python** 3.9-3.11 ([Download](https://www.python.org/))
- ZKTeco fingerprint device (network-connected)
- Door lock with serial interface (optional)

### One-Click Install & Run

**Just double-click:** `start.bat`

That's it! The script will:
1. ✅ Check if Node.js and Python are installed
2. ✅ Install all dependencies automatically
3. ✅ Start Python hardware bridge
4. ✅ Launch Electron application
5. ✅ Auto-cleanup when closed

**First time?** See `START_HERE.txt` for complete instructions.

### Manual Install (Advanced)
```powershell
# Install Node.js dependencies
npm install

# Install Python dependencies
cd python-bridge
pip install -r requirements.txt
cd ..

# Configure hardware
# Edit config.json with your device IP and COM port

# Run application
start.bat  # One-click launcher
# OR manually:
# Terminal 1: cd python-bridge && python main.py
# Terminal 2: npm start
```

📖 **See [QUICK_START.md](QUICK_START.md) for detailed setup guide**

## ⚙️ Configuration

Edit `config.json`:

```json
{
  "hardware": {
    "fingerprint": {
      "ip": "192.168.1.201",     // Your ZKTeco device IP
      "port": 4370
    },
    "doorlock": {
      "port": "COM7",             // Your serial port
      "baudrate": 9600
    }
  },
  "screens": {
    "employee": {
      "url": "https://bbkdashboard.vercel.app/",
      "display_index": 0
    },
    "member": {
      "url": "https://bbkdashboard.vercel.app/member-screen",
      "display_index": 1,
      "fullscreen": true
    }
  }
}
```

## 🚀 Usage

### One-Click Start
```
Double-click: start.bat
```
Everything starts automatically!

### Alternative Launchers
- **Windows**: `start.bat` (recommended)
- **PowerShell**: Right-click `start.ps1` → "Run with PowerShell"
- **Desktop Shortcut**: Run `create-desktop-shortcut.ps1` once

### Running in Development
```powershell
npm run start:hardware
```

### Building for Production

**Create Standalone EXE (No Installation Required):**
```powershell
# Quick portable EXE (1 minute)
BUILD-NOW.bat

# Output: exe-output/
# - BBK-Bridge.exe (30 MB)
# - START.bat (one-click launcher)
# - Works on any Windows PC!
# - No Node.js or Python needed!
```

**Create Full Installer + Portable Package:**
```powershell
# Build complete package with Electron UI (10 minutes)
build-exe.bat

# Output: build-exe/
# - BBK Hardware Bridge Setup.exe (Installer)
# - BBK-Hardware-Bridge-Portable.zip
# - Multi-screen support included
```

📖 **See [EXE_BUILD_GUIDE.md](EXE_BUILD_GUIDE.md) for complete build instructions**

**Create Portable Package:**
```powershell
# Run the packager
package-release.bat

# Output: release/bbk-hardware-bridge/
# - All application files
# - Dependencies pre-installed
# - Ready to copy to any Windows PC
# - Just needs Node.js and Python installed
```

**Build Standalone Executable:**
```powershell
# Build Python service
npm run build-python

# Build Electron app
npm run build

# Output: dist/BBK Hardware Bridge-win32-x64/
```

### API Examples

**Enroll Fingerprint:**
```javascript
// In Employee Dashboard DevTools
window.hardware.enrollFingerprint(123, 1)
  .then(result => console.log('Enrolled:', result));
```

**Listen for Scans:**
```javascript
window.hardware.on('finger-scanned', (data) => {
  console.log('Member ID:', data.user_id);
  console.log('Time:', data.timestamp);
});
```

**Control Door:**
```javascript
// Open for 5 seconds
window.hardware.openDoor(5);

// Close immediately
window.hardware.closeDoor();
```

## 📡 WebSocket Events

### Events FROM Python Bridge:
- `finger_scanned`: Member placed finger on device
- `enrollment_started`: Enrollment process initiated
- `enrollment_complete`: Fingerprint successfully enrolled
- `device_disconnected`: Hardware connection lost

### Commands TO Python Bridge:
- `enroll_fingerprint`: Start enrollment for user
- `get_users`: Retrieve all users from device
- `delete_user`: Remove user from device
- `reconnect_device`: Attempt device reconnection
- `open_door`: Trigger door unlock

## 🗂️ Project Structure

```
bbk-desktop-app/
├── main-hardware-bridge.js    # Electron main process
├── config.json                 # Configuration file
├── package.json                # Node.js dependencies
│
├── renderer/                   # Preload scripts
│   ├── employee-preload.js     # Employee screen IPC
│   └── member-preload.js       # Member screen IPC
│
├── python-bridge/              # Python hardware service
│   ├── main.py                 # FastAPI application
│   ├── fingerprint_service.py  # ZKTeco integration
│   ├── doorlock_service.py     # Serial communication
│   ├── websocket_manager.py    # Event broadcasting
│   └── requirements.txt        # Python dependencies
│
├── docs/                       # Documentation
│   ├── ARCHITECTURE.md         # System architecture
│   ├── QUICK_START.md          # Getting started guide
│   └── DEPLOYMENT.md           # Production deployment
│
└── logs/                       # Application logs
    ├── electron.log            # Electron process logs
    └── python-bridge.log       # Python service logs
```

## 🎯 For Non-Technical Users

- **[EXE_BUILD_GUIDE.md](EXE_BUILD_GUIDE.md)**: Create standalone EXE packages
- **[ARCHITECTURE.md](ARCHITECTURE.md)**: Complete system design, data flow, and technical details
- **[QUICK_START.md](QUICK_START.md)**: 5-minute setup guide
- **[DEPLOYMENT.md](DEPLOYMENT.md)**: Production deployment, packaging, and troubleshooting
- **[DELIVERY.md](DELIVERY.md)**: Complete delivery package guide
   ```
   Double-click: BUILD-NOW.bat
   ```

2. **Share the folder:**
   ```
   ZIP the exe-output folder
   Send to users
   ```

3. **Users just:**
   ```
   Extract ZIP
   Double-click START.bat
   Done! 🎉
   ```

**No installation, no Node.js, no Python needed!**

---

## 📖 Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)**: Complete system design, data flow, and technical details
- **[QUICK_START.md](QUICK_START.md)**: 5-minute setup guide
- **[DEPLOYMENT.md](DEPLOYMENT.md)**: Production deployment, packaging, and troubleshooting

## 🧪 Testing

### Test Fingerprint Connection
```powershell
cd python-bridge
python -c "from zk import ZK; zk = ZK('192.168.1.201'); conn = zk.connect(); print('✅ Connected!'); conn.disconnect()"
```

### Test Door Lock
```powershell
python -c "import serial; ser = serial.Serial('COM7', 9600); ser.write(b'o'); ser.close(); print('✅ Door opened')"
```

### Test Python Bridge
```powershell
cd python-bridge
python main.py
# Open http://localhost:8000/health in browser
```

## 🐛 Troubleshooting

### Python Bridge Won't Start
- Check Python version: `python --version` (should be 3.9-3.11)
- Verify packages: `pip list | findstr "fastapi pyzk pyserial"`
- Check port 8000: `netstat -ano | findstr :8000`

### Fingerprint Device Not Found
- Ping device: `ping 192.168.1.201`
- Check firewall rules
- Verify device IP in admin panel

### Door Lock Not Working
- Check COM port in Device Manager
- Test serial manually: `python -c "import serial; print(serial.Serial('COM7'))"`
- Verify Arduino code/wiring

### Multi-Screen Issues
- Verify displays: Electron DevTools → `require('electron').screen.getAllDisplays()`
- Check `config.json` display_index values
- Restart app after connecting monitors

📖 **See [DEPLOYMENT.md](DEPLOYMENT.md) for comprehensive troubleshooting**

## 🔄 Updates

### Updating Configuration
Edit `config.json` and restart app

### Updating Code
```powershell
git pull
npm install
cd python-bridge && pip install -r requirements.txt
npm run start:hardware
```

## 🛠️ Development

### Enable DevTools
Edit `config.json`:
```json
{
  "screens": {
    "employee": {
      "dev_tools": true  // Enable F12 DevTools
    }
  }
}
```

### View Logs
```powershell
# Electron logs
Get-Content logs\electron.log -Tail 50 -Wait

# Python logs
Get-Content python-bridge\logs\python-bridge.log -Tail 50 -Wait
```

## Requirements

- Node.js 18+
- Python 3.9-3.11
- Windows 10/11 (64-bit)
- Internet connection (for cloud dashboard)

## Deployment

1. Build the app: `npm run build`
2. Distribute the .exe files from `dist/` folder
3. Users install and run

## Hardware Setup

Requires gym-bridge backend for hardware integration:
- Located in: `../gym-bridge-desktop`
- Auto-bundled in distributable
- Needs Python 3.12+ to run

See BUILD_GUIDE.md for complete instructions.

## License

MIT License - See LICENSE.txt
