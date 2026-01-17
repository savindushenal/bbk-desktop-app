$ErrorActionPreference = "Stop"

Write-Host "`n=== BBK Desktop App - Standalone Executable Builder ===" -ForegroundColor Cyan

$releaseFolder = "BBK-Standalone-Release"
$zipFileName = "BBK-Desktop-App-Standalone-v1.0.0.zip"

# Clean up
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
if (Test-Path $releaseFolder) { Remove-Item -Path $releaseFolder -Recurse -Force }
if (Test-Path $zipFileName) { Remove-Item -Path $zipFileName -Force }

# Build Electron app
Write-Host "Building Electron executable (this may take a few minutes)..." -ForegroundColor Green

if (-not (Test-Path "node_modules\electron")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
}

npm run build

if (-not (Test-Path "dist")) {
    Write-Host "ERROR: Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Electron app built successfully!" -ForegroundColor Green

# Create release folder
Write-Host "`nCreating release package..." -ForegroundColor Green
New-Item -ItemType Directory -Path $releaseFolder | Out-Null

# Copy built app
Write-Host "Copying Electron executable..."
$distFolder = Get-ChildItem -Path "dist" -Directory | Where-Object { $_.Name -like "*win-unpacked*" } | Select-Object -First 1
if ($distFolder) {
    Copy-Item -Path "$($distFolder.FullName)\*" -Destination $releaseFolder -Recurse
    Write-Host "  Electron app copied from $($distFolder.Name)"
} else {
    Write-Host "ERROR: No unpacked dist folder found!" -ForegroundColor Red
    Write-Host "Available folders:" -ForegroundColor Yellow
    Get-ChildItem -Path "dist" -Directory | ForEach-Object { Write-Host "  - $($_.Name)" }
    exit 1
}

# Copy Python bridge
Write-Host "Copying Python bridge..."
New-Item -ItemType Directory -Path "$releaseFolder\python-bridge" -Force | Out-Null
if (Test-Path "exe-output\BBK-Bridge.exe") {
    Copy-Item "exe-output\BBK-Bridge.exe" -Destination "$releaseFolder\python-bridge\"
    Write-Host "  BBK-Bridge.exe copied"
} else {
    Write-Host "  WARNING: BBK-Bridge.exe not found!" -ForegroundColor Yellow
}

# Copy config and create logs folder
Copy-Item "config.json" -Destination $releaseFolder
New-Item -ItemType Directory -Path "$releaseFolder\logs" -Force | Out-Null

# Create START.bat
$startBat = "@echo off`r`n"
$startBat += "title BBK Desktop App`r`n"
$startBat += "echo Starting BBK Desktop App...`r`n"
$startBat += "echo.`r`n`r`n"
$startBat += "REM Start Python Bridge`r`n"
$startBat += "tasklist /FI `"IMAGENAME eq BBK-Bridge.exe`" 2>NUL | find /I /N `"BBK-Bridge.exe`">NUL`r`n"
$startBat += "if `"%ERRORLEVEL%`"==`"0`" (`r`n"
$startBat += "    echo Python Bridge already running`r`n"
$startBat += ") else (`r`n"
$startBat += "    echo Starting Python Bridge...`r`n"
$startBat += "    start `"`" `"%~dp0python-bridge\BBK-Bridge.exe`"`r`n"
$startBat += "    timeout /t 3 /nobreak >nul`r`n"
$startBat += ")`r`n`r`n"
$startBat += "REM Start Electron App`r`n"
$startBat += "echo Starting Desktop App...`r`n"
$startBat += "if exist `"%~dp0BBK Hardware Bridge.exe`" (`r`n"
$startBat += "    start `"`" `"%~dp0BBK Hardware Bridge.exe`"`r`n"
$startBat += ") else (`r`n"
$startBat += "    echo ERROR: Executable not found!`r`n"
$startBat += "    pause`r`n"
$startBat += ")`r`n"

Set-Content -Path "$releaseFolder\START.bat" -Value $startBat

# Create README
$readme = "BBK DESKTOP APP - STANDALONE EDITION`n`n"
$readme += "Version: 1.0.0`n"
$readme += "Date: " + (Get-Date -Format "yyyy-MM-dd") + "`n`n"
$readme += "QUICK START:`n"
$readme += "1. Extract to C:\BBK-Desktop-App\`n"
$readme += "2. Edit config.json (fingerprint IP and COM port)`n"
$readme += "3. Run START.bat`n`n"
$readme += "NO NODE.JS REQUIRED!`n"
Set-Content -Path "$releaseFolder\README.txt" -Value $readme

# Copy docs
if (Test-Path "DEPLOYMENT_GUIDE.md") { Copy-Item "DEPLOYMENT_GUIDE.md" -Destination $releaseFolder }
if (Test-Path "QUICK_REFERENCE.txt") { Copy-Item "QUICK_REFERENCE.txt" -Destination $releaseFolder }

# Create ZIP
Write-Host "`nCreating ZIP archive..." -ForegroundColor Green
Compress-Archive -Path "$releaseFolder\*" -DestinationPath $zipFileName -Force

$zipSize = (Get-Item $zipFileName).Length / 1MB
Write-Host "`n=== BUILD COMPLETE ===" -ForegroundColor Green
Write-Host "File: $zipFileName" -ForegroundColor Cyan
Write-Host "Size: $([math]::Round($zipSize, 2)) MB" -ForegroundColor Cyan
Write-Host "`nContents:" -ForegroundColor Yellow
Get-ChildItem -Path $releaseFolder -File | Select-Object -First 5 | ForEach-Object { Write-Host "  $($_.Name)" }
Write-Host "`nReady to deploy!" -ForegroundColor Green
