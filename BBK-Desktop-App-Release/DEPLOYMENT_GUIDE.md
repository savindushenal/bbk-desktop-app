# BBK Desktop App - Deployment Guide

## 📦 Package Information

**File:** BBK-Desktop-App-v1.0.0.zip  
**Size:** 37.23 MB  
**Type:** Electron Desktop App + Python Hardware Bridge  
**Platform:** Windows 10/11  
**Date:** $(Get-Date -Format "yyyy-MM-dd")

---

## 🎯 What's Included

### Application Components
- ✅ **Electron Desktop Application** - Dual-screen support for employee and member displays
- ✅ **Python Hardware Bridge (BBK-Bridge.exe)** - 37.53 MB standalone executable
- ✅ **Configuration System** - Hardware settings via config.json
- ✅ **Production Dependencies** - Only runtime node_modules (60 files)
- ✅ **Auto-Start Scripts** - START.bat for one-click launch

### Package Structure
```
BBK-Desktop-App-Release/
├── START.bat                      # Launch application
├── README.txt                     # Quick reference
├── config.json                    # Hardware configuration
├── main-hardware-bridge.js        # Electron main process
├── preload.js                     # IPC communication bridge
├── package.json                   # Runtime dependencies
├── package-lock.json              # Dependency lock file
│
├── python-bridge/
│   └── BBK-Bridge.exe            # Hardware service (37.53 MB)
│
├── renderer/
│   ├── employee-preload.js       # Employee window scripts
│   └── member-preload.js         # Member window scripts
│
├── resources/
│   ├── icon.ico                  # Application icon
│   └── [other resources]
│
├── logs/                          # Application logs (empty on install)
│
└── node_modules/                  # Production dependencies (60 files)
    ├── electron/
    ├── ws/
    └── [other runtime modules]
```

---

## 🚀 Installation & Deployment

### Step 1: Extract Package
```batch
# Extract BBK-Desktop-App-v1.0.0.zip to desired location
# Example: C:\BBK-Desktop-App\
```

### Step 2: Configure Hardware Settings

Edit **config.json** in the root folder:

```json
{
  "version": "1.0.0",
  "app_name": "BBK Hardware Bridge",
  "gym_id": 1,
  
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
      "ip": "192.168.1.201",          ← CHANGE THIS to your device IP
      "port": 4370,
      "timeout": 5,
      "auto_reconnect": true
    },
    "doorlock": {
      "port": "COM7",                 ← CHANGE THIS to your COM port
      "baudrate": 9600,
      "open_duration": 5000
    }
  },
  
  "python_bridge": {
    "enabled": true,
    "port": 8000,
    "auto_start": true
  }
}
```

### Step 3: Connect Hardware

#### Fingerprint Device (ZKTeco)
1. Connect device to local network via Ethernet
2. Find device IP address (default: 192.168.1.201)
3. Update **config.json** → `hardware.fingerprint.ip`
4. Verify connection: Device should be pingable

#### Door Lock (Arduino/Serial)
1. Connect door lock controller via USB
2. Find COM port in Device Manager → Ports (COM & LPT)
3. Update **config.json** → `hardware.doorlock.port`
4. Default baudrate: 9600

### Step 4: Launch Application

**Option A: One-Click Start (Recommended)**
```batch
# Double-click START.bat
# This will:
# 1. Start Python Bridge (BBK-Bridge.exe) on port 8000
# 2. Wait 3 seconds for bridge initialization
# 3. Launch Electron app with dual screens
```

**Option B: Manual Start**
```batch
# Terminal 1: Start Python Bridge
python-bridge\BBK-Bridge.exe

# Terminal 2: Start Electron App
npm start
```

### Step 5: Verify Operation

✅ **Python Bridge Running**
- Check for BBK-Bridge.exe in Task Manager
- Should be listening on http://localhost:8000
- WebSocket endpoint: ws://localhost:8000/ws/mirror

✅ **Electron App Running**
- **Window 1 (Primary):** Employee Dashboard at https://bbkdashboard.vercel.app/
- **Window 2 (Secondary):** Member Kiosk at https://bbkdashboard.vercel.app/member-screen

✅ **Hardware Connected**
- Fingerprint device responds to attendance
- Door lock opens on valid fingerprint
- Logs appear in **logs/** folder

---

## 🔧 Configuration Options

### Display Settings

```json
"screens": {
  "employee": {
    "display_index": 0,      // 0 = Primary monitor
    "dev_tools": false       // Set true for debugging
  },
  "member": {
    "display_index": 1,      // 1 = Secondary monitor
    "fullscreen": true,
    "kiosk_mode": true       // Prevents exit/menu access
  }
}
```

### Fingerprint Device Settings

```json
"fingerprint": {
  "ip": "192.168.1.201",     // Device IP address
  "port": 4370,              // ZKTeco default port
  "timeout": 5,              // Connection timeout (seconds)
  "auto_reconnect": true     // Reconnect on disconnect
}
```

**Finding Device IP:**
```batch
# Method 1: Check device LCD screen
# Method 2: Use ZKTeco software (ZKAccess or SearchDevice.exe)
# Method 3: Check router DHCP leases
```

### Door Lock Settings

```json
"doorlock": {
  "port": "COM7",            // Serial port
  "baudrate": 9600,          // Communication speed
  "open_duration": 5000      // Door open time (milliseconds)
}
```

**Finding COM Port:**
```batch
# 1. Open Device Manager (devmgmt.msc)
# 2. Expand "Ports (COM & LPT)"
# 3. Look for "USB Serial Port (COMx)" or "Arduino"
# 4. Note the COM number
```

---

## 🌐 Cloud Integration

The desktop app connects to the cloud dashboard for:
- Member profile synchronization
- Real-time attendance tracking
- Promotional media display
- System configuration

**Cloud Endpoints:**
- Production: https://bbkdashboard.vercel.app
- Employee Dashboard: https://bbkdashboard.vercel.app/dashboard
- Member Kiosk: https://bbkdashboard.vercel.app/member-screen
- API: https://bbkdashboard.vercel.app/api/*

---

## 🛠️ Troubleshooting

### Python Bridge Won't Start

**Issue:** BBK-Bridge.exe fails to launch or crashes immediately

**Solutions:**
1. Check if port 8000 is already in use:
   ```batch
   netstat -ano | findstr :8000
   ```
2. Verify config.json exists and is valid JSON
3. Check logs/bridge.log for errors
4. Run as Administrator if COM port access is denied

### Hardware Not Detected

**Fingerprint Device:**
```batch
# Test connection
ping 192.168.1.201

# If no response:
# 1. Check cable connection
# 2. Verify device is powered on
# 3. Check if IP matches config.json
# 4. Try accessing device web interface (http://192.168.1.201)
```

**Door Lock:**
```batch
# Check COM port
mode COM7:

# If error:
# 1. Verify cable connection
# 2. Check Device Manager for COM port
# 3. Try different USB port
# 4. Update USB-Serial drivers
```

### Electron App Issues

**Symptom:** App crashes or won't open

**Solutions:**
1. Delete node_modules and reinstall:
   ```batch
   rmdir /s /q node_modules
   npm install --production
   ```
2. Clear Electron cache:
   ```batch
   del /q %APPDATA%\BBK-Desktop-App\*
   ```
3. Check internet connection (required for cloud dashboard)
4. Verify Node.js is installed (check with `node -v`)

### Member Screen Not Updating

**Issue:** Employee changes don't reflect on member kiosk

**Solutions:**
1. Verify WebSocket connection:
   - Open browser DevTools (F12) on both screens
   - Check Console for WebSocket errors
2. Check Python Bridge is running (Task Manager → BBK-Bridge.exe)
3. Restart both bridge and Electron app

### Logs Location

All logs are stored in **logs/** folder:
- `bridge.log` - Python bridge hardware events
- `electron.log` - Electron app errors
- `attendance.log` - Fingerprint attendance records

---

## 📋 System Requirements

### Minimum
- **OS:** Windows 10 (64-bit)
- **RAM:** 4 GB
- **Disk:** 500 MB free space
- **Network:** Internet connection + Local network for hardware
- **Display:** Dual monitors for full functionality

### Recommended
- **OS:** Windows 11 (64-bit)
- **RAM:** 8 GB
- **Disk:** 1 GB free space
- **Network:** Stable broadband connection
- **Display:** 2x 1920x1080 monitors

### Hardware Requirements
- **Fingerprint Device:** ZKTeco compatible device (tested with ZK4500)
- **Door Lock:** Arduino/relay controller with USB serial
- **Ports:** 1x Ethernet, 1x USB

---

## 🔄 Updates & Maintenance

### Updating Configuration
1. Stop application
2. Edit config.json
3. Restart application (changes apply immediately)

### Updating Cloud Dashboard
- No action needed - updates deploy automatically
- Desktop app always uses latest version from Vercel

### Backup Important Files
- **config.json** - Your hardware configuration
- **logs/** - Attendance and error logs

---

## 🆘 Support

### Documentation Files
- README.txt - Quick start guide
- DEPLOYMENT_GUIDE.md - This file

### Online Resources
- Cloud Dashboard: https://bbkdashboard.vercel.app
- GitHub Repository: [Your Repo URL]

### Technical Support
- Check logs/ folder for error details
- Review troubleshooting section above
- Contact system administrator

---

## 📄 License

**BBK Desktop App - Hardware Bridge Edition**  
Version 1.0.0  
Proprietary Software - All Rights Reserved  

This software is licensed for use at authorized BBK Gym locations only. Unauthorized distribution, modification, or reverse engineering is prohibited.

---

## ✅ Deployment Checklist

Before going live:

- [ ] Package extracted to desired location
- [ ] config.json configured with correct IPs and COM ports
- [ ] Fingerprint device connected and tested (ping successful)
- [ ] Door lock connected and port verified (Device Manager)
- [ ] Python Bridge starts successfully (BBK-Bridge.exe in Task Manager)
- [ ] Electron app opens both windows (employee + member)
- [ ] Cloud dashboard loads in both windows
- [ ] Test fingerprint attendance (should open door and log attendance)
- [ ] Test member screen mirroring (show member details from employee screen)
- [ ] Verify logs are being written to logs/ folder
- [ ] Create backup of config.json

---

**Last Updated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Package Version:** 1.0.0  
**Support Contact:** [Your Support Email/Phone]
