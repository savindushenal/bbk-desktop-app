# Update Python Bridge Only
# This script only updates the BBK-Bridge.exe without creating full package

Write-Host "=== BBK Python Bridge Update ===" -ForegroundColor Cyan
Write-Host ""

# Stop any running processes
Write-Host "Stopping BBK processes..." -ForegroundColor Yellow
Stop-Process -Name "BBK-Bridge" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "electron" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Copy updated bridge to release folder
Write-Host "Copying updated bridge..." -ForegroundColor Green
$sourceBridge = "BBK-Desktop-App-Release\python-bridge\BBK-Bridge.exe"
$tempDestination = "BBK-Desktop-App-Release\python-bridge\BBK-Bridge.exe.new"

if (Test-Path $sourceBridge) {
    Copy-Item $sourceBridge -Destination $tempDestination -Force
    Write-Host "✅ Bridge updated successfully" -ForegroundColor Green
    
    # Show file size
    $size = (Get-Item $tempDestination).Length / 1MB
    Write-Host "   Size: $([math]::Round($size, 2)) MB" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "To complete update:" -ForegroundColor Cyan
    Write-Host "1. Navigate to your installation folder"
    Write-Host "2. Stop BBK Desktop App if running"
    Write-Host "3. Replace python-bridge\BBK-Bridge.exe with the new file"
    Write-Host "4. Restart the app"
} else {
    Write-Host "❌ Bridge executable not found: $sourceBridge" -ForegroundColor Red
    Write-Host "   Build it first with: python -m PyInstaller ..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
