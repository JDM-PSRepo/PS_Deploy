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
msedge.exe --kiosk http://10.97.164.61/LPS.Dashboard.MVC.WebApplication/Home/Dashboard?View=OEE_OP020B&ID=fccf0e48-0e7d-4c19-ae78-eafc53807341
 --edge-kiosk-type=fullscreen --no-first-run 