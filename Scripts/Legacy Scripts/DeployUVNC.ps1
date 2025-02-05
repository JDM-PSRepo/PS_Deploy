#DeployUVNC.ps1 v1.2 | James Mester | Quit reading my comments, and GET OFF MY LAWN!
#Deploys UVNC Server 1.4.2.0 to a Client PC over RCT's Powershell Instance

#Changes
#v1.0 Original
#v1.1 Updated to use the new Master Deployer PS_Deploy
#v1.2 Updated to now pull from DeployFiles, as apart of a centralization of the repository for PS_Deploy files as well as removing all Echo commands and updating them to the proper Write-Host equivalents

#TODO
#Add logging and Try/Catch statements to build this program out and be more robust and resillient to errors. Not that it needs it, simply just bugging me -JM

$Error.Clear() #Shouldnt be needed, but this clears the local shell's stored errors in case somebody was mucking around before they run the script

Write-Host "Script Successfully Launched, Pulling down VNC Payload" -ForegroundColor Yellow

#Pull Data from the Drive to local files, this just makes the process easier/safer
Copy-item -Path PS_Deploy:\DeployFiles\UVNC\ -Destination C:\UVNC_Staging\ -recurse

Write-Host "Payload Get, Launching Silent Install" -ForegroundColor Yellow

#Run Installer.
#SilentDeploy.inf is set to load pre-set config options (Only Installs VNC Server and Registers the service)
#/VerySilent supresses any and all text boxes
#/NoRestart is needed otherwise the script will IMMEDEATLY restart the computer here
Start-Process "C:\UVNC_Staging\UVNC_1420_Setup.exe" -Args "/loadinf=C:\UVNC_Staging\SilentDeploy.inf /VerySilent /NoRestart" -Wait -NoNewWindow

#Copy the INI file to establish the proper settings, this contains the new MSLogin settings and other things
Copy-item -Path "C:\UVNC_Staging\ultravnc.ini" -Destination "C:\Program Files\uvnc bvba\UltraVNC"

#Modifying Registry, oh boy. Hold onto your shorts.
Write-Host "Install Done, Modifying Registry to Accept MS Login Users" -ForegroundColor Yellow

#Create directory paths if they do not exist, until uVNC is connected to at least once these arent made. Prior installations will already have these so Errors are suppressed.
New-Item -Path HKLM:\SOFTWARE -name ORL -ErrorAction SilentlyContinue
New-Item -Path HKLM:\SOFTWARE\ORL -name WinVNC3 -ErrorAction SilentlyContinue
New-ItemProperty -Path HKLM:\SOFTWARE\ORL\WinVNC3 -Name "ACL" -Value ([byte[]](0x02,0x00,0x2c,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x24,0x00,0x03,0x00,0x00,0x00,0x01,0x05,0x00,0x00,0x00,0x00,0x00,0x05,0x15,0x00,0x00,0x00,0x4c,0x00,0xbc,0x52,0x0b,0x53,0x79,0xf0,0x44,0x15,0xd1,0xf3,0x15,0x70,0x12,0x00)) -ErrorAction SilentlyContinue

#If the above paths already exist (from a prior installation) then this below modifies the registry properly to the value we need. Redundant to above.
Set-ItemProperty -Path HKLM:\SOFTWARE\ORL\WinVNC3 -Name "ACL" -Value ([byte[]](0x02,0x00,0x2c,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x24,0x00,0x03,0x00,0x00,0x00,0x01,0x05,0x00,0x00,0x00,0x00,0x00,0x05,0x15,0x00,0x00,0x00,0x4c,0x00,0xbc,0x52,0x0b,0x53,0x79,0xf0,0x44,0x15,0xd1,0xf3,0x15,0x70,0x12,0x00))

Write-Host "Deployment Complete, Cleaning up" -ForegroundColor DarkGreen

#Delete Staging Folder
Remove-item C:\UVNC_Staging\ -recurse

#Goodbye
Write-Host "Cleanup is Done." -ForegroundColor DarkGreen
Write-Host "You can now connect using Admin Credentials at the the following Address:" -ForegroundColor Yellow
Test-Connection -ComputerName $env:COMPUTERNAME -Count 1  | Select IPV4Address
Write-Host ""
Write-Host "Be sure to schedule the computer for a restart, Cheers" -ForegroundColor Yellow

Write-Host "Exiting uVNC Deployer. . ." -ForegroundColor Green
Pause
