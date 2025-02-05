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
msedge.exe --kiosk http://10.97.164.61/LPS.Dashboard.MVC.WebApplication/Home/Dashboard?View=OEE_MARRIAGE&ID=425cb0b0-f669-470b-beb8-b8b7e8f050fe
 --edge-kiosk-type=fullscreen --no-first-run 