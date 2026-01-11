@echo off
title BBK Hardware Bridge - System Check
color 0B

echo.
echo ========================================
echo   BBK Hardware Bridge - System Check
echo ========================================
echo.

:: Check Node.js
echo [CHECK] Node.js...
where node >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
    echo [OK] Node.js found: %NODE_VERSION%
) else (
    echo [FAIL] Node.js not found - Install from https://nodejs.org/
)

:: Check Python
echo [CHECK] Python...
where python >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('python --version') do set PYTHON_VERSION=%%i
    echo [OK] Python found: %PYTHON_VERSION%
) else (
    echo [FAIL] Python not found - Install from https://python.org/
)

:: Check node_modules
echo [CHECK] Node.js dependencies...
if exist "node_modules\" (
    echo [OK] Node modules installed
) else (
    echo [WARN] Node modules not installed - Run 'npm install' or start.bat
)

:: Check Python packages
echo [CHECK] Python dependencies...
python -c "import fastapi, uvicorn, pyzk, serial" >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Python packages installed
) else (
    echo [WARN] Python packages not installed - Run start.bat to auto-install
)

:: Check if Python bridge is running
echo [CHECK] Python bridge service...
curl -s http://localhost:8000/health >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Python bridge is running on port 8000
    echo.
    echo Bridge Status:
    curl -s http://localhost:8000/health
) else (
    echo [INFO] Python bridge not running - Will start with start.bat
)

:: Check config file
echo.
echo [CHECK] Configuration file...
if exist "config.json" (
    echo [OK] config.json found
    echo.
    echo Current configuration:
    type config.json | findstr /C:"ip" /C:"port" /C:"COM"
) else (
    echo [FAIL] config.json not found
)

echo.
echo ========================================
echo   System Check Complete
echo ========================================
echo.
echo Next steps:
echo - If all checks passed: Double-click start.bat
echo - If dependencies missing: start.bat will auto-install them
echo - To configure hardware: Edit config.json
echo.

pause
