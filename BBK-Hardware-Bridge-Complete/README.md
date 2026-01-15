# BBK Hardware Bridge - Complete Package

## 🎉 What's Included

This package contains the complete BBK Hardware Bridge system:

1. **BBK-Bridge.exe** - Standalone Python service (37.53 MB)
   - FastAPI web server on port 8000
   - Fingerprint device integration (ZKTeco)
   - Door lock control (Serial COM port)
   - Hardware optional mode (works without devices)

2. **Electron Desktop App** - Multi-window interface
   - Employee dashboard
   - Member kiosk screen
   - Real-time hardware events

3. **Configuration** - `config.json`
   - Hardware device settings
   - Screen configuration
   - Cloud integration

## 🚀 Quick Start

### Option 1: Complete System (Recommended)
```bash
1. Double-click: START-ALL.bat
2. Wait for both Python bridge and Electron app to start
3. Done!
```

### Option 2: Python Bridge Only
```bash
1. Double-click: BBK-Bridge.exe
2. Access API at: http://localhost:8000
3. View docs at: http://localhost:8000/docs
```

### Option 3: Manual Start
```bash
1. Start Python bridge: BBK-Bridge.exe
2. Install dependencies: npm install
3. Start Electron: npx electron main-hardware-bridge.js
```

## ⚙️ Requirements

- **Windows 10/11** (64-bit)
- **Node.js 18+** (for Electron app only)
- **Hardware (Optional)**:
  - ZKTeco fingerprint device (network)
  - Door lock controller (Serial/USB)

## 📝 Configuration

Edit `config.json` to customize:

```json
{
  "hardware": {
    "fingerprint": {
      "ip": "192.168.2.201",
      "port": 4370
    },
    "doorlock": {
      "port": "COM7",
      "baudrate": 9600
    }
  }
}
```

## 🔧 API Endpoints

- `GET /health` - System health check
- `POST /fingerprint/verify` - Verify fingerprint
- `POST /door/unlock` - Unlock door
- `GET /docs` - Interactive API documentation

## 📦 Deployment

For end users without Node.js:
1. Share only `BBK-Bridge.exe` + `config.json`
2. Users run BBK-Bridge.exe
3. Access web interface at http://localhost:8000

For full system deployment:
1. ZIP this entire folder
2. Users extract and run START-ALL.bat
3. First run will install Node dependencies automatically

## 🛠️ Troubleshooting

**Python bridge won't start:**
- Check if port 8000 is already in use
- View logs in: logs/python-bridge.log

**Hardware not detected:**
- System works in hardware-optional mode
- Check device IP/COM port in config.json
- Verify device connections

**Electron app won't start:**
- Ensure Node.js is installed
- Run: npm install
- Check for errors in terminal

## 📞 Support

- GitHub: https://github.com/savindushenal/bbk-desktop-app
- Documentation: See README files in project

## 📄 License

Copyright © 2026 BBK Boho Fitness
