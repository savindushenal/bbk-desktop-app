@echo off
title BBK Hardware Bridge - Complete System Launcher
color 0A

echo ========================================
echo   BBK Hardware Bridge - System Startup
echo ========================================
echo.

REM Kill any existing instances to prevent port conflicts
echo [1/5] Checking for existing processes...
taskkill /F /IM BBK-Bridge.exe 2>nul
taskkill /F /IM electron.exe 2>nul
timeout /t 2 /nobreak >nul

REM Start Python Bridge in background
echo [2/5] Starting Python Bridge Service...
start "" /min "%~dp0BBK-Bridge.exe"
timeout /t 3 /nobreak >nul

REM Check if bridge is running
echo [3/5] Verifying bridge health...
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:8000/health' -TimeoutSec 5; if ($response.StatusCode -eq 200) { Write-Host '[OK] Bridge is healthy' -ForegroundColor Green } else { Write-Host '[WARN] Bridge responded with status:' $response.StatusCode -ForegroundColor Yellow } } catch { Write-Host '[ERROR] Bridge not responding' -ForegroundColor Red; Write-Host 'Press any key to exit...'; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); exit 1 }"

REM Check if Node.js is installed
echo [4/5] Checking Node.js installation...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed!
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check if node_modules exists
if not exist "%~dp0node_modules" (
    echo [INSTALL] Installing dependencies...
    call npm install
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install dependencies
        pause
        exit /b 1
    )
)

REM Start Electron App
echo [5/5] Starting Desktop Application...
echo.
echo ========================================
echo   System Ready!
echo   Python Bridge: http://localhost:8000
echo   Desktop App: Starting...
echo ========================================
echo.

start "" npm start

echo.
echo Application is starting...
echo You can close this window once the app opens.
echo.
timeout /t 5 /nobreak >nul
exit
