@echo off
cls
cd \
cd "C:\Program Files (x86)\Microsoft\Edge\Application\"
echo "Launching LPS Dashboard! Please wait this takes a bit of work!"
echo "Beginning LoginGUI Waitout. . ."
timeout /t 10
echo "Pre-emptively Killing any MS Edge Popups!"
msedge.exe
taskkill /f /im msedge.exe
echo "Launch!"
msedge.exe --kiosk http://10.97.164.61/LPS.Dashboard.MVC.WebApplication/Home/Dashboard?View=OEE_OP100A&ID=d5019446-b738-43cf-961c-fab72b3abd3b
 --edge-kiosk-type=fullscreen --no-first-run 