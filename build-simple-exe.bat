@echo off
title BBK Hardware Bridge - Quick EXE Builder
color 0A

:: Change to script directory
cd /d "%~dp0"

echo.
echo ========================================
echo   BBK Hardware Bridge
echo   Quick Standalone EXE Builder
echo ========================================
echo.

:: Install build tools
echo [1/3] Installing build tools...
pip install pyinstaller >nul 2>nul

:: Build Python bridge
echo [2/3] Building Python service...
cd python-bridge
pyinstaller --onefile --noconsole ^
    --name "BBK-Bridge-Service" ^
    --icon=..\resources\icon.ico ^
    --hidden-import=fastapi ^
    --hidden-import=uvicorn ^
    --hidden-import=pyzk ^
    --hidden-import=serial ^
    --copy-metadata=fastapi ^
    --copy-metadata=uvicorn ^
    --copy-metadata=pydantic ^
    --copy-metadata=starlette ^
    main.py
if %errorlevel% neq 0 (
    echo [ERROR] Python build failed
    cd ..
    pause
    exit /b 1
)
cd ..

:: Create portable folder
echo [3/3] Creating portable package...
if not exist "portable" mkdir portable
if exist "portable\BBK-Hardware-Bridge" rmdir /s /q "portable\BBK-Hardware-Bridge"
mkdir "portable\BBK-Hardware-Bridge"

:: Copy files
copy "python-bridge\dist\BBK-Bridge-Service.exe" "portable\BBK-Hardware-Bridge\" >nul
copy "config.json" "portable\BBK-Hardware-Bridge\" >nul
copy "START_HERE.txt" "portable\BBK-Hardware-Bridge\" >nul
mkdir "portable\BBK-Hardware-Bridge\logs" 2>nul

:: Create launcher
(
echo @echo off
echo cd /d "%%~dp0"
echo start /min "" "BBK-Bridge-Service.exe"
echo timeout /t 5 /nobreak ^>nul
echo start "" https://bbkdashboard.vercel.app
echo echo.
echo echo BBK Hardware Bridge is running!
echo echo Python Bridge: http://localhost:8000
echo echo Dashboard: https://bbkdashboard.vercel.app
echo echo.
echo echo Close this window to stop the service.
echo echo.
echo pause
echo taskkill /F /IM BBK-Bridge-Service.exe ^>nul 2^>nul
) > "portable\BBK-Hardware-Bridge\Start BBK Bridge.bat"

:: Create README
(
echo BBK HARDWARE BRIDGE - PORTABLE
echo ===============================
echo.
echo QUICK START:
echo 1. Edit config.json with your device IP/COM port
echo 2. Double-click "Start BBK Bridge.bat"
echo 3. Browser opens automatically to dashboard
echo.
echo NO INSTALLATION NEEDED!
echo.
) > "portable\BBK-Hardware-Bridge\README.txt"

echo.
echo ========================================
echo   SUCCESS!
echo ========================================
echo.
echo Package created: portable\BBK-Hardware-Bridge\
echo.
echo To use:
echo 1. Copy the BBK-Hardware-Bridge folder to any PC
echo 2. Edit config.json
echo 3. Run "Start BBK Bridge.bat"
echo.

explorer portable
pause
