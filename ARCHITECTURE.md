# BBK Gym Hardware Bridge - System Architecture

## 🎯 Core Purpose
Electron desktop application that bridges local ZKTeco fingerprint devices with cloud-based gym management system, supporting multi-screen displays and real-time hardware events.

---

## 📐 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         BBK HARDWARE BRIDGE                              │
│                       (Electron Desktop App)                             │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌──────────────┐          ┌──────────────┐          ┌──────────────┐
│   SCREEN 1   │          │   SCREEN 2   │          │  PYTHON      │
│   Employee   │          │   Member     │          │  BRIDGE      │
│   Window     │          │   Kiosk      │          │  SERVICE     │
└──────────────┘          └──────────────┘          └──────────────┘
        │                           │                           │
        │                           │                           │
        │                           │                           ▼
        │                           │                  ┌─────────────────┐
        │                           │                  │   ZKTeco SDK    │
        │                           │                  │   (pyzk lib)    │
        │                           │                  └─────────────────┘
        │                           │                           │
        │                           │                           ▼
        │                           │                  ┌─────────────────┐
        │                           │                  │  Fingerprint    │
        │                           │                  │  Device (TCP)   │
        │                           │                  │  192.168.1.201  │
        │                           │                  └─────────────────┘
        │                           │
        │                           │                  ┌─────────────────┐
        │                           │                  │   Door Lock     │
        │                           │                  │   (Serial)      │
        │                           │                  │   COM7 @ 9600   │
        │                           │                  └─────────────────┘
        │                           │
        └───────────────────────────┴───────────────────────────┐
                                    │                           │
                                    ▼                           │
                          ┌──────────────────┐                  │
                          │  WebSocket HUB   │◄─────────────────┘
                          │  (Main Process)  │
                          └──────────────────┘
                                    │
                                    ▼
                          ┌──────────────────┐
                          │  Cloud Dashboard │
                          │  bbkdashboard    │
                          │  .vercel.app     │
                          └──────────────────┘
```

---

## 🏗️ Component Breakdown

### 1. **Electron Main Process**
- **Role**: Orchestrator, Window Manager, IPC Hub
- **Responsibilities**:
  - Create and manage multiple BrowserWindows
  - Start/stop Python bridge service
  - Route messages between screens, Python, and cloud
  - Handle app lifecycle (auto-start, tray, updates)

### 2. **Employee Screen (Screen 1)**
- **URL**: `https://bbkdashboard.vercel.app/`
- **Purpose**: Staff admin interface
- **Features**:
  - Full dashboard access
  - Trigger actions (Add Member, Enroll Fingerprint)
  - View real-time attendance
  - Control door lock manually

### 3. **Member Kiosk Screen (Screen 2)**
- **URL**: `https://bbkdashboard.vercel.app/member-screen`
- **Purpose**: Public display for members
- **Modes**:
  - **Idle**: Promotional media (images/videos)
  - **Active**: Member info on finger scan
  - **Registration**: Self-registration form

### 4. **Python Bridge Service**
- **Tech**: FastAPI + WebSocket + pyzk + pyserial
- **Port**: `8000` (configurable)
- **Endpoints**:
  - `GET /health` - Health check
  - `POST /fingerprint/connect` - Connect to device
  - `POST /fingerprint/enroll` - Start enrollment
  - `POST /doorlock/open` - Open door
  - `WS /ws/events` - Real-time events stream

### 5. **Cloud Dashboard Integration**
- **Communication**: WebSocket bidirectional
- **Events TO Cloud**:
  - Finger scanned (user_id, timestamp)
  - Enrollment complete
  - Device status changes
- **Commands FROM Cloud**:
  - Show registration modal
  - Sync user to device
  - Update promotional media

---

## 🔄 Data Flow Examples

### A. **Fingerprint Scan Flow**
```
1. Member places finger on ZKTeco device
   ↓
2. pyzk lib detects scan → user_id: 1234
   ↓
3. Python service emits via WebSocket:
   {
     "event": "finger_scanned",
     "user_id": 1234,
     "timestamp": "2026-01-10T10:30:00Z"
   }
   ↓
4. Electron Main Process receives event
   ↓
5. Electron queries local DB or cloud API:
   GET /api/members/1234 → { name, expiry, photo }
   ↓
6. Broadcast to ALL windows via IPC:
   - Employee Screen: Toast notification
   - Member Screen: Show user popup (5 seconds)
   - Cloud Dashboard: Update attendance table
   ↓
7. Check expiry:
   - If valid → Open door (ser.write('o'))
   - If expired → Show warning, deny entry
   ↓
8. Log attendance to cloud:
   POST /api/attendance { user_id, timestamp }
```

### B. **Member Registration Flow**
```
1. Staff clicks "Add Member" on Employee Screen
   ↓
2. Dashboard sends WebSocket message:
   {
     "command": "show_registration",
     "data": { mode: "kiosk" }
   }
   ↓
3. Electron Main Process receives
   ↓
4. Send IPC to Member Screen (Screen 2):
   window.webContents.send('show-modal', 'registration')
   ↓
5. Member Screen switches to registration form
   ↓
6. User fills form → submits
   ↓
7. POST to cloud API: /api/members (create member)
   ↓
8. Cloud returns member_id
   ↓
9. Electron triggers Python:
   POST /fingerprint/enroll { member_id, user_id }
   ↓
10. Python starts enrollment mode on device
    ↓
11. Device scans 3 finger samples
    ↓
12. Python saves template to device
    ↓
13. Emit success event → All screens notified
```

---

## 🗂️ Project Structure

```
bbk-desktop-app/
├── main.js                    # Electron main process
├── preload.js                 # Secure IPC bridge
├── package.json               # Node dependencies
├── config.json                # App configuration
│
├── windows/                   # Window management
│   ├── employee-screen.js     # Admin window logic
│   ├── member-screen.js       # Kiosk window logic
│   └── window-manager.js      # Multi-screen handler
│
├── services/                  # Business logic
│   ├── python-bridge.js       # Python service manager
│   ├── websocket-hub.js       # Central WS orchestrator
│   ├── cloud-api.js           # Dashboard API client
│   └── event-broadcaster.js   # Cross-window messaging
│
├── python-bridge/             # Python hardware service
│   ├── main.py                # FastAPI app
│   ├── fingerprint_service.py # ZKTeco integration (pyzk)
│   ├── doorlock_service.py    # Serial port (pyserial)
│   ├── websocket_manager.py   # Event emission
│   └── requirements.txt       # Python dependencies
│
├── renderer/                  # Preload scripts
│   ├── employee-preload.js
│   └── member-preload.js
│
├── assets/                    # Static resources
│   ├── icons/
│   └── sounds/
│
└── docs/                      # Documentation
    ├── ARCHITECTURE.md        # This file
    ├── API_REFERENCE.md       # All endpoints
    ├── DEPLOYMENT.md          # Installation guide
    └── TROUBLESHOOTING.md     # Common issues
```

---

## 🔐 Security Model

### 1. **Hardware Access Isolation**
- ❌ NO direct hardware access from browser
- ✅ Python bridge is the ONLY hardware interface
- ✅ Electron acts as authenticated proxy

### 2. **IPC Security**
```javascript
// Preload script exposes ONLY safe APIs
contextBridge.exposeInMainWorld('hardware', {
  enrollFingerprint: (memberId) => ipcRenderer.invoke('enroll', memberId),
  openDoor: () => ipcRenderer.invoke('door-open')
  // ❌ NO direct serial/USB access
});
```

### 3. **WebSocket Authentication**
```python
# Python bridge validates tokens
@app.websocket("/ws/events")
async def events(websocket: WebSocket, token: str):
    if not verify_token(token):
        await websocket.close(code=1008)
```

### 4. **Config File Protection**
```json
{
  "python_bridge_token": "auto-generated-uuid",
  "cloud_api_key": "env-variable-only"
}
```

---

## 🌐 Communication Protocols

### A. **Electron ↔ Python Bridge**
- **Method**: WebSocket (bidirectional)
- **URL**: `ws://localhost:8000/ws/electron`
- **Format**: JSON messages

**Example - Electron to Python:**
```json
{
  "type": "command",
  "action": "enroll_fingerprint",
  "payload": {
    "user_id": 1234,
    "member_id": "MEM-2026-001"
  },
  "request_id": "uuid-123"
}
```

**Example - Python to Electron:**
```json
{
  "type": "event",
  "name": "finger_scanned",
  "data": {
    "user_id": 1234,
    "punch_time": "2026-01-10T10:30:00Z",
    "punch_type": 1
  },
  "timestamp": 1736508600000
}
```

### B. **Electron ↔ Cloud Dashboard**
- **Method**: WebSocket + REST API
- **WebSocket URL**: `wss://bbkdashboard.vercel.app/api/hardware/ws`
- **REST Base**: `https://bbkdashboard.vercel.app/api`

**Events TO Cloud:**
```json
{
  "event": "attendance_marked",
  "member_id": 123,
  "timestamp": "2026-01-10T10:30:00Z",
  "status": "valid"
}
```

**Commands FROM Cloud:**
```json
{
  "command": "sync_member",
  "data": {
    "member_id": 123,
    "finger_id": 1234,
    "template": "base64_encoded_template"
  }
}
```

### C. **Electron ↔ BrowserWindows**
- **Method**: IPC (Inter-Process Communication)
- **Direction**: Bidirectional

**Main → Renderer:**
```javascript
// In main.js
memberWindow.webContents.send('show-member-info', {
  name: 'John Doe',
  expiry: '2026-06-30',
  photo: 'https://cdn.example.com/photo.jpg'
});
```

**Renderer → Main:**
```javascript
// In renderer (via preload)
window.hardware.enrollFingerprint(memberId);

// Main process handles
ipcMain.handle('enroll', async (event, memberId) => {
  const result = await pythonBridge.enroll(memberId);
  return result;
});
```

---

## 🔄 State Management

### 1. **Connection States**
```javascript
const ConnectionState = {
  DISCONNECTED: 'disconnected',
  CONNECTING: 'connecting',
  CONNECTED: 'connected',
  ERROR: 'error'
};

// Track states
const states = {
  pythonBridge: ConnectionState.DISCONNECTED,
  fingerprintDevice: ConnectionState.DISCONNECTED,
  doorLock: ConnectionState.DISCONNECTED,
  cloudDashboard: ConnectionState.DISCONNECTED
};
```

### 2. **Auto-Reconnect Logic**
```javascript
class PythonBridge {
  async connect() {
    try {
      this.ws = new WebSocket('ws://localhost:8000/ws/electron');
      this.ws.on('close', () => this.reconnect());
    } catch (err) {
      setTimeout(() => this.reconnect(), 5000);
    }
  }
  
  reconnect() {
    if (this.reconnectAttempts < 10) {
      this.reconnectAttempts++;
      setTimeout(() => this.connect(), 2000 * this.reconnectAttempts);
    }
  }
}
```

### 3. **Offline Queue**
```javascript
class EventQueue {
  constructor() {
    this.queue = [];
  }
  
  add(event) {
    this.queue.push({...event, queued_at: Date.now()});
    this.persist(); // Save to local DB
  }
  
  async flush() {
    while (this.queue.length > 0 && this.isOnline()) {
      const event = this.queue.shift();
      await this.sendToCloud(event);
    }
  }
}
```

---

## 📊 Configuration Schema

**config.json:**
```json
{
  "version": "1.0.0",
  "app_name": "BBK Hardware Bridge",
  
  "screens": {
    "employee": {
      "url": "https://bbkdashboard.vercel.app/",
      "display_index": 0,
      "dev_tools": false
    },
    "member": {
      "url": "https://bbkdashboard.vercel.app/member-screen",
      "display_index": 1,
      "fullscreen": true,
      "kiosk_mode": true
    }
  },
  
  "hardware": {
    "fingerprint": {
      "ip": "192.168.1.201",
      "port": 4370,
      "timeout": 5,
      "auto_reconnect": true
    },
    "doorlock": {
      "port": "COM7",
      "baudrate": 9600,
      "open_duration": 5000
    }
  },
  
  "python_bridge": {
    "enabled": true,
    "port": 8000,
    "auto_start": true,
    "executable": "./python-bridge/dist/bridge-service.exe"
  },
  
  "cloud": {
    "base_url": "https://bbkdashboard.vercel.app",
    "ws_url": "wss://bbkdashboard.vercel.app/api/hardware/ws",
    "api_key_env": "BBK_API_KEY",
    "timeout": 10000
  },
  
  "ui": {
    "popup_duration": 5000,
    "sound_enabled": true,
    "notification_enabled": true
  },
  
  "logging": {
    "level": "info",
    "file": "./logs/app.log",
    "max_size": "10MB"
  }
}
```

---

## 🚀 Startup Sequence

```
1. Electron App Launch
   ├─ Load config.json
   ├─ Initialize logging
   ├─ Check Python installation
   └─ Create tray icon

2. Start Python Bridge
   ├─ Spawn child process: python-bridge-service.exe
   ├─ Wait for health check: GET http://localhost:8000/health
   └─ Establish WebSocket: ws://localhost:8000/ws/electron

3. Connect to Hardware
   ├─ Python connects to ZKTeco (IP: 192.168.1.201:4370)
   ├─ Python opens serial port (COM7 @ 9600)
   └─ Emit status events → Electron

4. Create Windows
   ├─ Detect displays (primary + external)
   ├─ Create Employee Window (Display 0)
   ├─ Create Member Window (Display 1, fullscreen)
   └─ Load URLs from config

5. Connect to Cloud
   ├─ Establish WebSocket: wss://bbkdashboard.vercel.app/api/hardware/ws
   ├─ Authenticate with API key
   └─ Sync initial state

6. Start Event Loop
   ├─ Listen to Python events
   ├─ Listen to Cloud commands
   ├─ Broadcast to all windows
   └─ Handle IPC messages

7. Ready State
   └─ Show "Connected" indicator on all screens
```

---

## 🛠️ Technology Stack

### **Electron Layer**
- `electron`: ^33.2.1
- `electron-store`: ^8.2.0 (persistent config)
- `winston`: ^3.11.0 (logging)
- `ws`: ^8.16.0 (WebSocket client)

### **Python Layer**
- `fastapi`: ^0.109.0
- `uvicorn`: ^0.27.0
- `pyzk`: ^0.9 (ZKTeco SDK)
- `pyserial`: ^3.5 (Serial communication)
- `websockets`: ^12.0

### **Build Tools**
- `electron-builder`: ^25.1.8 (package Electron)
- `PyInstaller`: ^6.3.0 (package Python)

---

## 📦 Packaging Strategy

### **Step 1: Build Python Service**
```bash
cd python-bridge
pyinstaller --onefile --name bridge-service main.py
# Output: dist/bridge-service.exe
```

### **Step 2: Build Electron App**
```bash
npm run build
# Output: dist/BBK Hardware Bridge Setup.exe
```

### **Step 3: Bundle Together**
```
BBK-Hardware-Bridge/
├── BBK Hardware Bridge.exe     # Electron executable
├── resources/
│   └── python-bridge/
│       └── bridge-service.exe  # Bundled Python service
├── config.json                 # User-editable config
└── README.txt                  # Installation guide
```

---

## 🔍 Debugging & Monitoring

### **Log Files**
- `logs/electron.log` - Electron main process
- `logs/python-bridge.log` - Python service
- `logs/fingerprint.log` - Device communication
- `logs/websocket.log` - Network events

### **DevTools**
```javascript
// Enable in config.json
"screens": {
  "employee": { "dev_tools": true }  // F12 opens DevTools
}
```

### **Health Dashboard**
```
http://localhost:8000/health
{
  "status": "healthy",
  "fingerprint": {
    "connected": true,
    "users": 150,
    "last_scan": "2026-01-10T10:30:00Z"
  },
  "doorlock": {
    "connected": true,
    "port": "COM7"
  }
}
```

---

## ✅ Design Validation Checklist

- [x] Multi-screen support (Employee + Member)
- [x] ZKTeco integration via Python (pyzk)
- [x] Door lock control via serial (pyserial)
- [x] Real-time finger scan events
- [x] Bidirectional cloud communication
- [x] Offline-safe with event queue
- [x] Secure IPC (no direct hardware from browser)
- [x] Auto-reconnect on failures
- [x] Configurable via JSON
- [x] Packageable as single installer

---

## 🎯 Next Steps

1. ✅ Architecture documented
2. ⏳ Implement Python bridge service
3. ⏳ Create Electron multi-window system
4. ⏳ Build WebSocket hub
5. ⏳ Integrate fingerprint events
6. ⏳ Add door lock control
7. ⏳ Test multi-screen scenarios
8. ⏳ Package for deployment
