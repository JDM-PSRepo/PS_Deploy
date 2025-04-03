#CONTROL VARIABLES
$BREAKOUT = -1

#Variables
$inputVariable = -999

try{
    #Swap to the PS_Deploy Folder directly
    cd PS_Deploy:\
    Write-Host "Mount Complete! Activating PS_Deploy!" -ForegroundColor Green
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

#Begin the loop
while($inputVariable -ne $BREAKOUT){
    
    #Begin The Super Deployer
    Write-Host "Please choose a number from the following:" -ForegroundColor DarkYellow

    #Put any new deployments here
    #Write-Host "[What it is]" -ForegroundColor Yellow
    Write-Host "1) I want to deploy Automatic Login to this PC" -ForegroundColor Yellow
    Write-Host "2) I want to deploy Ultra VNC to this PC" -ForegroundColor Yellow
    Write-Host "3) I want to deploy Windows Patches to this PC" -ForegroundColor Yellow
    Write-Host "4) I want to deploy the CVE-2013-3900 WinVerifyTrust Fix" -ForegroundColor Yellow
    Write-Host "5) I want to remove the CVE-2013-3900 WinVerifyTrust Fix" -ForegroundColor Yellow
    Write-Host "To close this deployer, type -1 as a response:" -ForegroundColor DarkYellow
    $inputVariable = Read-Host

    #Check against list of usable scripts
    Switch ($inputVariable){

        #Add any new scripts here
        -1 {Write-Host "Exiting. . ." -ForegroundColor Green} #Exit Clause
        'Negative One' { Write-Host "Oh HA HA HA yeah so funny so clever arent you. Watch this, pull my enter key"; pause; exit} #End user isnt funny
        0 {Write-Host "WARNING: You're deploying a temporary script thats been manually linked for staging purposes!" -ForegroundColor DarkRed; PS_DEPLOY:\Scripts\DeployAutoLoginV2_1.ps1;break} #Run Temp Stager
        1 {Write-Host "Deploying Autologin. . ." -ForegroundColor Green; PS_DEPLOY:\Scripts\DeployAutoLoginV2.ps1; break} #Run Autologin Deployer
        2 {Write-Host "Deploying uVNC. . ." -ForegroundColor Green; PS_DEPLOY:\Scripts\DeployUVNC.ps1; break} #Run uVNC Deployer
        3 {Write-Host "Running Windows Patcher. . ." -ForegroundColor Green; PS_DEPLOY:\Scripts\DeployWinPatch.ps1; break} #Run Windows Patcher
        4 {Write-Host "Running WinVerifyTrust Patcher. . ." -ForegroundColor Green; PS_DEPLOY:\Scripts\DeployWinVerifyTrust.ps1; break} #Run WinVerifyTrust Patcher
        5 {Write-Host "Running RemoveWinVerifyTrust Patcher. . ." -ForegroundColor Green; PS_DEPLOY:\Scripts\RemoveWinVerifyTrust.ps1; break} #Run WinVerifyTrust Patcher
        default {Write-Host "You have selected an option that does not match, Please use -1 to escape this script"; break} #Get Angy at user
    } #End Switch

} #Close Loop

#Leave the drive so it can be delinked
cd C:\

#Kill the Drive
remove-psdrive "PS_Deploy" -Force

#Lock it down
set-executionpolicy Restricted -force | Out-Null

#Be Polite
Write-Host "Goodbye!" -ForegroundColor Yellow
pause
