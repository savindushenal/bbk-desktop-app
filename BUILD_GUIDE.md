# BBK Gym Management - Build & Distribution Guide

## Quick Build Commands

### For End Users (Recommended)
```bash
# Build installer (.exe)
npm run dist

# Build portable version (no installation required)
npm run dist:portable
```

### Output Files
After building, find in `dist/` folder:
- **Installer**: `BBK Gym Management-Setup-0.1.0.exe` (Recommended)
- **Portable**: `BBK Gym Management-Portable-0.1.0.exe` (No admin rights needed)

## Build Process

### 1. Prerequisites
- Node.js 18+ installed
- Windows 10/11 (64-bit)
- Git (optional)

### 2. Install Dependencies
```bash
cd bbkdashboard-nextjs
npm install
```

### 3. Build Application
```bash
# Creates both installer and portable versions
npm run dist
```

### 4. Test Build
Run the installer or portable .exe from `dist/` folder

## Distribution Files

### What Gets Packaged
✓ Electron desktop application
✓ All UI components and pages
✓ Gym-bridge Python backend (bundled)
✓ Configuration files
✓ Documentation

### What's NOT Included (Must Install Separately)
✗ Python runtime (if using gym-bridge)
✗ MySQL database
✗ Fingerprint device drivers

## Installer Options

### Standard Installer (NSIS)
- **Size**: ~200-300 MB
- **Installation**: Requires admin rights
- **Location**: User chooses install directory
- **Shortcuts**: Desktop + Start Menu
- **Uninstaller**: Included in Control Panel
- **Updates**: Can be updated by running new installer

### Portable Version
- **Size**: ~200-300 MB
- **Installation**: None required
- **Location**: Run from any folder (USB drive compatible)
- **Shortcuts**: None (manual creation)
- **Uninstaller**: Just delete folder
- **Updates**: Replace with new portable .exe

## Deployment Checklist

### Before Building
- [ ] Update version in `package.json`
- [ ] Test application locally with `npm run electron`
- [ ] Verify Vercel dashboard URL is correct
- [ ] Check all menu navigation works
- [ ] Test member kiosk and display screens

### After Building
- [ ] Test installer on clean Windows machine
- [ ] Test portable version on different PC
- [ ] Verify desktop shortcuts work
- [ ] Check application starts correctly
- [ ] Test member kiosk and screen modes

### For Deployment
- [ ] Copy installer to USB drive or network share
- [ ] Prepare gym-bridge setup instructions
- [ ] Document Python installation requirements
- [ ] Create quick start guide for staff
- [ ] Plan hardware setup (fingerprint, door lock, printer)

## Installation Instructions (For End Users)

### Method 1: Standard Installation (Recommended)

1. **Download** `BBK Gym Management-Setup-0.1.0.exe`

2. **Run Installer**
   - Double-click the .exe file
   - Windows may show security warning - click "More info" → "Run anyway"
   - Choose installation directory (default: `C:\Program Files\BBK Gym Management`)
   - Click "Install"

3. **Launch Application**
   - Desktop shortcut: "BBK Gym Management"
   - Or: Start Menu → BBK Gym Management

4. **First Launch**
   - Application loads Vercel dashboard: https://bbkdashboard.vercel.app/
   - Login with your credentials
   - Configure hardware if needed (Menu → Hardware)

### Method 2: Portable Installation

1. **Download** `BBK Gym Management-Portable-0.1.0.exe`

2. **Choose Location**
   - Create folder: `C:\BBK-Gym` (or any location)
   - Copy portable .exe to this folder
   - No installation required!

3. **Run Application**
   - Double-click the .exe file
   - Application starts immediately

4. **Create Shortcut** (Optional)
   - Right-click .exe → Send to → Desktop (create shortcut)

## Gym-Bridge Backend Setup

The gym-bridge backend is bundled but requires Python to run.

### Install Python (One-time)
1. Download Python 3.12: https://www.python.org/downloads/
2. Install with "Add to PATH" checked
3. Open PowerShell and verify: `python --version`

### Start Gym-Bridge (Each Session)
**Option A: Manual Start**
```bash
cd "C:\Program Files\BBK Gym Management\resources\gym-bridge\backend"
python -m pip install -r requirements.txt
python main.py
```

**Option B: Create Startup Script**
Create `start-gym-bridge.bat`:
```batch
@echo off
cd /d "%~dp0resources\gym-bridge\backend"
python main.py
pause
```
Double-click to start gym-bridge backend

### Verify Backend Running
- Menu → Hardware → Check Gym-Bridge Status
- Should show: "Status: healthy, Version: 1.0.0"

## Hardware Setup

### Fingerprint Scanner
1. Connect ZKTeco device via network
2. Menu → Hardware → Fingerprint Device
3. Enter device IP and port (default: 4370)
4. Click "Connect" and test

### Door Lock
1. Connect via serial port (USB or COM port)
2. Menu → Hardware → Test Door Lock
3. Should hear/see door mechanism activate

### Receipt Printer
1. Install printer drivers (manufacturer provided)
2. Set as default Windows printer
3. Test from dashboard payment screen

## Kiosk Mode Deployment

### Member Self-Registration Kiosk
**Hardware**: Touchscreen PC/Tablet near reception

**Setup**:
1. Install BBK Gym Management
2. Create desktop shortcut
3. Configure Windows auto-login (optional)
4. Set shortcut to run on startup
5. Launch: Menu → View → Member Kiosk

**Kiosk Lock** (Prevent Exit):
- Application runs in fullscreen kiosk mode
- Press `Escape` to exit (staff only)
- Consider Windows kiosk mode for extra security

### Member Display Screen
**Hardware**: Large TV/Monitor + Mini PC

**Setup**:
1. Install BBK Gym Management
2. Start gym-bridge backend (for fingerprint integration)
3. Launch: Menu → View → Member Screen (Display)
4. Runs in fullscreen with promotional content

## Troubleshooting Builds

### Build Fails
**Error**: "electron-builder not found"
```bash
npm install electron-builder --save-dev
```

**Error**: "Icon file not found"
- Create `public/icon.ico` (256x256 Windows icon)
- Or remove icon setting from package.json

**Error**: "ENOENT: no such file or directory"
- Check all paths in package.json "build.files"
- Ensure electron/main.js exists

### Large File Size
If .exe is too large (>500MB):
- Remove unused dependencies
- Exclude development files in build.files
- Consider portable version instead

### Slow Build
- Builds take 5-10 minutes (normal)
- Faster PC = faster builds
- Use `npm run pack` for quick test builds (no compression)

## Version Updates

### Update Version Number
Edit `package.json`:
```json
{
  "version": "0.2.0"
}
```

### Rebuild
```bash
npm run dist
```

### Distribute Update
- Users run new installer over old version
- Or replace portable .exe

## Security Considerations

### Code Signing (Optional)
For production deployment, consider code signing:
1. Purchase code signing certificate
2. Configure in package.json:
```json
"win": {
  "certificateFile": "path/to/cert.pfx",
  "certificatePassword": "password"
}
```

### Windows SmartScreen
Unsigned apps trigger SmartScreen warning:
- Users click "More info" → "Run anyway"
- Code signing eliminates this warning

## Support & Maintenance

### Update Dashboard
- Dashboard updates happen on Vercel (automatic)
- Desktop app always loads latest from https://bbkdashboard.vercel.app/
- No need to rebuild app for dashboard changes

### Update Hardware Integration
- Update gym-bridge backend code
- Rebuild and redistribute .exe
- Or manually update gym-bridge folder in installation

### Bug Reports
- Check application logs in installation directory
- Test with `npm run electron` in development
- Review Electron DevTools (F12) for errors

## Advanced Configuration

### Custom Build Settings
Edit `package.json` → `build` section:
- Change app name
- Modify icon
- Add/remove files
- Configure installer options

### Multiple Environments
Create different builds for:
- Production (live Vercel URL)
- Staging (test Vercel URL)
- Development (localhost)

Change URL in `electron/main.js`:
```javascript
const startUrl = 'https://your-custom-url.vercel.app/';
```

## File Locations After Installation

### Standard Install
- **Application**: `C:\Program Files\BBK Gym Management\`
- **Shortcuts**: Desktop + Start Menu
- **Gym-Bridge**: `C:\Program Files\BBK Gym Management\resources\gym-bridge\`

### Portable
- **Application**: Wherever you placed the .exe
- **Gym-Bridge**: `{app-location}\resources\gym-bridge\`

## Distribution Checklist

Before releasing to gym staff:
- [ ] Build and test both installer and portable versions
- [ ] Create USB drive with installers
- [ ] Include gym-bridge setup instructions
- [ ] Add Python installer (if needed)
- [ ] Prepare staff training materials
- [ ] Document hardware setup procedures
- [ ] Create quick troubleshooting guide

## Quick Start for Staff

1. **Install Application**
   - Run `BBK Gym Management-Setup-0.1.0.exe`
   - Follow installer prompts

2. **Launch & Login**
   - Desktop shortcut: BBK Gym Management
   - Login with credentials

3. **Setup Hardware** (If Applicable)
   - Start gym-bridge backend
   - Configure fingerprint device
   - Test door lock and printer

4. **Access Kiosk Modes**
   - Member registration: Menu → View → Member Kiosk
   - Display screen: Menu → View → Member Screen

Done! The system is ready to use.
