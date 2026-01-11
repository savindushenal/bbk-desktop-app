@echo off
echo ===============================================
echo BBK Gym Management - Build Script
echo ===============================================
echo.

echo Checking Node.js installation...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js is not installed!
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)
echo Node.js found: 
node --version

echo.
echo Installing dependencies...
call npm install
if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo ===============================================
echo Building BBK Gym Management Application
echo This may take 5-10 minutes...
echo ===============================================
echo.

call npm run dist
if %errorlevel% neq 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo ===============================================
echo BUILD SUCCESSFUL!
echo ===============================================
echo.
echo Output files are in the 'dist' folder:
echo   - BBK Gym Management-Setup-0.1.0.exe (Installer)
echo   - BBK Gym Management-Portable-0.1.0.exe (Portable)
echo.
echo You can now distribute these files to users.
echo.
pause
