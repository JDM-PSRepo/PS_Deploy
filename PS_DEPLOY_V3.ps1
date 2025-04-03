#PS_DEPLOY_V3.1 | Rebuilt for drop in place use
#If something breaks, contact James Mester Immedeatly!!!!! Did he get fired? Heh. Powershell isnt hard to learn. I like it more than C# personally (and I'm rather fond of C#)

#This has to be first! This defines the script's functions and switches
param(
	#Mandatory Options
	[Parameter(Mandatory=$true)]
	[Int32]$Option,
	
	#Gui switch, functions as a Boolean
	[switch]$showGui
)

#Previously this was intended to be run as a network drive, this is no longer needed
#New-PSDrive -Name "PS_Deploy" -PSProvider "FileSystem" -Root "\\HVAC-DATA\IT\STAGING"

#Launch initial setup
try{
    #Jump into the drive to confirm it works
    cd PS_Deploy:\ #Swap to the PS_Deploy Folder directly

    #Dot inclusion is critical, you cant run anything until then
    . .\Library\PS_Function.ps1 #Dot Include the PS_Function System
    
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

#TODO: Generate a list of options if a particular switch case has been passed in. E.G. a boolean that says "Display options" with a default of false
if($showGUI){
	#TODO: Actually implement This
	Log-Alert -message "Successfully triggered the ShowGui Function, however it is not implemented yet!"
	
	
}

#Check against list of usable scripts
Switch ($Option){
    #Add any new scripts here
    0 {Log-Alert -message "Default value passed to Switch Case in Deployer V3! Remember to add arguments to this script damnit!!!";break}
    1 {.\Library\DeployUVNCV2.ps1; break} #Run uVNC Deployer
    2 {Enable-PSRemoting; break} #Deploys WinRM
    default { #Wrong argument was passed
        Log-Alert -message "Error occured, input variable was $Option and struck the Default Case in PS_DEPLOY. Using DeployerV3 that means an incorrect option variable was passed!" -severity 3
        break
        } 
} #End Switch


#Legacy nonsense
#cd C:\

#Legacy remover
#remove-psdrive "PS_Deploy" -Force