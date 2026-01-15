╔═══════════════════════════════════════════════════════════════╗
║       BBK DESKTOP APP - HARDWARE BRIDGE EDITION              ║
║                     Version 1.0.0                             ║
╚═══════════════════════════════════════════════════════════════╝

⚠️  IMPORTANT: NODE.JS REQUIRED  ⚠️
════════════════════════════════════════════════════════════════
Before running START.bat, you MUST have Node.js installed!

Download Node.js: https://nodejs.org/
➤ Choose "LTS" version (recommended)
➤ Run the installer
➤ Restart your computer after installation

════════════════════════════════════════════════════════════════

📋 QUICK START GUIDE
════════════════════════════════════════════════════════════════

STEP 1: Install Node.js (if not already installed)
   ✓ Go to https://nodejs.org/
   ✓ Download LTS version (e.g., v20.x.x)
   ✓ Run installer with default settings
   ✓ Restart computer

STEP 2: Extract Package
   ✓ Unzip to ANY location (works from any drive/folder)
   ✓ Examples: C:\BBK-App\, D:\Apps\BBK\, E:\Desktop\BBK\
   ✓ No installation needed - just extract and run

STEP 3: Configure Hardware
   ✓ Open config.json in Notepad
   ✓ Edit these settings:
     • hardware.fingerprint.ip → Your fingerprint device IP
     • hardware.doorlock.port → Your door lock COM port

STEP 4: Launch Application
   ✓ Double-click START.bat
   ✓ First run: Dependencies install automatically (1-2 minutes)
   ✓ Subsequent runs: App starts immediately

════════════════════════════════════════════════════════════════

🔧 CONFIGURATION
════════════════════════════════════════════════════════════════

Edit config.json:

FINGERPRINT DEVICE (ZKTeco):
{
  "hardware": {
    "fingerprint": {
      "ip": "192.168.1.201"  ← Change this to your device IP
    }
  }
}

How to find IP:
- Check device LCD screen
- Use ZKAccess SearchDevice tool
- Check your router's DHCP leases

DOOR LOCK (Serial):
{
  "hardware": {
    "doorlock": {
      "port": "COM7"  ← Change this to your COM port
    }
  }
}

How to find COM port:
- Open Device Manager (Win+X → Device Manager)
- Expand "Ports (COM & LPT)"
- Look for "USB Serial Port (COMx)"
- Note the number (e.g., COM3, COM7)

════════════════════════════════════════════════════════════════

🛠️  TROUBLESHOOTING
════════════════════════════════════════════════════════════════

❌ "Node.js is NOT installed"
   ➤ Install Node.js from https://nodejs.org/
   ➤ Restart computer after installation
   ➤ Run START.bat again

❌ "Failed to install dependencies"
   ➤ Check internet connection
   ➤ Run as Administrator
   ➤ Delete node_modules folder and try again

❌ Python Bridge not starting
   ➤ Check if port 8000 is already in use:
     Open Command Prompt and run: netstat -ano | findstr :8000
   ➤ Check logs\bridge.log for errors

❌ Fingerprint device not working
   ➤ Ping the device: ping 192.168.1.201
   ➤ Verify IP in config.json matches device IP
   ➤ Check network cable connection

❌ Door lock not working
   ➤ Verify COM port in Device Manager
   ➤ Check USB cable connection
   ➤ Try different USB port

❌ App won't open
   ➤ Run START.bat as Administrator
   ➤ Check logs\ folder for errors
   ➤ Make sure no firewall is blocking

════════════════════════════════════════════════════════════════

💻 SYSTEM REQUIREMENTS
════════════════════════════════════════════════════════════════

MINIMUM:
├─ Windows 10 (64-bit)
├─ Node.js 16+ ⚠️ REQUIRED
├─ 4 GB RAM
├─ 500 MB disk space
├─ Internet connection
└─ Dual monitors (recommended)

HARDWARE:
├─ Fingerprint: ZKTeco device (Ethernet)
└─ Door Lock: Serial controller (USB)

════════════════════════════════════════════════════════════════

🌐 CLOUD INTEGRATION
════════════════════════════════════════════════════════════════

The app connects to:
- Dashboard: https://bbkdashboard.vercel.app
- Employee: https://bbkdashboard.vercel.app/dashboard
- Member Screen: https://bbkdashboard.vercel.app/member-screen
- Local Bridge API: http://localhost:8000

════════════════════════════════════════════════════════════════

📁 PACKAGE CONTENTS
════════════════════════════════════════════════════════════════

BBK-Desktop-App-Release/
├─ START.bat                    ← Double-click to launch
├─ config.json                  ← Hardware settings
├─ README.txt                   ← This file
├─ main-hardware-bridge.js      ← Electron main process
├─ preload.js                   ← IPC bridge
├─ package.json                 ← Dependencies list
├─ python-bridge/
│  └─ BBK-Bridge.exe           ← Hardware service
├─ renderer/                    ← UI scripts
├─ resources/                   ← Icons and assets
├─ logs/                        ← Error logs (created on first run)
└─ node_modules/                ← Runtime dependencies (60 files)

════════════════════════════════════════════════════════════════

✅ FIRST RUN CHECKLIST
════════════════════════════════════════════════════════════════

Before running START.bat:
  [ ] Node.js installed (check: open CMD, type "node -v")
  [ ] Package extracted to C:\BBK-Desktop-App\
  [ ] config.json edited with correct IPs and ports
  [ ] Fingerprint device connected and pingable
  [ ] Door lock connected (visible in Device Manager)
  [ ] Internet connection active
  [ ] Dual monitors connected (or single monitor configured)

═══════════════════════════════════════════════════════════════════

        BBK Desktop App v1.0.0 - All Rights Reserved
                © 2026 BBK Boho Fitness

═══════════════════════════════════════════════════════════════════

