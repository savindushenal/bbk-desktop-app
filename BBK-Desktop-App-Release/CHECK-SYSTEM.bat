@echo off
title BBK Desktop App - System Check
color 0B

REM Change to the directory where this batch file is located
cd /d "%~dp0"

echo ========================================
echo   BBK Desktop App - System Check
echo ========================================
echo.
echo Checking from: %CD%
echo.

REM Check 1: Node.js
echo [1/5] Checking Node.js...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] FAILED: Node.js is NOT installed!
    echo.
    echo    Download from: https://nodejs.org/
    echo    Install and restart computer, then run this again.
    echo.
    goto :end
) else (
    for /f "tokens=*" %%i in ('node -v') do set NODE_VERSION=%%i
    echo [OK] Node.js found: %NODE_VERSION%
)

REM Check 2: npm
echo [2/5] Checking npm...
where npm >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] FAILED: npm is NOT installed!
    goto :end
) else (
    for /f "tokens=*" %%i in ('npm -v') do set NPM_VERSION=%%i
    echo [OK] npm found: %NPM_VERSION%
)

REM Check 3: Python Bridge
echo [3/5] Checking Python Bridge...
if exist "python-bridge\BBK-Bridge.exe" (
    echo [OK] BBK-Bridge.exe found
) else (
    echo [X] FAILED: BBK-Bridge.exe NOT found!
    echo    Expected location: python-bridge\BBK-Bridge.exe
    goto :end
)

REM Check 4: Config file
echo [4/5] Checking configuration...
if exist "config.json" (
    echo [OK] config.json found
) else (
    echo [X] FAILED: config.json NOT found!
    goto :end
)

REM Check 5: Dependencies
echo [5/5] Checking dependencies...
if exist "node_modules" (
    echo [OK] node_modules folder exists
) else (
    echo [WARN] node_modules NOT found - will install on first run
)

echo.
echo ========================================
echo   All Checks Passed!
echo ========================================
echo.
echo System is ready to run START.bat
echo.

:end
echo Press any key to close...
pause >nul
