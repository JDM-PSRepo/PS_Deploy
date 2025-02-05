#PS_DEPLOY_V2 | The Big mama, the one that incorperates the Backend Rewrite of PS_DEPLOY's entire system
#If something breaks, contact James Mester Immedeatly!!!!! Did he get fired? Heh. Powershell isnt hard to learn. I like it more than C# personally (and I'm rather fond of C#)

#Launch initial setup
try{
    cd PS_Deploy:\ #Swap to the PS_Deploy Folder directly
    . .\Scripts\PS_Function.ps1 #Dot Include the PS_Function System
    Write-Host "Mount Complete! Activating PS_Deploy!" -ForegroundColor Green
    Write-Host "Warning: Do not close this shell until you properly exit the script, otherwise you may leave the Powershell on this device as unrestricted and vunderable to attacks!" -ForegroundColor DarkRed
}

#If that fails, scream from the rooftops and nope out
catch{
    Write-Host "Something went horribly wrong! Was unable to bind the PS_Deploy Folder on the network! This is pretty bad news. Did the file get renamed?!" -ForegroundColor DarkRed
    Write-Host "Terminating Shell, cannot proceed!" -ForegroundColor DarkRed
    pause #Hold temporarily before killing the shell
    #Disconnect the Drive
    cd C:\
    remove-psdrive "PS_Deploy" -Force
    #Kill the instance
    exit
}

#This is where the fun begins

#Global Log
$Global:GLOBAL_LOGPATH = Log-Name

#List of options the deployer will support
$options = @("I want to deploy GEN_GRATimeclock Bypassed Autologin to this PC [Untested - RUN AT YOUR OWN RISK!!!!]",
             "I want to deploy PFFloor Autologin to this PC [Untested - RUN AT YOUR OWN RISK!!!!]",
             "I want to deploy Ultra VNC to this PC",
             "I want to deploy Windows Patches to this PC [Untested - RUN AT YOUR OWN RISK!!!!]",
             "I want to deploy the CVE-2013-3900 WinVerifyTrust Fix [Untested - RUN AT YOUR OWN RISK!!!!]",
             "I want to remove the CVE-2013-3900 WinVerifyTrust Fix [Incomplete - RUN AT YOUR OWN RISK!!!!]")
$beforeText = "Please choose a number from the following:" #Said before options
$afterText = "To close this deployer, type -1 as a response" #Said after options
$inputVariable = -9999 #Garbage data to prevent weirdness             

#Capture everything in a while loop so multiple operations can be completed together
while($inputVariable -ne -1){
    
    #Dump options, ask for an input
    $inputVariable = Output-DisplayOptions -displayPrompt $beforeText -optionsArray $options -specialMessage $afterText

    #Check against list of usable scripts
    Switch ($inputVariable){
        #Add any new scripts here
       -1 {Write-Host "Exiting. . ." -ForegroundColor Green} #Exit Clause
        1 {Write-Host "Deploying a Bypassed Autologin for PFFloor. . ." -ForegroundColor Green;Add-AutologBypass -autoUser "GEN_GRATimeclock" -autoPass "Lear2021"; break} #Run Autologin Deployer
        2 {Write-Host "Deploying an Unbypassed Autologin for PFFloor. . ." -ForegroundColor Green;Add-Autolog -autoUser "PFFloor" -autoPass "Michigan21"; break} #Run Autologin Deployer
        3 {Write-Host "Deploying uVNC. . ." -ForegroundColor Green; PS_DEPLOY:\Scripts\DeployUVNCV2.ps1; break} #Run uVNC Deployer
        4 {Write-Host "Running Windows Patcher. . ." -ForegroundColor Green; PS_DEPLOY:\Scripts\DeployWinPatchV2.ps1; break} #Run Windows Patcher
        5 {Write-Host "Running WinVerifyTrust Patcher. . ." -ForegroundColor Green; PS_DEPLOY:\Scripts\DeployWinVerifyTrustV2.ps1; break} #Run WinVerifyTrust Patcher
        6 {Write-Host "Running RemoveWinVerifyTrust Patcher. . ." -ForegroundColor Green; PS_DEPLOY:\Scripts\RemoveWinVerifyTrustV2.ps1; break} #Run WinVerifyTrust Patcher
        default { #Shouldnt be possible, but have it just to be safe
            Log-Alert -message "Error occured, input variable was $inputVariable and struck the Default Case in PS_DEPLOY. This shouldnt be possible in V2, this means Output-DisplayOptions was fed an incorrect array size!?" -severity 3
            break
            } 
    } #End Switch
}

#Leave the drive so it can be delinked
cd C:\

#Kill the Drive
remove-psdrive "PS_Deploy" -Force

#Lock it down
set-executionpolicy Restricted -force | Out-Null

#Be Polite
Write-Host "Execution Policy has been locked back down, it is now safe to close this shell!" -ForegroundColor Yellow
pause
