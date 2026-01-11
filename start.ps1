# BBK Hardware Bridge - PowerShell Startup Script
# One-click launcher for the entire system

$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "BBK Hardware Bridge - Starting..."

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  BBK Hardware Bridge" -ForegroundColor Cyan
Write-Host "  Starting System..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Function to check if a command exists
function Test-Command {
    param($Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Check prerequisites
Write-Host "[CHECK] Verifying prerequisites..." -ForegroundColor Yellow

if (-not (Test-Command "node")) {
    Write-Host "[ERROR] Node.js is not installed!" -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not (Test-Command "python")) {
    Write-Host "[ERROR] Python is not installed!" -ForegroundColor Red
    Write-Host "Please install Python from https://python.org/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] Node.js and Python found" -ForegroundColor Green

# Install Node.js dependencies if needed
Write-Host ""
Write-Host "[1/3] Checking Node.js dependencies..." -ForegroundColor Yellow

if (-not (Test-Path "node_modules")) {
    Write-Host "[INFO] Installing Node.js dependencies..." -ForegroundColor Cyan
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to install Node.js dependencies" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "[OK] Node.js dependencies installed" -ForegroundColor Green
} else {
    Write-Host "[OK] Node.js dependencies already installed" -ForegroundColor Green
}

# Install Python dependencies if needed
Write-Host ""
Write-Host "[2/3] Checking Python dependencies..." -ForegroundColor Yellow

python -c "import fastapi" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[INFO] Installing Python dependencies..." -ForegroundColor Cyan
    Push-Location python-bridge
    pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Host "[ERROR] Failed to install Python dependencies" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Pop-Location
    Write-Host "[OK] Python dependencies installed" -ForegroundColor Green
} else {
    Write-Host "[OK] Python dependencies already installed" -ForegroundColor Green
}

# Start Python bridge
Write-Host ""
Write-Host "[3/3] Starting Python Bridge..." -ForegroundColor Yellow

$pythonProcess = Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd '$PSScriptRoot\python-bridge'; python main.py"
) -WindowStyle Minimized -PassThru

Write-Host "[OK] Python bridge started (PID: $($pythonProcess.Id))" -ForegroundColor Green

# Wait for Python bridge to be ready
Write-Host "[INFO] Waiting for Python bridge to initialize..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

$maxRetries = 10
$retryCount = 0
$bridgeReady = $false

while ($retryCount -lt $maxRetries -and -not $bridgeReady) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $bridgeReady = $true
            Write-Host "[OK] Python bridge is ready!" -ForegroundColor Green
        }
    } catch {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "[INFO] Waiting for bridge... (attempt $retryCount/$maxRetries)" -ForegroundColor Cyan
            Start-Sleep -Seconds 2
        }
    }
}

if (-not $bridgeReady) {
    Write-Host "[WARNING] Python bridge may not be fully ready" -ForegroundColor Yellow
    Write-Host "[INFO] Continuing anyway..." -ForegroundColor Cyan
}

# Display system info
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  System Ready!" -ForegroundColor Cyan
Write-Host "  Python Bridge: http://localhost:8000" -ForegroundColor White
Write-Host "  Electron App: Launching..." -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Start Electron app
Write-Host "[LAUNCH] Starting Electron application..." -ForegroundColor Yellow
npm start

# Cleanup when Electron closes
Write-Host ""
Write-Host "[CLEANUP] Shutting down Python bridge..." -ForegroundColor Yellow

try {
    Stop-Process -Id $pythonProcess.Id -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Python bridge stopped" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Failed to stop Python bridge gracefully" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  BBK Hardware Bridge - Stopped" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit"
