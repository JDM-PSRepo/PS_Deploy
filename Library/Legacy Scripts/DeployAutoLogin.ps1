#DeployAutoLogin.ps1 v1.1 | James Mester | Quit reading my comments, and GET OFF MY LAWN!
#Established Registry Based Autologin to a Client PC over RCT's Powershell Instance, this script can also be run locally too with the Copy Paste Deployer, modified to work with the super deployer

$Error.Clear() #Shouldnt be needed, but this clears the local shell's stored errors in case somebody was mucking around before they run the script

#Script Success, Network Share was properly mounted and launched from Copy Paste Deployer
echo "Script successfully launched, editing Registry to automatically login on start"

#Establish the AdminAutologon Function | If property already exists, shuts up the error. Editing shouldnt be needed
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value "1" -PropertyType String -ErrorAction SilentlyContinue
 
#Enter Username | If property already exists, shuts up the error and edits it
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName" -Value "GEN_GRATimeclock" -PropertyType String -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName" -Value "GEN_GRATimeclock" 

#Enter Password (THIS IS CLEARTEXT!!! DO NOT LET PEOPLE SEE THIS FILE IF THEY SHOULDNT) | If property already exists, shuts up the error and edits it
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -Value "Lear2021" -PropertyType String -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -Value "Lear2021" 

#Enter Domain | If property already exists, shuts up the error and edits it
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultDomainName" -Value "CORPLEAR" -PropertyType String -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultDomainName" -Value "CORPLEAR" 

#Work Complete, deleting fun from system
echo "Autologin setup complete, Removing Surf game access"

#Wiping out Surf from Edge since any autologin system shouldnt be allowed to use it, if its already set then be quiet
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "AllowSurfGame" -Value "0" -PropertyType DWORD -ErrorAction SilentlyContinue

#Goodbye
echo "All done, user will need to hit OK on startup, then the device should login automatically"

#Leave
echo "Edits are done, returning to deployer"

#Pause before leaving
Pause

