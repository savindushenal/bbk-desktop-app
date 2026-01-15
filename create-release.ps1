# BBK Desktop App - Create Optimized Release Package
# This script creates a production-ready .zip with only necessary files

$ErrorActionPreference = "Stop"

Write-Host "🚀 BBK Desktop App - Release Package Creator" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$releaseFolder = "BBK-Desktop-App-Release"
$zipFileName = "BBK-Desktop-App-v1.0.0.zip"

# Clean up previous release
if (Test-Path $releaseFolder) {
    Write-Host "🗑️  Removing previous release folder..." -ForegroundColor Yellow
    Remove-Item -Path $releaseFolder -Recurse -Force
}

if (Test-Path $zipFileName) {
    Write-Host "🗑️  Removing previous .zip file..." -ForegroundColor Yellow
    Remove-Item -Path $zipFileName -Force
}

# Create release folder
Write-Host "📁 Creating release folder..." -ForegroundColor Green
New-Item -ItemType Directory -Path $releaseFolder | Out-Null

# Copy essential files
Write-Host "📦 Copying essential files..." -ForegroundColor Green

# Main application files
Copy-Item "main-hardware-bridge.js" -Destination $releaseFolder
Copy-Item "preload.js" -Destination $releaseFolder
Copy-Item "package.json" -Destination $releaseFolder
Copy-Item "config.json" -Destination $releaseFolder

# Renderer folder
Write-Host "   - Copying renderer files..."
Copy-Item -Path "renderer" -Destination $releaseFolder -Recurse

# Resources folder
Write-Host "   - Copying resources..."
Copy-Item -Path "resources" -Destination $releaseFolder -Recurse

# Python bridge (exe-output folder with BBK-Bridge.exe)
Write-Host "   - Copying Python bridge..."
New-Item -ItemType Directory -Path "$releaseFolder\python-bridge" | Out-Null
if (Test-Path "exe-output\BBK-Bridge.exe") {
    Copy-Item "exe-output\BBK-Bridge.exe" -Destination "$releaseFolder\python-bridge\"
    Write-Host "   ✓ BBK-Bridge.exe copied" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Warning: BBK-Bridge.exe not found in exe-output!" -ForegroundColor Yellow
    Write-Host "   Building bridge executable..." -ForegroundColor Yellow
    
    # Try to build if not exists
    if (Test-Path "python-bridge\build-exe.bat") {
        Push-Location python-bridge
        & .\build-exe.bat
        Pop-Location
        
        if (Test-Path "exe-output\BBK-Bridge.exe") {
            Copy-Item "exe-output\BBK-Bridge.exe" -Destination "$releaseFolder\python-bridge\"
            Write-Host "   ✓ BBK-Bridge.exe built and copied" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Failed to build BBK-Bridge.exe" -ForegroundColor Red
        }
    }
}

# Copy logs folder structure (empty)
New-Item -ItemType Directory -Path "$releaseFolder\logs" | Out-Null

# Install production node_modules
Write-Host "📦 Installing production dependencies..." -ForegroundColor Green
Push-Location $releaseFolder
npm install --production --silent 2>&1 | Out-Null
Pop-Location
Write-Host "   ✓ Dependencies installed" -ForegroundColor Green

# Create documentation
Write-Host "📝 Creating documentation..." -ForegroundColor Green

$readmeContent = @'
# BBK Desktop App - Hardware Bridge Edition

**Version:** 1.0.0  
**Date:** {0}

## What's Included

This package contains:
- Electron Desktop Application (Dual-screen support)
- Python Hardware Bridge (BBK-Bridge.exe for fingerprint & door lock)
- Configuration File (config.json)

## Quick Start

1. Configure Hardware Settings

Edit config.json:
- Set fingerprint device IP (default: 192.168.1.201)
- Set door lock COM port (default: COM7)

2. Start the Application

Run START.bat to launch everything automatically

Or manually:
  a) Start Python Bridge: python-bridge\BBK-Bridge.exe
  b) Start Electron App: npm run electron

3. Access the Dashboard

The application will open two windows:
- Employee Dashboard (Primary screen)
- Member Screen (Secondary screen - Kiosk mode)

## Hardware Connections

Fingerprint Device (ZKTeco):
- Connect via Ethernet
- Default IP: 192.168.1.201, Port: 4370
- Configure in config.json

Door Lock (Arduino/Serial):
- Connect via USB (COM port)
- Default: COM7 @ 9600 baud
- Configure in config.json

## Troubleshooting

Python Bridge Not Starting:
- Check if port 8000 is already in use
- Verify config.json exists
- Check logs folder for error details

Hardware Not Detected:
- Verify device IP address (fingerprint)
- Check COM port (door lock)
- Ensure devices are powered on

Electron App Issues:
- Delete node_modules and run: npm install
- Check internet connection (for cloud dashboard)

## Folder Structure

BBK-Desktop-App-Release/
  main-hardware-bridge.js    # Main Electron process
  preload.js                  # IPC bridge
  package.json                # Dependencies
  config.json                 # Hardware configuration
  renderer/                   # Frontend scripts
  resources/                  # App icons and assets
  python-bridge/
    BBK-Bridge.exe           # Hardware communication service
  logs/                       # Application logs
  node_modules/              # Runtime dependencies

## Cloud Dashboard

- Production: https://bbkdashboard.vercel.app
- Employee: https://bbkdashboard.vercel.app/dashboard
- Member Screen: https://bbkdashboard.vercel.app/member-screen

## Support

For technical support and updates, see included documentation files.

## License

Proprietary - All Rights Reserved
'@

$readmeContent = $readmeContent -f (Get-Date -Format "yyyy-MM-dd")
Set-Content -Path "$releaseFolder\README.txt" -Value $readmeContent

# Create start script
$startScript = @"
@echo off
echo ========================================
echo BBK Desktop App - Starting...
echo ========================================
echo.

REM Check if Python bridge is running
tasklist /FI "IMAGENAME eq BBK-Bridge.exe" 2>NUL | find /I /N "BBK-Bridge.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [OK] Python Bridge already running
) else (
    echo [STARTING] Python Bridge...
    start "" "%~dp0python-bridge\BBK-Bridge.exe"
    timeout /t 3 /nobreak >nul
)

echo [STARTING] Electron App...
npm start

echo.
echo Application started!
pause
"@

Set-Content -Path "$releaseFolder\START.bat" -Value $startScript

# Create config template
$configTemplate = @"
{
  "version": "1.0.0",
  "app_name": "BBK Hardware Bridge",
  "gym_id": 1,
  
  "screens": {
    "employee": {
      "url": "https://bbkdashboard.vercel.app/",
      "display_index": 0,
      "dev_tools": false
    },
    "member": {
      "url": "https://bbkdashboard.vercel.app/member-screen",
      "display_index": 1,
      "fullscreen": true,
      "kiosk_mode": true
    }
  },
  
  "hardware": {
    "fingerprint": {
      "ip": "192.168.1.201",
      "port": 4370,
      "timeout": 5,
      "auto_reconnect": true,
      "comment": "ZKTeco fingerprint device IP and port"
    },
    "doorlock": {
      "port": "COM7",
      "baudrate": 9600,
      "open_duration": 5000,
      "comment": "Serial port for door lock (Arduino/relay)"
    }
  },
  
  "python_bridge": {
    "enabled": true,
    "port": 8000,
    "auto_start": true,
    "executable": "./python-bridge/BBK-Bridge.exe",
    "comment": "Python service for hardware communication"
  },
  
  "cloud": {
    "base_url": "https://bbkdashboard.vercel.app",
    "ws_url": "wss://bbkdashboard.vercel.app/api/hardware/ws",
    "timeout": 10000,
    "comment": "Cloud dashboard integration"
  }
}
"@

Set-Content -Path "$releaseFolder\config-template.json" -Value $configTemplate

Write-Host "   ✓ Documentation created" -ForegroundColor Green

# Create .zip file
Write-Host "📦 Creating .zip archive..." -ForegroundColor Green
Compress-Archive -Path "$releaseFolder\*" -DestinationPath $zipFileName -Force
Write-Host "   ✓ $zipFileName created" -ForegroundColor Green

# Calculate sizes
$releaseSize = (Get-ChildItem -Path $releaseFolder -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
$zipSize = (Get-Item $zipFileName).Length / 1MB

Write-Host ""
Write-Host "✅ Release package created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Package Information:" -ForegroundColor Cyan
Write-Host "   - Release folder: $releaseFolder ($([math]::Round($releaseSize, 2)) MB)" -ForegroundColor White
Write-Host "   - ZIP file: $zipFileName ($([math]::Round($zipSize, 2)) MB)" -ForegroundColor White
Write-Host ""
Write-Host "📦 Package Contents:" -ForegroundColor Cyan
Get-ChildItem -Path $releaseFolder -Recurse -Directory | ForEach-Object {
    $itemCount = (Get-ChildItem -Path $_.FullName -File).Count
    if ($itemCount -gt 0) {
        Write-Host "   - $($_.Name): $itemCount files" -ForegroundColor White
    }
}
Write-Host ""
Write-Host "🚀 Ready to deploy: $zipFileName" -ForegroundColor Green
Write-Host ""
Write-Host "To test the release:" -ForegroundColor Yellow
Write-Host "   1. Extract $zipFileName to a new folder" -ForegroundColor White
Write-Host "   2. Configure config.json with your hardware settings" -ForegroundColor White
Write-Host "   3. Run START.bat" -ForegroundColor White
Write-Host ""
