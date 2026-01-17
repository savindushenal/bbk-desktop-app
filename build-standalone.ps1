# BBK Desktop App - Create Standalone Executable Package
$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  BBK Desktop App - Standalone Executable Builder      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$releaseFolder = "BBK-Standalone-Release"
$zipFileName = "BBK-Desktop-App-Standalone-v1.0.0.zip"

# Clean up
Write-Host "🗑️  Cleaning previous builds..." -ForegroundColor Yellow
if (Test-Path $releaseFolder) { Remove-Item -Path $releaseFolder -Recurse -Force }
if (Test-Path $zipFileName) { Remove-Item -Path $zipFileName -Force }

# Build Electron app
Write-Host "🔨 Building Electron executable..." -ForegroundColor Green
Write-Host "   This may take a few minutes..." -ForegroundColor Gray

# Install dependencies if needed
if (-not (Test-Path "node_modules")) {
    Write-Host "   Installing dependencies..." -ForegroundColor Yellow
    npm install --silent
}

# Build the executable
npm run build 2>&1 | Out-Null

if (-not (Test-Path "dist")) {
    Write-Host "❌ Build failed! Check for errors." -ForegroundColor Red
    exit 1
}

# Find the built executable
$exeFiles = Get-ChildItem -Path "dist" -Filter "*.exe" -Recurse
if ($exeFiles.Count -eq 0) {
    Write-Host "❌ No executable found in dist folder!" -ForegroundColor Red
    exit 1
}

Write-Host "   ✓ Electron app built successfully" -ForegroundColor Green

# Create release folder
Write-Host "`n📦 Creating release package..." -ForegroundColor Green
New-Item -ItemType Directory -Path $releaseFolder | Out-Null

# Copy built Electron app
Write-Host "   Copying Electron executable..." -ForegroundColor Gray
$distFolder = Get-ChildItem -Path "dist" -Directory | Select-Object -First 1
if ($distFolder) {
    Copy-Item -Path "$($distFolder.FullName)\*" -Destination $releaseFolder -Recurse
} else {
    # If no unpacked folder, copy the installer
    Copy-Item -Path "dist\*.exe" -Destination $releaseFolder
}

# Copy Python bridge
Write-Host "   Copying Python bridge..." -ForegroundColor Gray
New-Item -ItemType Directory -Path "$releaseFolder\python-bridge" -Force | Out-Null
if (Test-Path "exe-output\BBK-Bridge.exe") {
    Copy-Item "exe-output\BBK-Bridge.exe" -Destination "$releaseFolder\python-bridge\"
    Write-Host "   ✓ BBK-Bridge.exe copied" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  BBK-Bridge.exe not found - will need manual copy" -ForegroundColor Yellow
}

# Copy config
Write-Host "   Copying configuration..." -ForegroundColor Gray
Copy-Item "config.json" -Destination $releaseFolder

# Create logs folder
New-Item -ItemType Directory -Path "$releaseFolder\logs" -Force | Out-Null

# Create startup script
Write-Host "   Creating startup script..." -ForegroundColor Gray
$startBat = @"
@echo off
title BBK Desktop App Launcher
echo ========================================
echo BBK Desktop App - Starting...
echo ========================================
echo.

REM Check if Python bridge exists
if not exist "%~dp0python-bridge\BBK-Bridge.exe" (
    echo [ERROR] BBK-Bridge.exe not found!
    echo Please ensure python-bridge\BBK-Bridge.exe exists.
    pause
    exit /b 1
)

REM Check if bridge is already running
tasklist /FI "IMAGENAME eq BBK-Bridge.exe" 2>NUL | find /I /N "BBK-Bridge.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [OK] Python Bridge already running
) else (
    echo [STARTING] Python Bridge...
    start "" "%~dp0python-bridge\BBK-Bridge.exe"
    timeout /t 3 /nobreak >nul
    echo [OK] Bridge started
)

REM Find and start the Electron app
echo [STARTING] BBK Desktop App...
if exist "%~dp0BBK Hardware Bridge.exe" (
    start "" "%~dp0BBK Hardware Bridge.exe"
) else if exist "%~dp0bbk-desktop-app.exe" (
    start "" "%~dp0bbk-desktop-app.exe"
) else (
    echo [ERROR] Electron app executable not found!
    echo Looking for: "BBK Hardware Bridge.exe" or "bbk-desktop-app.exe"
    pause
    exit /b 1
)

echo.
echo [OK] Application started successfully!
echo.
echo Press any key to close this window...
pause >nul
"@

Set-Content -Path "$releaseFolder\START.bat" -Value $startBat

# Create README
Write-Host "   Creating documentation..." -ForegroundColor Gray
$readme = "BBK DESKTOP APP - STANDALONE EDITION`n"
$readme += "====================================`n`n"
$readme += "Version: 1.0.0 (Standalone)`n"
$readme += "Date: " + (Get-Date -Format "yyyy-MM-dd") + "`n`n"
$readme += "QUICK START:`n"
$readme += "1. Extract to C:\BBK-Desktop-App\`n"
$readme += "2. Edit config.json (set fingerprint IP and door lock COM port)`n"
$readme += "3. Double-click START.bat`n`n"
$readme += "HARDWARE CONFIGURATION:`n"
$readme += "Edit config.json -> hardware.fingerprint.ip and hardware.doorlock.port`n`n"
$readme += "TROUBLESHOOTING:`n"
$readme += "- Bridge won't start: Check port 8000 is free`n"
$readme += "- Hardware not working: Verify IP/COM port in config.json`n"
$readme += "- App won't launch: Run as Administrator`n`n"
$readme += "NO NODE.JS REQUIRED - Standalone executable!`n"

Set-Content -Path "$releaseFolder\README.txt" -Value $readme

# Copy documentation
if (Test-Path "DEPLOYMENT_GUIDE.md") {
    Copy-Item "DEPLOYMENT_GUIDE.md" -Destination $releaseFolder
}
if (Test-Path "QUICK_REFERENCE.txt") {
    Copy-Item "QUICK_REFERENCE.txt" -Destination $releaseFolder
}

# Create .zip
Write-Host "`n📦 Creating ZIP archive..." -ForegroundColor Green
Compress-Archive -Path "$releaseFolder\*" -DestinationPath $zipFileName -Force

# Show results
$zipSize = (Get-Item $zipFileName).Length / 1MB
Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              BUILD SUCCESSFUL!                         ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📦 PACKAGE CREATED:" -ForegroundColor Cyan
Write-Host "   File: $zipFileName" -ForegroundColor White
Write-Host "   Size: $([math]::Round($zipSize, 2)) MB" -ForegroundColor White
Write-Host "   Type: Standalone Executable (No Node.js required)`n" -ForegroundColor White

Write-Host "📁 CONTENTS:" -ForegroundColor Cyan
Get-ChildItem -Path $releaseFolder | ForEach-Object {
    if ($_.PSIsContainer) {
        $count = (Get-ChildItem -Path $_.FullName -Recurse -File).Count
        Write-Host "   ✓ $($_.Name)\ ($count files)" -ForegroundColor White
    } else {
        $size = [math]::Round($_.Length/1KB, 2)
        Write-Host "   ✓ $($_.Name) ($size KB)" -ForegroundColor White
    }
}

Write-Host "`n🚀 DEPLOYMENT:" -ForegroundColor Cyan
Write-Host "   1. Extract $zipFileName" -ForegroundColor White
Write-Host "   2. Edit config.json" -ForegroundColor White
Write-Host "   3. Run START.bat`n" -ForegroundColor White

Write-Host "✅ Ready to deploy!`n" -ForegroundColor Green
