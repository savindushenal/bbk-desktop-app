# BBK HARDWARE BRIDGE - DELIVERY PACKAGE
# ========================================

## 📦 What You're Getting

This is a complete, production-ready hardware bridge system that connects:
- ZKTeco fingerprint devices
- Serial door locks
- Cloud-based gym management dashboard

## 🎯 One-Click Deployment

### For End Users (Simplest):

1. **Install Prerequisites** (one-time):
   - Install Node.js 18+ from https://nodejs.org/
   - Install Python 3.9-3.11 from https://python.org/

2. **Run the Application**:
   - Double-click `start.bat`
   - That's it! Everything else is automatic.

### What Happens Automatically:
✅ Checks system requirements
✅ Installs all dependencies
✅ Starts Python hardware bridge
✅ Launches Electron multi-screen app
✅ Connects to hardware (if available)
✅ Cleanup when you close

## 📁 Package Contents

```
bbk-desktop-app/
├── start.bat                    ⭐ ONE-CLICK LAUNCHER (Start here!)
├── START_HERE.txt               📖 Quick start guide
├── system-check.bat             🔍 Verify system is ready
│
├── start.ps1                    🔷 PowerShell launcher (alternative)
├── create-desktop-shortcut.ps1  🖥️ Create desktop icon
├── package-release.bat          📦 Create portable package
│
├── config.json                  ⚙️ Hardware configuration
├── package.json                 📄 Node.js dependencies
│
├── main-hardware-bridge.js      🔧 Electron main process
├── renderer/                    🖼️ Preload scripts for IPC
│   ├── employee-preload.js
│   └── member-preload.js
│
├── python-bridge/               🐍 Python hardware service
│   ├── main.py                  FastAPI application
│   ├── fingerprint_service.py   ZKTeco integration
│   ├── doorlock_service.py      Serial communication
│   ├── websocket_manager.py     Event broadcasting
│   └── requirements.txt         Python dependencies
│
├── logs/                        📝 Application logs
├── resources/                   🎨 Icons and assets
│
└── docs/                        📚 Documentation
    ├── ARCHITECTURE.md          System design
    ├── QUICK_START.md           5-minute setup
    ├── DEPLOYMENT.md            Production guide
    └── README.md                Overview
```

## 🚀 Deployment Options

### Option 1: Direct Run (Recommended)
```
1. Copy entire bbk-desktop-app folder to target PC
2. Install Node.js and Python
3. Double-click start.bat
```

### Option 2: Create Portable Package
```
1. Run package-release.bat
2. Share release/bbk-hardware-bridge.zip
3. Extract on target PC
4. Double-click start.bat
```

### Option 3: Install as Windows Service (Advanced)
See DEPLOYMENT.md for auto-start configuration

## ⚙️ Configuration

Before first run, edit `config.json`:

```json
{
  "hardware": {
    "fingerprint": {
      "ip": "192.168.1.201",  // ← Change to your ZKTeco IP
      "port": 4370
    },
    "doorlock": {
      "port": "COM7",          // ← Change to your COM port
      "baudrate": 9600
    }
  }
}
```

To find COM port:
1. Open Device Manager (Win + X → Device Manager)
2. Expand "Ports (COM & LPT)"
3. Note the COM number for your Arduino/relay device

## 🧪 Testing

### 1. System Check
```
Double-click: system-check.bat
```
Verifies all prerequisites are met

### 2. Test Without Hardware
The app works perfectly without hardware connected.
You can develop/test the UI and cloud integration.

### 3. Test with Hardware
1. Connect ZKTeco device to network
2. Connect door lock to USB/serial port
3. Update config.json with correct IP and COM port
4. Run start.bat
5. Check logs/ folder for connection status

## 📊 Monitoring

### Health Check
Open browser: http://localhost:8000/health

Shows:
- Python bridge status
- Fingerprint device connection
- Door lock connection
- Service versions

### View Logs
- `logs/electron.log` - Electron application logs
- `python-bridge/logs/python-bridge.log` - Python service logs

### Real-time Logs
```powershell
# Electron logs
Get-Content logs\electron.log -Tail 50 -Wait

# Python logs  
Get-Content python-bridge\logs\python-bridge.log -Tail 50 -Wait
```

## 🎨 Customization

### Add Desktop Icon
1. Create/download a .ico file for BBK Gym
2. Place as `resources/icon.ico`
3. Run `create-desktop-shortcut.ps1`
4. Double-click desktop shortcut to launch

### Change URLs
Edit `config.json`:
```json
{
  "screens": {
    "employee": {
      "url": "https://your-dashboard.com"
    },
    "member": {
      "url": "https://your-dashboard.com/kiosk"
    }
  }
}
```

## 🐛 Troubleshooting

### "Python not found"
→ Install Python 3.9-3.11 and check "Add to PATH" during installation

### "Node not found"
→ Install Node.js 18+ and restart computer

### "Port 8000 already in use"
→ Another instance is running. Close it or restart computer.

### Hardware not connecting
→ Verify IP/COM port in config.json
→ Check firewall allows port 4370 (fingerprint)
→ Run system-check.bat to diagnose

### App won't start
→ Run system-check.bat first
→ Check logs/ folder for errors
→ Try manual start: `cd python-bridge && python main.py`

## 📞 Support

### Documentation
- Quick start: `QUICK_START.md`
- Architecture: `ARCHITECTURE.md`
- Deployment: `DEPLOYMENT.md`
- This file: `DELIVERY.md`

### Manual Operations
If start.bat doesn't work, you can run manually:

**Terminal 1 (Python Bridge):**
```powershell
cd python-bridge
pip install -r requirements.txt
python main.py
```

**Terminal 2 (Electron App):**
```powershell
npm install
npm start
```

## ✅ Pre-Deployment Checklist

Before deploying to production:

- [ ] Node.js 18+ installed on target PC
- [ ] Python 3.9-3.11 installed on target PC
- [ ] config.json updated with correct IP addresses
- [ ] config.json updated with correct COM port
- [ ] Firewall allows port 8000 (Python bridge)
- [ ] Firewall allows port 4370 (ZKTeco device)
- [ ] ZKTeco device is on network and pingable
- [ ] Door lock Arduino is connected to PC
- [ ] Tested with `system-check.bat`
- [ ] Tested one-click start with `start.bat`
- [ ] Multiple monitors connected (if using kiosk mode)

## 🎉 You're Ready!

The system is complete and production-ready. 

**To start using:**
1. Read `START_HERE.txt`
2. Run `system-check.bat` to verify
3. Double-click `start.bat` to launch
4. Enjoy your automated gym system!

---

**Made with ❤️ for BBK Boho Fitness**
**Version 1.0.0 - January 2026**
