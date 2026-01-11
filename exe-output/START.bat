@echo off
title BBK Hardware Bridge
echo Starting BBK Hardware Bridge...
start /min "" BBK-Bridge.exe
timeout /t 3 >nul
start "" https://bbkdashboard.vercel.app
echo.
echo ✅ BBK Hardware Bridge is running!
echo    Python Bridge: http://localhost:8000
echo    Dashboard: https://bbkdashboard.vercel.app
echo.
echo Press any key to stop...
pause >nul
taskkill /F /IM BBK-Bridge.exe >nul 2>nul
