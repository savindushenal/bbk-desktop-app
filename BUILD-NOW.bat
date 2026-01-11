@echo off
title BBK Hardware Bridge - ONE-CLICK EXE BUILDER
color 0B

:: Change to script directory
cd /d "%~dp0"

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║  BBK HARDWARE BRIDGE - ONE-CLICK EXE BUILDER             ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

:: Quick check
where python >nul 2>nul || (echo ERROR: Python not found & pause & exit /b 1)

:: Install PyInstaller if needed
python -c "import PyInstaller" >nul 2>nul || pip install pyinstaller

echo [1/2] Building Python service to EXE (this may take 2-3 minutes)...
cd python-bridge
pyinstaller --onefile --noconsole ^
  --name "BBK-Bridge" ^
  --icon=..\resources\icon.ico ^
  main.py

if %errorlevel% neq 0 (
    echo [ERROR] Python build failed
    cd ..
    pause
    exit /b 1
)

cd ..

echo [2/2] Creating portable package...
mkdir exe-output 2>nul
mkdir exe-output\logs 2>nul
copy python-bridge\dist\BBK-Bridge.exe exe-output\ >nul
copy config.json exe-output\ >nul

:: Create launcher
(
echo @echo off
echo title BBK Hardware Bridge
echo echo Starting BBK Hardware Bridge...
echo start /min "" BBK-Bridge.exe
echo timeout /t 3 ^>nul
echo start "" https://bbkdashboard.vercel.app
echo echo.
echo echo ✅ BBK Hardware Bridge is running!
echo echo    Python Bridge: http://localhost:8000
echo echo    Dashboard: https://bbkdashboard.vercel.app
echo echo.
echo echo Press any key to stop...
echo pause ^>nul
echo taskkill /F /IM BBK-Bridge.exe ^>nul 2^>nul
) > exe-output\START.bat

:: Create README
(
echo ═══════════════════════════════════════════════════
echo   BBK HARDWARE BRIDGE - PORTABLE EDITION
echo ═══════════════════════════════════════════════════
echo.
echo ⭐ QUICK START:
echo    1. Edit config.json with your device details
echo    2. Double-click START.bat
echo    3. Dashboard opens automatically!
echo.
echo 🎯 NO INSTALLATION NEEDED
echo    Works on any Windows 10/11 PC
echo    No Node.js or Python required
echo.
echo 📋 WHAT'S INCLUDED:
echo    • BBK-Bridge.exe - Hardware service
echo    • START.bat - One-click launcher
echo    • config.json - Configuration file
echo.
echo ⚙️  CONFIGURATION:
echo    Edit config.json to set:
echo    - ZKTeco device IP address
echo    - Door lock COM port
echo.
echo 📞 SUPPORT:
echo    Check http://localhost:8000/health when running
echo.
echo ═══════════════════════════════════════════════════
) > exe-output\README.txt

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║  ✅ BUILD COMPLETE!                                       ║
echo ╚══════════════════════════════════════════════════════════╝
echo.
echo 📦 Output: exe-output\
echo.
echo 📁 Files created:
echo    • BBK-Bridge.exe      (Python service - 30 MB)
echo    • START.bat           (One-click launcher)
echo    • config.json         (Configuration)
echo    • README.txt          (Instructions)
echo.
echo 🚀 To deploy:
echo    1. Copy exe-output folder to any Windows PC
echo    2. Double-click START.bat
echo.
echo 💡 Tip: Rename exe-output to "BBK Hardware Bridge"
echo         Then ZIP it for easy sharing!
echo.

explorer exe-output
echo.
pause
