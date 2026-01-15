==========================================
   BBK HARDWARE BRIDGE - COMPLETE PACKAGE
==========================================

This package contains the complete BBK Hardware Bridge system:
- Python Bridge Service (BBK-Bridge.exe)
- Electron Desktop Application

QUICK START
===========
1. Double-click START-APP.bat
2. Wait for the system to start (10-15 seconds)
3. The desktop application will open automatically

REQUIREMENTS
============
- Windows 10/11 (64-bit)
- Node.js 18+ (Download from https://nodejs.org/)
- Internet connection (for first-time setup)

FIRST TIME SETUP
================
1. Install Node.js if not already installed
2. Run START-APP.bat
3. The script will automatically install dependencies
4. System will start when ready

WHAT HAPPENS ON STARTUP
========================
1. Kills any existing BBK processes
2. Starts Python Bridge Service (port 8000)
3. Verifies bridge health
4. Installs Node.js dependencies (first run only)
5. Starts Electron Desktop Application

CONFIGURATION
=============
Edit config.json to customize:
- Screen URLs (employee/member displays)
- Hardware devices (fingerprint/doorlock)
- Server settings (host/port)

HARDWARE DEVICES
================
The system works WITHOUT hardware devices connected!
- Fingerprint: ZKTeco device on 192.168.1.201:4370
- Door Lock: Arduino/relay on COM7 @ 9600 baud

If devices are not available, the system will log warnings
but continue to operate normally.

TROUBLESHOOTING
===============
Port Already in Use (Error 10048):
- Run START-APP.bat again (it kills old processes)
- Or manually: taskkill /F /IM BBK-Bridge.exe

Bridge Not Responding:
- Check logs\python-bridge.log
- Verify port 8000 is not blocked by firewall

Desktop App Not Opening:
- Install Node.js from https://nodejs.org/
- Delete node_modules folder and run START-APP.bat

LOGS
====
- Python Bridge: logs\python-bridge.log
- Electron App: Console in Developer Tools (Ctrl+Shift+I)

SUPPORT
=======
GitHub: https://github.com/savindushenal/bbk-desktop-app
Email: support@bbk.com

==========================================
   System Version 1.0.0 - January 2026
==========================================
