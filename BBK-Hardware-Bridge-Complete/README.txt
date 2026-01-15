╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║              BBK GYM HARDWARE BRIDGE - QUICK START               ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

ONE-CLICK START:
════════════════

  ► Double-click: start.bat     (Recommended for Windows)
  
  OR
  
  ► Right-click start.ps1 → "Run with PowerShell"


WHAT HAPPENS:
═════════════

  1. Checks if Node.js and Python are installed
  2. Installs dependencies automatically (first time only)
  3. Starts Python hardware bridge in background
  4. Launches Electron multi-screen app
  5. Auto-cleanup when you close the app


FIRST TIME SETUP:
═════════════════

  Before running, make sure you have:
  
  ✓ Node.js 18+ installed → https://nodejs.org/
  ✓ Python 3.9-3.11 installed → https://python.org/
  
  The start script will handle everything else!


CONFIGURATION:
═══════════════

  To connect your hardware devices:
  
  1. Open config.json in a text editor
  2. Update the fingerprint device IP address
  3. Update the door lock COM port
  4. Save and restart the application


MANUAL START (Advanced):
════════════════════════

  If you prefer manual control:
  
  Terminal 1 (Python Bridge):
    cd python-bridge
    python main.py
  
  Terminal 2 (Electron App):
    npm start


TROUBLESHOOTING:
════════════════

  ► "Python not found"
    → Install Python and add to PATH
  
  ► "Node not found"
    → Install Node.js and add to PATH
  
  ► "Port 8000 already in use"
    → Close other instances or restart computer
  
  ► Hardware not connecting
    → Check config.json has correct IP/COM port
    → Hardware connection is optional for testing


SUPPORT:
════════

  Documentation: See QUICK_START.md
  Architecture: See ARCHITECTURE.md
  Deployment: See DEPLOYMENT.md


═══════════════════════════════════════════════════════════════════

                 Ready to start? Double-click start.bat

═══════════════════════════════════════════════════════════════════
