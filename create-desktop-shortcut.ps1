# BBK Hardware Bridge - Desktop Shortcut Creator
# Run this once to create a desktop shortcut

$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "BBK Hardware Bridge.lnk"
$targetPath = Join-Path $PSScriptRoot "start.bat"
$iconPath = Join-Path $PSScriptRoot "resources\icon.ico"

# Create shortcut
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $targetPath
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.Description = "BBK Gym Hardware Bridge - One-click launcher"

# Set icon if available
if (Test-Path $iconPath) {
    $shortcut.IconLocation = $iconPath
}

$shortcut.Save()

Write-Host "✓ Desktop shortcut created successfully!" -ForegroundColor Green
Write-Host "  Location: $shortcutPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now launch the app from your desktop!" -ForegroundColor Yellow

Read-Host "Press Enter to exit"
