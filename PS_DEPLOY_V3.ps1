#PS_DEPLOY_V3 | Rebuilt for completely Automated GPO use
#If something breaks, contact James Mester Immedeatly!!!!! Did he get fired? Heh. Powershell isnt hard to learn. I like it more than C# personally (and I'm rather fond of C#)

#This has to be first!
param([Int32]$Option=0) 

#Bind the drive! We dont need none of that execution policy crap at Airtech!
New-PSDrive -Name "PS_Deploy" -PSProvider "FileSystem" -Root "\\HVAC-DATA\IT\STAGING"

#Launch initial setup
try{
    #Jump into the drive to confirm it works
    cd PS_Deploy:\ #Swap to the PS_Deploy Folder directly

    #Dot inclusion is critical, you cant run anything until then
    . .\Scripts\PS_Function.ps1 #Dot Include the PS_Function System
    
    #Bind a Global Log so we can properly make use of our logging tools immedeatly
    $Global:GLOBAL_LOGPATH = Log-Name
    Log-Alert -message "Mount Complete! Activating PS_Deploy!" -severity -2
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

#Check against list of usable scripts
Switch ($Option){
    #Add any new scripts here
    0 {Log-Alert -message "Default value passed to Switch Case in Deployer V3! Remember to add arguments to this script damnit!!!";break}
    1 {PS_DEPLOY:\Scripts\DeployUVNCV2.ps1; break} #Run uVNC Deployer
    2 {Enable-PSRemoting; break} #Deploys WinRM
    default { #Wrong argument was passed
        Log-Alert -message "Error occured, input variable was $Option and struck the Default Case in PS_DEPLOY. Using DeployerV3 that means an incorrect option variable was passed!" -severity 3
        break
        } 
} #End Switch


#Leave the drive so it can be delinked
cd C:\

#Kill the Drive
remove-psdrive "PS_Deploy" -Force