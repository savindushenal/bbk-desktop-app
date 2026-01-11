@echo off
title BBK Hardware Bridge - Creating Release Package
color 0E

echo.
echo ========================================
echo   BBK Hardware Bridge
echo   Creating Release Package
echo ========================================
echo.

:: Create release directory
if not exist "release" mkdir release
if exist "release\bbk-hardware-bridge" rmdir /s /q "release\bbk-hardware-bridge"
mkdir "release\bbk-hardware-bridge"

echo [1/5] Copying application files...
xcopy /E /I /Y "*.js" "release\bbk-hardware-bridge\" >nul
xcopy /E /I /Y "*.json" "release\bbk-hardware-bridge\" >nul
xcopy /E /I /Y "*.md" "release\bbk-hardware-bridge\" >nul
xcopy /E /I /Y "*.txt" "release\bbk-hardware-bridge\" >nul
xcopy /E /I /Y "*.bat" "release\bbk-hardware-bridge\" >nul
xcopy /E /I /Y "*.ps1" "release\bbk-hardware-bridge\" >nul

echo [2/5] Copying Python bridge...
xcopy /E /I /Y "python-bridge" "release\bbk-hardware-bridge\python-bridge\" >nul

echo [3/5] Copying renderer files...
if exist "renderer" xcopy /E /I /Y "renderer" "release\bbk-hardware-bridge\renderer\" >nul

echo [4/5] Installing Node.js dependencies...
cd release\bbk-hardware-bridge
call npm install --production
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install Node.js dependencies
    cd ..\..
    pause
    exit /b 1
)
cd ..\..

echo [5/5] Creating README...
(
echo BBK HARDWARE BRIDGE - PORTABLE PACKAGE
echo =======================================
echo.
echo SYSTEM REQUIREMENTS:
echo - Windows 10/11 ^(64-bit^)
echo - Node.js 18+ ^(https://nodejs.org/^)
echo - Python 3.9-3.11 ^(https://python.org/^)
echo.
echo FIRST TIME SETUP:
echo 1. Install Node.js and Python if not already installed
echo 2. Double-click start.bat
echo 3. Wait for dependencies to install automatically
echo 4. Application will launch when ready
echo.
echo CONFIGURATION:
echo - Edit config.json to set your device IP and COM port
echo - See START_HERE.txt for detailed instructions
echo.
echo DOCUMENTATION:
echo - QUICK_START.md - 5-minute setup guide
echo - ARCHITECTURE.md - System design and architecture
echo - DEPLOYMENT.md - Production deployment guide
echo.
) > "release\bbk-hardware-bridge\README.txt"

echo.
echo ========================================
echo   Package Created Successfully!
echo   Location: release\bbk-hardware-bridge
echo ========================================
echo.
echo Next steps:
echo 1. Copy the release\bbk-hardware-bridge folder to target computer
echo 2. Install Node.js and Python on target computer
echo 3. Double-click start.bat to run
echo.

:: Ask if user wants to create ZIP
set /p createzip="Create ZIP archive? (Y/N): "
if /i "%createzip%"=="Y" (
    echo.
    echo Creating ZIP archive...
    powershell -command "Compress-Archive -Path 'release\bbk-hardware-bridge\*' -DestinationPath 'release\bbk-hardware-bridge.zip' -Force"
    if %errorlevel% equ 0 (
        echo [OK] ZIP created: release\bbk-hardware-bridge.zip
    ) else (
        echo [ERROR] Failed to create ZIP
    )
)

echo.
pause
