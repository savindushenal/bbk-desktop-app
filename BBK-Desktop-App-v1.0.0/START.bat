@echo off
cd /d "%~dp0"
echo.
echo ============================================
echo   BBK Desktop App - Starting
echo ============================================
echo.
echo Working directory: %CD%
echo.

where node >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js not installed!
    echo Install from: https://nodejs.org/
    echo.
    pause
    exit /b 1
)

echo [1/3] Node.js: OK
echo.

if not exist "node_modules" (
    echo [2/3] Installing dependencies...
    echo This will take 1-2 minutes...
    echo.
    npm install
    if errorlevel 1 (
        echo.
        echo [ERROR] npm install failed!
        pause
        exit /b 1
    )
) else (
    echo [2/3] Dependencies: OK
)

echo.
echo [3/3] Starting Python Bridge...
taskkill /F /IM BBK-Bridge.exe >nul 2>&1
start "BBK Bridge" /min python-bridge\BBK-Bridge.exe
timeout /t 3 /nobreak >nul
echo.

echo ============================================
echo   Starting Electron App
echo ============================================
echo.
echo Window will stay open. Close to stop app.
echo.

npm start

echo.
echo ============================================
echo   App Stopped
echo ============================================
echo.
pause

