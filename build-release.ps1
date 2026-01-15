$ErrorActionPreference = "Stop"

Write-Host "Creating BBK Desktop App Release Package..." -ForegroundColor Cyan

$releaseFolder = "BBK-Desktop-App-Release"
$zipFileName = "BBK-Desktop-App-v1.0.0.zip"

# Clean up
if (Test-Path $releaseFolder) { Remove-Item -Path $releaseFolder -Recurse -Force }
if (Test-Path $zipFileName) { Remove-Item -Path $zipFileName -Force }

# Create release folder
New-Item -ItemType Directory -Path $releaseFolder | Out-Null

# Copy main files
Write-Host "Copying application files..." -ForegroundColor Green
Copy-Item "main-hardware-bridge.js" -Destination $releaseFolder
Copy-Item "preload.js" -Destination $releaseFolder
Copy-Item "package.json" -Destination $releaseFolder
Copy-Item "config.json" -Destination $releaseFolder

# Copy directories
Copy-Item -Path "renderer" -Destination $releaseFolder -Recurse
Copy-Item -Path "resources" -Destination $releaseFolder -Recurse

# Copy Python bridge
New-Item -ItemType Directory -Path "$releaseFolder\python-bridge" | Out-Null
if (Test-Path "exe-output\BBK-Bridge.exe") {
    Copy-Item "exe-output\BBK-Bridge.exe" -Destination "$releaseFolder\python-bridge\"
    Write-Host "BBK-Bridge.exe copied" -ForegroundColor Green
} else {
    Write-Host "WARNING: BBK-Bridge.exe not found!" -ForegroundColor Yellow
}

# Create logs folder
New-Item -ItemType Directory -Path "$releaseFolder\logs" | Out-Null

# Install production dependencies
Write-Host "Installing production dependencies..." -ForegroundColor Green
Push-Location $releaseFolder
npm install --production --silent 2>&1 | Out-Null
Pop-Location

# Create README
$readme = "BBK Desktop App - Hardware Bridge Edition`n`n"
$readme += "Version: 1.0.0`n"
$readme += "Date: " + (Get-Date -Format "yyyy-MM-dd") + "`n`n"
$readme += "QUICK START:`n"
$readme += "1. Edit config.json with your hardware settings`n"
$readme += "2. Run START.bat`n`n"
$readme += "HARDWARE CONFIGURATION:`n"
$readme += "- Fingerprint Device: Edit config.json -> hardware.fingerprint.ip`n"
$readme += "- Door Lock: Edit config.json -> hardware.doorlock.port`n`n"
$readme += "SUPPORT:`n"
$readme += "- Cloud Dashboard: https://bbkdashboard.vercel.app`n"
$readme += "- Employee Portal: https://bbkdashboard.vercel.app/dashboard`n"
$readme += "- Member Screen: https://bbkdashboard.vercel.app/member-screen`n"
Set-Content -Path "$releaseFolder\README.txt" -Value $readme

# Create START batch file
$startBat = "@echo off`r`n"
$startBat += "echo Starting BBK Desktop App...`r`n"
$startBat += "start `"`" `"%~dp0python-bridge\BBK-Bridge.exe`"`r`n"
$startBat += "timeout /t 3 /nobreak >nul`r`n"
$startBat += "npm start`r`n"
Set-Content -Path "$releaseFolder\START.bat" -Value $startBat

# Create .zip
Write-Host "Creating ZIP archive..." -ForegroundColor Green
Compress-Archive -Path "$releaseFolder\*" -DestinationPath $zipFileName -Force

$zipSize = (Get-Item $zipFileName).Length / 1MB
Write-Host "`nSUCCESS! Package created: $zipFileName" -ForegroundColor Green
Write-Host "Size: $([math]::Round($zipSize, 2)) MB" -ForegroundColor White
Write-Host "`nTo deploy:" -ForegroundColor Yellow
Write-Host "1. Extract $zipFileName" -ForegroundColor White
Write-Host "2. Configure config.json" -ForegroundColor White
Write-Host "3. Run START.bat" -ForegroundColor White
