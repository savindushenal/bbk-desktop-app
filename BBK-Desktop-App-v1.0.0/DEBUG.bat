@echo off
cd /d "%~dp0"
color 0B
echo.
echo ============================================
echo   BBK Desktop App - Debug Information
echo ============================================
echo.

echo [1] Current Directory:
echo %CD%
echo.

echo [2] Files in this directory:
dir /b
echo.

echo [3] Node.js Check:
where node
node -v 2>nul
echo.

echo [4] npm Check:
where npm
npm -v 2>nul
echo.

echo [5] Python Bridge Check:
if exist "python-bridge\BBK-Bridge.exe" (
    echo FOUND: python-bridge\BBK-Bridge.exe
) else (
    echo NOT FOUND: python-bridge\BBK-Bridge.exe
)
echo.

echo [6] node_modules Check:
if exist "node_modules" (
    echo FOUND: node_modules
) else (
    echo NOT FOUND: node_modules
)
echo.

echo [7] package.json Check:
if exist "package.json" (
    echo FOUND: package.json
    type package.json | findstr "name"
) else (
    echo NOT FOUND: package.json
)
echo.

echo ============================================
echo   Debug Complete
echo ============================================
echo.
echo Copy the output above and check for issues.
echo.
pause
