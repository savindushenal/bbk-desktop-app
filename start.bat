@echo off
title BBK Hardware Bridge - Starting...
color 0A

echo.
echo ========================================
echo   BBK Hardware Bridge
echo   Starting System...
echo ========================================
echo.

:: Check if Node.js is installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed!
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

:: Check if Python is installed
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed!
    echo Please install Python from https://python.org/
    pause
    exit /b 1
)

echo [1/3] Checking dependencies...

:: Check if node_modules exists
if not exist "node_modules\" (
    echo [INFO] Installing Node.js dependencies...
    call npm install
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install Node.js dependencies
        pause
        exit /b 1
    )
)

:: Check if Python packages are installed
python -c "import fastapi" >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Installing Python dependencies...
    cd python-bridge
    pip install -r requirements.txt
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install Python dependencies
        cd ..
        pause
        exit /b 1
    )
    cd ..
)

echo [2/3] Starting Python Bridge...
:: Start Python bridge in a new minimized window
start /min "BBK Python Bridge" cmd /c "cd python-bridge && python main.py"

:: Wait for Python bridge to start
timeout /t 5 /nobreak >nul

:: Check if Python bridge is running
curl -s http://localhost:8000/health >nul 2>nul
if %errorlevel% neq 0 (
    echo [WARNING] Python bridge may not be ready yet...
    echo [INFO] Waiting additional 5 seconds...
    timeout /t 5 /nobreak >nul
)

echo [3/3] Starting Electron App...
echo.
echo ========================================
echo   System Ready!
echo   Python Bridge: http://localhost:8000
echo   Electron App: Launching...
echo ========================================
echo.

:: Start Electron app
call npm start

:: Cleanup - kill Python bridge when Electron closes
echo.
echo Shutting down Python bridge...
taskkill /FI "WindowTitle eq BBK Python Bridge*" /F >nul 2>nul

echo.
echo ========================================
echo   BBK Hardware Bridge - Stopped
echo ========================================
echo.
pause
