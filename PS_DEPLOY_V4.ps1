#PS_DEPLOY_V4 | Github Airstrike edition
#If something breaks, contact James Mester Immedeatly!!!!! Did he get fired? Heh. Powershell isnt hard to learn. I like it more than C# personally (and I'm rather fond of C#)

#This has to be first! This defines the script's functions and switches
param(
	#Dont make this mandatory, or else showGui is useless
    #This is the option to run, 0 is default, 1 is uVNC, 2 is WinRM, more to be added later on
	[Int32]$Option=0,
	
	#Gui switch, functions as a Boolean
	[switch]$showGui
)

#These variables are REQUIRED for the script to run properly even before Dot Sourcing the primary function library.
#Write the Temp directory to a variable
$Global:TEMP = $env:TEMP #This is the temp directory, where we will be downloading the script to


#We need this to run as administrator for the script to work properly
#This is a check to see if the script is running as admin, if not, it will exit
try{
    #Check if the script is running as admin
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-Host "Too Bad, Buddy. This script needs to be run as Administrator!``nStart back over from Zero with this Script, and entrust the future to the next Powershell Instance" -ForegroundColor Red
        exit
    }
}
catch{
    Write-Host "Admin Check just completely failed out, no good. Ejecting now!" -ForegroundColor DarkRed
    Write-Host "Terminating Shell, cannot proceed!" -ForegroundColor DarkRed
    pause #Hold temporarily before killing the shell
    exit
}

#Create a root directory for the script library. Then download the script from github down to it.
try{
    #Check if the directory exists
    if(!(Test-Path -Path $TEMP\PS_DEPLOY)){
        #If it does not exist, create it
        New-Item -Path $TEMP\PS_DEPLOY -ItemType Directory -Force
    }
}
catch{
    Write-Host "Unable to create the PS_DEPLOY directory in TEMP! This is bad news!" -ForegroundColor DarkRed
    Write-Host "Terminating Shell, cannot proceed!" -ForegroundColor DarkRed
    pause #Hold temporarily before killing the shell
    exit
}

#Pull the repository down to the local machine as a zip file and extract it
try{
    #Download the zip file
    Invoke-WebRequest -Uri "https://github.com/JDM-PSRepo/PS_Deploy/archive/refs/heads/main.zip" -OutFile $TEMP\PS_DEPLOY\PS_DEPLOY.zip
    #Extract the zip file
    Expand-Archive -Path $TEMP\PS_DEPLOY\PS_DEPLOY.zip -DestinationPath $TEMP\PS_DEPLOY -ErrorAction Stop
    #Remove the zip file, if this fails we dont care
    Remove-Item -Path $TEMP\PS_DEPLOY\PS_DEPLOY.zip -ErrorAction SilentlyContinue
}
catch{
    Write-Host "Github repo download failed! This is very very very bad! This means we dont have the files we need to continue!" -ForegroundColor DarkRed
    Write-Host "Terminating Shell, cannot proceed!" -ForegroundColor DarkRed
    pause #Hold temporarily before killing the shell
    exit
}

#Check if the PS_Deploy folder exists
#Launch initial setup
try{
    #Jump to the PSDeploy folder in TEMP so we can run the scripts
    Set-Location $TEMP\PS_DEPLOY\PS_Deploy-main\ #Swap to the PS_Deploy Folder directly

    #Dot inclusion is critical, you cant run anything until then
    Import-Module .\Library\PS_Function.ps1 #Dot Include the PS_Function System
    
    #Bind a Global Log so we can properly make use of our logging tools immedeatly
}
catch{
    Write-Host "Unable to set the PS_Deploy directory as the working directory! This is bad news!" -ForegroundColor DarkRed
    Write-Host "Terminating Shell, cannot proceed!" -ForegroundColor DarkRed
    pause #Hold temporarily before killing the shell
    exit
}

#Establish logging
try {
    #Attempt to establish the log path
    $Global:GLOBAL_LOGPATH = New-LogName
    New-LogMessage -message "Mount Complete! Activating PS_Deploy!" -severity -2
}
catch {
    Write-Host "Unable to set the log path! No bueno my friend!" -ForegroundColor DarkRed
    Write-Host "Terminating Shell, cannot proceed!" -ForegroundColor DarkRed
    pause #Hold temporarily before killing the shell
    exit
}

#TODO: Generate a list of options if a particular switch case has been passed in. E.G. a boolean that says "Display options" with a default of false
if($showGUI){
	#TODO: Actually implement This
	New-LogMessage -message "Successfully triggered the ShowGui Function, however it is not implemented yet!" -Severity -2
	
}

#Check against list of usable scripts
Switch ($Option){
    #Add any new scripts here
    0 {New-LogMessage -message "Default value passed to Switch Case in Deployer V3! Remember to add arguments to this script damnit!!!";break}
    1 {.\Library\DeployUVNCV2.ps1; break} #Run uVNC Deployer
    2 {Enable-PSRemoting; break} #Deploys WinRM
    default { #Wrong argument was passed
        New-LogMessage -message "Error occured, input variable was $Option and struck the Default Case in PS_DEPLOY. Using DeployerV3 that means an incorrect option variable was passed!" -severity 3
        break
        } 
} #End Switch


#Legacy nonsense
#cd C:\

#Legacy remover
#remove-psdrive "PS_Deploy" -Force