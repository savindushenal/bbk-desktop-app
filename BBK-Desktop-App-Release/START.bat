@echo off
setlocal enabledelayedexpansion
title BBK Desktop App Launcher
color 0A

REM Change to the directory where this batch file is located
cd /d "%~dp0"

echo ========================================
echo   BBK Desktop App - Starting...
echo ========================================
echo.
echo Running from: %CD%
echo NOTE: This window STAYS OPEN while app runs
echo       Close this window to stop the app
echo.

REM Check Node.js
echo [1/4] Checking Node.js...
where node >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo ERROR: Node.js NOT installed!
    echo.
    echo Install from: https://nodejs.org/
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('node -v 2^>^&1') do set NODE_VERSION=%%i
echo [OK] Node.js: %NODE_VERSION%
echo.

REM Check dependencies
echo [2/4] Checking dependencies...
if not exist "node_modules" (
    echo Installing dependencies (first run, 1-2 min)...
    echo Working directory: %CD%
    echo.
    npm install
    if !errorlevel! neq 0 (
        color 0C
        echo.
        echo ERROR: Installation failed!
        echo Check internet connection and try again
        echo.
        pause
        exit /b 1
    )
    echo [OK] Installed!
) else (
    echo [OK] Already installed
)
echo.

REM Start bridge
echo [3/4] Starting Python Bridge...
taskkill /F /IM BBK-Bridge.exe 2>nul 1>nul
if exist "python-bridge\BBK-Bridge.exe" (
    start "BBK Bridge" /min "%CD%\python-bridge\BBK-Bridge.exe"
    timeout /t 3 /nobreak >nul
    echo [OK] Bridge started
) else (
    echo [WARN] Bridge not found - hardware features disabled
)
echo.

REM Start app
echo [4/4] Starting Electron App...
echo.
echo ======================================
echo   APP RUNNING - Keep window open!
echo ======================================
echo.

npm start

echo.
echo ======================================
echo   App Closed
echo ======================================
echo.
pause

