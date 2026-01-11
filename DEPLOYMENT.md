# BBK Hardware Bridge - Deployment Guide

## 📦 Packaging & Deployment for Windows

This guide explains how to package and deploy the BBK Hardware Bridge desktop application.

---

## Prerequisites

### 1. Development Environment
- **Windows 10/11** (64-bit)
- **Node.js** 18+ ([Download](https://nodejs.org/))
- **Python** 3.9-3.11 ([Download](https://www.python.org/))
- **Git** ([Download](https://git-scm.com/))

### 2. Hardware Setup
- ZKTeco fingerprint device (configured on network)
- Door lock Arduino/relay (connected to COM port)
- Multiple monitors (optional, for dual-screen mode)

---

## 🔧 Installation Steps

### Step 1: Clone Repository
```bash
cd E:\githubNew\bbk
git clone https://github.com/yourusername/bbk-desktop-app.git
cd bbk-desktop-app
```

### Step 2: Install Node.js Dependencies
```powershell
npm install ws@^8.16.0 electron-log@^5.0.1
npm install --save-dev electron@^33.2.1 electron-packager@^17.1.2
```

### Step 3: Install Python Dependencies
```powershell
cd python-bridge
pip install -r requirements.txt
cd ..
```

Verify Python packages:
```powershell
python -c "import fastapi, pyzk, serial; print('All packages installed')"
```

### Step 4: Configure Application
Edit `config.json`:
```json
{
  "hardware": {
    "fingerprint": {
      "ip": "YOUR_DEVICE_IP",        # Change this!
      "port": 4370
    },
    "doorlock": {
      "port": "COM7"                  # Change if different!
    }
  }
}
```

Test fingerprint connection:
```bash
python python-bridge/test-connection.py
```

---

## 🚀 Running in Development

### Option 1: Run with Electron
```powershell
npm run start:hardware
```

This will:
1. Start Electron app with hardware bridge
2. Auto-start Python service
3. Load cloud dashboard URLs
4. Connect to ZKTeco device

### Option 2: Run Components Separately

**Terminal 1 - Python Bridge:**
```powershell
cd python-bridge
python main.py
```

**Terminal 2 - Electron App:**
```powershell
npm start
```

**Verify Health:**
Open browser: http://localhost:8000/health

---

## 📦 Building for Production

### Step 1: Build Python Service
```powershell
cd python-bridge
pyinstaller --onefile --name bridge-service main.py
```

This creates: `python-bridge/dist/bridge-service.exe` (standalone executable)

### Step 2: Build Electron App
```powershell
# Return to root
cd ..

# Build with electron-packager
npm run build
```

This creates: `dist/BBK Hardware Bridge-win32-x64/`

### Step 3: Bundle Together
Create release folder:
```powershell
mkdir release
mkdir release\BBK-Hardware-Bridge

# Copy Electron app
xcopy "dist\BBK Hardware Bridge-win32-x64\*" "release\BBK-Hardware-Bridge\" /E /I /Y

# Copy Python service
mkdir "release\BBK-Hardware-Bridge\resources\python-bridge"
copy "python-bridge\dist\bridge-service.exe" "release\BBK-Hardware-Bridge\resources\python-bridge\"

# Copy config
copy "config.json" "release\BBK-Hardware-Bridge\"

# Copy README
copy "DEPLOYMENT.md" "release\BBK-Hardware-Bridge\README.txt"
```

### Step 4: Create Installer (Optional)

Using **Inno Setup**:
1. Install Inno Setup: https://jrsoftware.org/isinfo.php
2. Create `installer.iss`:

```inno
[Setup]
AppName=BBK Hardware Bridge
AppVersion=1.0.0
DefaultDirName={pf}\BBK Hardware Bridge
DefaultGroupName=BBK Gym
OutputDir=installer
OutputBaseFilename=BBK-Hardware-Bridge-Setup

[Files]
Source: "release\BBK-Hardware-Bridge\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\BBK Hardware Bridge"; Filename: "{app}\BBK Hardware Bridge.exe"
Name: "{commondesktop}\BBK Hardware Bridge"; Filename: "{app}\BBK Hardware Bridge.exe"

[Run]
Filename: "{app}\BBK Hardware Bridge.exe"; Description: "Launch BBK Hardware Bridge"; Flags: postinstall nowait
```

3. Compile:
```powershell
iscc installer.iss
```

Output: `installer/BBK-Hardware-Bridge-Setup.exe`

---

## 📋 Pre-Deployment Checklist

### Software Requirements
- [ ] Python 3.9-3.11 installed on target machine
- [ ] Windows 10/11 64-bit
- [ ] .NET Framework 4.7.2+ (usually pre-installed)
- [ ] Visual C++ Redistributable 2015-2022

### Hardware Requirements
- [ ] ZKTeco device accessible on network
- [ ] Door lock connected to COM port
- [ ] Multiple monitors (if using dual-screen mode)

### Configuration
- [ ] `config.json` updated with correct IPs/ports
- [ ] Firewall rules allow port 8000 (Python bridge)
- [ ] Network allows access to bbkdashboard.vercel.app
- [ ] Serial port permissions (COM7 accessible)

### Testing
- [ ] Test fingerprint scan
- [ ] Test door lock open/close
- [ ] Test dual-screen display
- [ ] Test auto-reconnect on device disconnect
- [ ] Test offline mode (queue events)

---

## 🖥️ Deployment Options

### Option 1: Portable Version (Recommended)
**Advantages:**
- No installation required
- Easy to update (replace folder)
- Works on USB drive

**Distribution:**
1. Zip the `release/BBK-Hardware-Bridge` folder
2. Share via:
   - USB drive
   - Network share
   - Cloud storage (Google Drive, Dropbox)

**Usage:**
```powershell
# User extracts ZIP
# Double-click: BBK Hardware Bridge.exe
```

### Option 2: Installer Version
**Advantages:**
- Professional installation experience
- Desktop shortcuts created
- Uninstaller included

**Distribution:**
1. Share `BBK-Hardware-Bridge-Setup.exe`
2. User runs installer
3. App installed to `C:\Program Files\BBK Hardware Bridge\`

---

## 🔄 Auto-Start Configuration

### Method 1: Task Scheduler
1. Open Task Scheduler
2. Create Basic Task
3. Trigger: At log on
4. Action: Start a program
5. Program: `C:\Program Files\BBK Hardware Bridge\BBK Hardware Bridge.exe`
6. ✅ Run with highest privileges

### Method 2: Startup Folder
```powershell
# Create shortcut
$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\BBK Hardware Bridge.lnk")
$Shortcut.TargetPath = "C:\Program Files\BBK Hardware Bridge\BBK Hardware Bridge.exe"
$Shortcut.Save()
```

---

## 🐛 Troubleshooting

### Python Bridge Not Starting
**Symptoms:** App shows "Python bridge disconnected"

**Solutions:**
1. Check Python installation:
   ```powershell
   python --version
   # Should show 3.9-3.11
   ```

2. Test Python service manually:
   ```powershell
   cd "C:\Program Files\BBK Hardware Bridge\resources\python-bridge"
   .\bridge-service.exe
   # Should show "Running on http://0.0.0.0:8000"
   ```

3. Check firewall:
   ```powershell
   netsh advfirewall firewall add rule name="BBK Python Bridge" dir=in action=allow protocol=TCP localport=8000
   ```

### Fingerprint Device Not Connecting
**Symptoms:** Health check shows `fingerprint.connected: false`

**Solutions:**
1. Verify IP address:
   ```powershell
   ping 192.168.1.201
   ```

2. Check device admin panel (usually http://DEVICE_IP/)
3. Ensure port 4370 is open
4. Try manual test:
   ```powershell
   cd python-bridge
   python -c "from zk import ZK; zk = ZK('192.168.1.201', port=4370); conn = zk.connect(); print('Connected!'); conn.disconnect()"
   ```

### Door Lock Not Working
**Symptoms:** Door doesn't open on finger scan

**Solutions:**
1. Check COM port:
   ```powershell
   # In Device Manager, find correct COM port number
   # Update config.json
   ```

2. Test serial connection:
   ```powershell
   python -c "import serial; ser = serial.Serial('COM7', 9600); ser.write(b'o'); ser.close(); print('Sent open command')"
   ```

3. Verify Arduino/relay wiring

### Multi-Screen Not Working
**Symptoms:** Member screen doesn't appear on second monitor

**Solutions:**
1. Verify displays detected:
   ```javascript
   // In Electron DevTools console
   require('electron').screen.getAllDisplays()
   ```

2. Check `config.json`:
   ```json
   "screens": {
     "member": {
       "display_index": 1  // 0 = primary, 1 = secondary
     }
   }
   ```

3. Restart app after connecting monitor

---

## 📊 Monitoring & Logs

### Log Locations
- **Electron logs:** `%APPDATA%\bbk-hardware-bridge\logs\electron.log`
- **Python logs:** `python-bridge/logs/python-bridge.log`
- **Fingerprint logs:** `python-bridge/logs/fingerprint.log`

### View Logs
```powershell
# Electron
Get-Content "$env:APPDATA\bbk-hardware-bridge\logs\electron.log" -Tail 50 -Wait

# Python
Get-Content "python-bridge\logs\python-bridge.log" -Tail 50 -Wait
```

### Health Monitoring
```powershell
# Check if Python bridge is running
curl http://localhost:8000/health

# Expected response:
{
  "status": "healthy",
  "fingerprint": { "connected": true },
  "doorlock": { "connected": true }
}
```

---

## 🔐 Security Considerations

### Network Security
- [ ] Fingerprint device on isolated VLAN
- [ ] Firewall rules restrict Python bridge to localhost
- [ ] HTTPS enforced for cloud dashboard

### Physical Security
- [ ] Serial port access restricted
- [ ] Device room locked
- [ ] Backup authentication method

### Data Security
- [ ] Fingerprint templates encrypted on device
- [ ] No templates transmitted to cloud
- [ ] Local logs rotated/archived

---

## 📱 Update Procedure

### Minor Updates (Config/Settings)
1. Edit `config.json` on target machine
2. Restart app

### Code Updates
1. Build new version
2. Stop running app
3. Replace exe files
4. Start app

### Python Updates
1. Rebuild Python bridge: `pyinstaller --onefile...`
2. Replace `bridge-service.exe`
3. Restart app

---

## 💾 Backup & Restore

### Backup Config
```powershell
# Backup
Copy-Item "C:\Program Files\BBK Hardware Bridge\config.json" "C:\Backup\config-$(Get-Date -Format 'yyyy-MM-dd').json"

# Restore
Copy-Item "C:\Backup\config-2026-01-10.json" "C:\Program Files\BBK Hardware Bridge\config.json"
```

### Backup Logs
```powershell
Compress-Archive -Path "C:\Program Files\BBK Hardware Bridge\logs" -DestinationPath "C:\Backup\logs-$(Get-Date -Format 'yyyy-MM-dd').zip"
```

---

## 📞 Support

### Documentation
- Architecture: `ARCHITECTURE.md`
- API Reference: `API_REFERENCE.md`
- Build Guide: `BUILD_GUIDE.md`

### Contact
- Email: support@bbkgym.com
- GitHub: https://github.com/yourusername/bbk-hardware-bridge

---

## ✅ Deployment Success Criteria

- [ ] App starts automatically on boot
- [ ] Python bridge connects within 5 seconds
- [ ] Fingerprint device responds to scans
- [ ] Door opens on valid member scan
- [ ] Member screen shows on second monitor
- [ ] Employee dashboard loads cloud URL
- [ ] Logs written to correct locations
- [ ] Auto-reconnect works after device restart

**Congratulations! Your BBK Hardware Bridge is now deployed! 🎉**
