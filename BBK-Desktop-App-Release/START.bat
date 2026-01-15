@echo off
echo Starting BBK Desktop App...
start "" "%~dp0python-bridge\BBK-Bridge.exe"
timeout /t 3 /nobreak >nul
npm start

