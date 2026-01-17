param([string]$OutputName = "BBK-Desktop-App-Cloudflare-v1.0.0.zip")
Write-Host "Creating deployment package..." -ForegroundColor Cyan
Stop-Process -Name "electron" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "BBK-Bridge" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$excludePatterns = @('logs', 'node_modules', '.git', '*.log', '*.tmp', 'TUNNEL_URL.txt', 'NGROK_SETUP_OLD.md')
$files = Get-ChildItem -Path "BBK-Desktop-App-Release" -Recurse -File | Where-Object {
    $file = $_; $shouldInclude = $true
    foreach ($pattern in $excludePatterns) {
        if ($file.FullName -like "*\$pattern\*" -or $file.Name -like $pattern) { $shouldInclude = $false; break }
    }
    $shouldInclude
}
Write-Host "Found $($files.Count) files"
$tempDir = "BBK-Temp"; if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
foreach ($file in $files) {
    $relativePath = $file.FullName.Replace((Get-Location).Path + "\BBK-Desktop-App-Release\", "")
    $destPath = Join-Path $tempDir $relativePath; $destDir = Split-Path $destPath -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Copy-Item $file.FullName -Destination $destPath -Force
}
Write-Host "Compressing..."
if (Test-Path $OutputName) { Remove-Item $OutputName -Force }
Compress-Archive -Path $tempDir -DestinationPath $OutputName -CompressionLevel Optimal
Remove-Item $tempDir -Recurse -Force
if (Test-Path $OutputName) {
    $zipInfo = Get-Item $OutputName; $sizeMB = [math]::Round($zipInfo.Length / 1MB, 2)
    Write-Host "Success! Size: $sizeMB MB" -ForegroundColor Green
    Write-Host "Location: $($zipInfo.FullName)" -ForegroundColor Cyan
} else { Write-Host "Failed" -ForegroundColor Red }
