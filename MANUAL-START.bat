@echo off
cd /d "%~dp0"
color 0E
echo.
echo ============================================
echo   BBK Desktop App - Manual Start Guide
echo ============================================
echo.
echo If START.bat doesn't work, follow these steps:
echo.
echo ============================================
echo   STEP 1: Open Command Prompt Here
echo ============================================
echo.
echo 1. Press Windows + R
echo 2. Type: cmd
echo 3. Press Enter
echo 4. Type: cd /d "%CD%"
echo 5. Press Enter
echo.
echo ============================================
echo   STEP 2: Start Python Bridge
echo ============================================
echo.
echo Type this command:
echo   start python-bridge\BBK-Bridge.exe
echo.
echo Then press Enter and wait 3 seconds
echo.
echo ============================================
echo   STEP 3: Start Electron App
echo ============================================
echo.
echo Type this command:
echo   npm start
echo.
echo Then press Enter
echo.
echo ============================================
echo.
echo Or press any key to try automatic start...
pause >nul

echo.
echo Attempting automatic start...
echo.

start python-bridge\BBK-Bridge.exe
timeout /t 3 /nobreak >nul
npm start

pause
