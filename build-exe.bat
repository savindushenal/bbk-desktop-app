@echo off
title BBK Hardware Bridge - Building EXE Package
color 0E

:: Change to script directory
cd /d "%~dp0"

echo.
echo ========================================
echo   BBK Hardware Bridge
echo   Building Standalone EXE
echo ========================================
echo.

:: Check prerequisites
echo [CHECK] Verifying build tools...

where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not found. Please install Node.js first.
    pause
    exit /b 1
)

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python not found. Please install Python first.
    pause
    exit /b 1
)

:: Check if PyInstaller is installed
python -c "import PyInstaller" >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Installing PyInstaller...
    pip install pyinstaller
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install PyInstaller
        pause
        exit /b 1
    )
)

:: Check if electron-builder is installed
if not exist "node_modules\electron-builder" (
    echo [INFO] Installing electron-builder...
    npm install --save-dev electron-builder
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install electron-builder
        pause
        exit /b 1
    )
)

echo [OK] Build tools ready
echo.

:: Create build directory
if not exist "build-exe" mkdir build-exe
if exist "build-exe\BBK-Hardware-Bridge" rmdir /s /q "build-exe\BBK-Hardware-Bridge"
mkdir "build-exe\BBK-Hardware-Bridge"

echo ========================================
echo   Step 1/4: Building Python Bridge
echo ========================================
echo.

cd python-bridge

echo [BUILD] Creating standalone Python executable...
pyinstaller --onefile --noconsole ^
    --name "BBK-Python-Bridge" ^
    --icon=..\resources\icon.ico ^
    --add-data "*.py;." ^
    --hidden-import=fastapi ^
    --hidden-import=uvicorn ^
    --hidden-import=websockets ^
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

echo [OK] Python bridge compiled to EXE
cd ..

:: Copy Python executable
copy "python-bridge\dist\BBK-Python-Bridge.exe" "build-exe\BBK-Hardware-Bridge\" >nul
echo [OK] Python bridge copied

echo.
echo ========================================
echo   Step 2/4: Building Electron App
echo ========================================
echo.

echo [BUILD] Creating Electron executable...
call npx electron-builder --win --x64 --dir

if %errorlevel% neq 0 (
    echo [ERROR] Electron build failed
    pause
    exit /b 1
)

echo [OK] Electron app compiled

:: Copy Electron build
echo [COPY] Copying Electron files...
xcopy /E /I /Y "dist\win-unpacked\*" "build-exe\BBK-Hardware-Bridge\" >nul

echo.
echo ========================================
echo   Step 3/4: Creating Support Files
echo ========================================
echo.

:: Copy configuration and docs
copy "config.json" "build-exe\BBK-Hardware-Bridge\" >nul
copy "START_HERE.txt" "build-exe\BBK-Hardware-Bridge\" >nul
copy "LICENSE.txt" "build-exe\BBK-Hardware-Bridge\" >nul

:: Create logs directory
mkdir "build-exe\BBK-Hardware-Bridge\logs" 2>nul
mkdir "build-exe\BBK-Hardware-Bridge\python-bridge" 2>nul
mkdir "build-exe\BBK-Hardware-Bridge\python-bridge\logs" 2>nul

:: Create launcher batch file
(
echo @echo off
echo title BBK Hardware Bridge
echo cd /d "%%~dp0"
echo.
echo :: Start Python Bridge in background
echo start /min "" "BBK-Python-Bridge.exe"
echo.
echo :: Wait for Python bridge to initialize
echo timeout /t 5 /nobreak ^>nul
echo.
echo :: Start Electron App
echo start "" "BBK Hardware Bridge.exe"
echo.
echo exit
) > "build-exe\BBK-Hardware-Bridge\BBK Hardware Bridge.bat"

:: Create README
(
echo BBK HARDWARE BRIDGE - STANDALONE PACKAGE
echo =========================================
echo.
echo This is a standalone executable package.
echo NO installation required - just run and go!
echo.
echo QUICK START:
echo 1. Double-click: "BBK Hardware Bridge.bat"
echo 2. Wait 5 seconds for initialization
echo 3. Application will launch automatically
echo.
echo CONFIGURATION:
echo - Edit config.json to set your device IP and COM port
echo - See START_HERE.txt for detailed instructions
echo.
echo SYSTEM REQUIREMENTS:
echo - Windows 10/11 ^(64-bit^)
echo - No Node.js or Python needed!
echo - Everything is bundled in this package
echo.
echo FOLDER CONTENTS:
echo - BBK Hardware Bridge.bat  ^^<-- DOUBLE-CLICK THIS TO START
echo - BBK-Python-Bridge.exe    ^(Hardware service^)
echo - BBK Hardware Bridge.exe  ^(Main application^)
echo - config.json              ^(Configuration file^)
echo - logs\                    ^(Application logs^)
echo.
echo FIRST TIME SETUP:
echo 1. Edit config.json with your hardware details
echo 2. Run "BBK Hardware Bridge.bat"
echo 3. Enjoy!
echo.
echo For support, see START_HERE.txt
echo.
) > "build-exe\BBK-Hardware-Bridge\README.txt"

echo [OK] Support files created

echo.
echo ========================================
echo   Step 4/4: Creating Installer
echo ========================================
echo.

:: Create simple installer using Electron Builder
echo [BUILD] Creating Windows installer...

:: Update package.json for installer
copy package.json package.json.backup >nul

:: Build installer
call npx electron-builder --win --x64

if %errorlevel% equ 0 (
    echo [OK] Installer created
    if exist "dist\BBK Hardware Bridge Setup*.exe" (
        copy "dist\BBK Hardware Bridge Setup*.exe" "build-exe\" >nul
        echo [OK] Installer copied to build-exe folder
    )
) else (
    echo [WARN] Installer creation failed, but portable version is ready
)

:: Restore package.json
move /y package.json.backup package.json >nul

echo.
echo ========================================
echo   Creating ZIP Package
echo ========================================
echo.

cd build-exe
powershell -command "Compress-Archive -Path 'BBK-Hardware-Bridge\*' -DestinationPath 'BBK-Hardware-Bridge-Portable.zip' -Force"
if %errorlevel% equ 0 (
    echo [OK] ZIP package created
) else (
    echo [WARN] ZIP creation failed
)
cd ..

echo.
echo ========================================
echo   BUILD COMPLETE!
echo ========================================
echo.
echo Output Location: build-exe\
echo.
echo Available Packages:
echo.
if exist "build-exe\BBK Hardware Bridge Setup*.exe" (
    echo [1] INSTALLER ^(Recommended for end users^)
    echo     File: BBK Hardware Bridge Setup.exe
    echo     Size: ~150-200 MB
    echo     Usage: Double-click to install, creates Start Menu shortcut
    echo.
)
echo [2] PORTABLE FOLDER ^(No installation required^)
echo     Folder: BBK-Hardware-Bridge\
echo     Size: ~150-200 MB
echo     Usage: Copy folder anywhere, run "BBK Hardware Bridge.bat"
echo.
echo [3] PORTABLE ZIP ^(Easy to share^)
echo     File: BBK-Hardware-Bridge-Portable.zip
echo     Size: ~80-100 MB ^(compressed^)
echo     Usage: Extract and run "BBK Hardware Bridge.bat"
echo.
echo ========================================
echo.
echo Deployment Options:
echo.
echo For end users:
echo   ^> Share the INSTALLER or PORTABLE ZIP
echo   ^> No Node.js or Python needed
echo   ^> Just double-click to run
echo.
echo For IT deployment:
echo   ^> Use installer for silent install: /S flag
echo   ^> Or copy portable folder to C:\Program Files\
echo.
echo ========================================
echo.

:: Ask to open folder
set /p openfolder="Open build folder? (Y/N): "
if /i "%openfolder%"=="Y" (
    explorer build-exe
)

echo.
pause
