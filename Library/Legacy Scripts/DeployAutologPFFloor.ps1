#DeplloyAutologPFFLoor.ps1
#Established Registry Based Autologin to a Client PC over RCT's Powershell Instance, this script can also be run locally too with the Copy Paste Deployer, modified to work with the super deployer

#User Defined Variables. Dont mess with these unless you want to change something
$regName = "AutoAdminLogon", "DefaultUserName", "DefaultPassword", "DefaultDomainName" #Values in the registry to modify
$regValue = "1", "PFFloor", "Michigan21", "CORPLEAR" #Values to put in registry
$clearPass = "SR71Blackb!rd" #I'm not a fan of clear text passwords, but nobody should have access to this file and it only controls admin rights to signage PC's with no user access nor network power so, im gonna do it. Sorry mom. The right way is a pain in the butt
$definedName = "PS_RUNNER" #Change this if you want to modify the name of the User
$taskAction = New-ScheduledTaskAction -Execute 'C:\PS_RUN\SoloWingRegistry.bat' #Sets location and file to run

#Generated Variables, dont mess with this unless you know what they do
$securePass = $clearPass | ConvertTo-SecureString -AsPlainText -Force #This is my way of saying this is bad and i have to override windows's safeguards, but outputting secure strings to files requires byte keys and i dont wanna.
$hostDevice = Hostname #Grabs Machine Name
$runnerUser = "$hostDevice\$definedName" #Dont modify this, its automatically generated from prior variables
$Strider1 = New-ScheduledTaskTrigger -AtStartup #If you get the joke, congrats on owning Ace Combat 7, sets task trigger to startup

#Runtime variables, dont mess with these either
$userSuccess = $false
$taskSuccess = $false
$regSuccess = $false, $false, $false, $false

$Error.Clear() #Shouldnt be needed, but this clears the local shell's stored errors in case somebody was mucking around before they run the script

#Script Success, Network Share was properly mounted and launched from Copy Paste Deployer
Log-Alert -message "Script successfully launched, editing Registry to automatically login on start" -severity 1

#Check to make sure that the PS_RUN folder exists, if not make it
if(-NOT (Test-Path C:\PS_RUN)){New-item -ItemType Directory -Path "C:\" -Name "PS_RUN" | Out-Null; Log-Alert -message "PS_RUN Created as it did not exist" -severity 1}
else{Log-Alert -message "PS_RUN already exists, Skipping File Creation" -severity 1}

#Speak to User
Log-Alert -message "Deploying V2's Batch Payload" -severity 1

#Attempt to move the Batch File for the Registry Nuke into the PS_RUN folder. If this fails, alert the user.
try{
    #Copy the Nuker Bat to local files
    Copy-Item PS_DEPLOY:\DeployFiles\LegalBypass\SoloWingRegistry.bat -Destination C:\PS_RUN -Force -ErrorAction Stop | Out-Null
    Log-Alert -message "Registry Batch Staged in PS_RUN" -severity -2
}

#Something borked, complain
catch{
    Log-Alert -message "Fatal Error: SoloWingRegistry.bat couldnt be relocated to the PS_RUN file?. Did the file get deleted?" -severity 4
}

#Attempt to add the user, update the variable based on success or failure
$userSuccess = User-AddAdmin -definedName $definedName -securePass $securePass -descUser "Runs PS_RUN Files"

#The task is tied to the user account, so if that fails then the task will fail.
if($userSuccess){
    $taskSuccess = Modify-Task -taskUser $runnerUser -clearPass $clearPass -taskAction $taskAction -taskTrigger $Strider1 -taskName "PS_Deploy_LegalBypasser" -taskDesc "Sidesteps the Legal Notice on startup by nuking the registry element on startup"
}

#Add the Autologin for GEN_GRATimeclock, at the very minimum if the legal bypass fails we can still always just add this
#Test the arrays to ensure they're the same length
if($regName.Length -eq $regValue.Length){

    #If the array check comes back clean iterate through them
    for($i = 0; $i -le ($regName.Length - 1); $i += 1){

        #Load the next item from the array
        $displayName = $regName[$i]
        $displayValue = $regValue[$i]

        #Speak to user
        Log-Alert -message "Attempting to add $displayName to the Registry" -severity 1
       
        #Load next registry value, log the results
        $regSuccess[$i] = Modify-RegValue -regPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -regName $displayName -regValue $displayValue -regProperty String

        #Test for success, if it fails scream an error
        if($regSuccess[$i]){Log-Alert -message "Successfully added $regName[$i] to the Registry with a value of $displayValue" -severity -2}
        else{Log-Alert -message "Add of $displayName failed. This issue has been logged and continue." -severity 4}
    }
}

#If we strike this case we have a problem
else{
    Log-Alert -message "Fatal Error: regName and regValue arrays are not the same length! This could mean that there was a mishap in the configuration and could have lead to an out of bounds error!" -severity 5
}
