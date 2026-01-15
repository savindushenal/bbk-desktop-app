@echo off
title BBK Hardware Bridge - Complete System
color 0A

echo.
echo ========================================
echo   BBK Hardware Bridge
echo   Complete System Launcher
echo ========================================
echo.

:: Check Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not found!
    echo Please install Node.js from: https://nodejs.org/
    pause
    exit /b 1
)

:: Install dependencies if needed
if not exist "node_modules\" (
    echo [INFO] Installing dependencies...
    call npm install
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install dependencies
        pause
        exit /b 1
    )
)

echo [START] Starting BBK Hardware Bridge...
echo.
echo   Python Bridge: http://localhost:8000
echo   Electron App:  Starting...
echo.

:: Start Python bridge in background
start /min "" BBK-Bridge.exe

:: Wait for bridge to start
timeout /t 5 /nobreak >nul

:: Start Electron app
npx electron main-hardware-bridge.js

:: Cleanup on exit
taskkill /F /IM BBK-Bridge.exe >nul 2>nul
