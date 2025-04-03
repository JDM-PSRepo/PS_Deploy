#DeployAutoLogin.ps1 v2.0 | James Mester | Quit reading my comments, and GET OFF MY LAWN!
#Too Bad, Buddy | This twisted game needs to be reset | We'll reset everything to Zero with this V2
#Established Registry Based Autologin to a Client PC over RCT's Powershell Instance, this script can also be run locally too with the Copy Paste Deployer, modified to work with the super deployer

#Pre-Established Variables, dont mess with this unless you know what they do
$regName = "AutoAdminLogon", "DefaultUserName", "DefaultPassword", "DefaultDomainName" #Values in the registry to modify
$regValue = "1", "GEN_GRATimeclock", "Lear2021", "CORPLEAR" #Values to put in registry
$hostDevice = Hostname #Grabs Machine Name
$definedName = "PS_RUNNER" #Change this if you want to modify the name of the User
$runnerUser = "$hostDevice\$definedName" #Dont modify this, its automatically generated from prior variables
$clearPass = "SR71Blackb!rd" #I'm not a fan of clear text passwords, but nobody should have access to this file and it only controls admin rights to signage PC's with no user access nor network power so, im gonna do it. Sorry mom. The right way is a pain in the butt
$securePass = $clearPass | ConvertTo-SecureString -AsPlainText -Force #This is my way of saying this is bad and i have to override windows's safeguards, but outputting secure strings to files requires byte keys and i dont wanna.

#Logging Data
$currentUser = WhoAmI #Grabs Username
$date = get-date -f 'MM-dd-yyyy a\t HH_MM' #Writes the name in a file friendly format
$logPath = "AutoLogInV2-$hostDevice-$date.txt" #Dynamically generates a log name on execute
$writeLog = 0 #0 Means no error occured and no log is generated


$Error.Clear() #Shouldnt be needed, but this clears the local shell's stored errors in case somebody was mucking around before they run the script

#Script Success, Network Share was properly mounted and launched from Copy Paste Deployer
Write-Host "Script successfully launched, editing Registry to automatically login on start" -ForegroundColor Yellow

#Check to make sure that the PS_RUN folder exists, if not make it
if(-NOT (Test-Path C:\PS_RUN)){New-item -ItemType Directory -Path "C:\" -Name "PS_RUN" | Out-Null; Write-Host "PS_RUN Created as it did not exist" -ForegroundColor Yellow}
else{Write-Host "PS_RUN already exists, Skipping File Creation" -ForegroundColor Yellow}

#Speak to User
Write-Host "Deploying V2's Batch Payload" -ForegroundColor Yellow

#Attempt to move the Batch File for the Registry Nuke into the PS_RUN folder. If this fails, alert the user.
try{
    #Copy the Nuker Bat to local files
    Copy-Item PS_DEPLOY:\DeployFiles\LegalBypass\SoloWingRegistry.bat -Destination C:\PS_RUN -Force -ErrorAction Stop | Out-Null
    Write-Host "Registry Batch Staged in PS_RUN" -ForegroundColor DarkGreen
}
#Something borked, complain
catch{
    #Complain
    Write-Host "Fatal Error: SoloWingRegistry.bat couldnt be relocated to the PS_RUN file?. Did the file get deleted?" -ForegroundColor DarkRed
    
    #Error Write
    "Nuker Bat Deployment Failed, Log Writer enabled" >> PS_DEPLOY:\Logs\$logPath
    $writeLog = 1 #Enable Error Dump
}

#Deploy the new local user to run this stuff
try{
    
    Write-Host "Adding User to the system" -ForegroundColor DarkGreen
    #Create a new user, force its existence, and as a backup security measure: make it so the user cannot change their own password. Kinda moot as admin but i'm trying
    New-LocalUser -AccountNeverExpires -Name $definedName -Password $securePass -Description "Runs PS_RUN Files" -UserMayNotChangePassword -PasswordNeverExpires -ErrorAction Stop| Out-Null 
    Add-LocalGroupMember -Group "Administrators" -Member $runnerUser -ErrorAction Stop | Out-Null
    Write-Host "User successfully added and escalated to admin" -ForegroundColor DarkGreen

}
catch{    
     try{
        "Creation Failed, Modification Branch Triggered!" >> PS_DEPLOY:\Logs\$logPath
        Write-Host "Add failed, attempting modification" -ForegroundColor Yellow

        #Update the user, since errors likely occur only if they exist
        Set-LocalUser -AccountNeverExpires -Name $definedName -Password $securePass -Description "Runs PS_RUN Files" -UserMayChangePassword $false -PasswordNeverExpires $true -ErrorAction Stop| Out-Null 
        Add-LocalGroupMember -Group "Administrators" -Member $runnerUser -ErrorAction SilentlyContinue | Out-Null #Shutting this up, the user may be already added at this point, which will throw an error

        Write-Host "Modification Successful" -ForegroundColor DarkGreen
     }
     catch{
        #Complain
        Write-Host "Something went wrong during user creation. Make sure you have permissions to do what you're doing." -ForegroundColor DarkRed
        "User Creation/Modification Failed, Log Writer enabled"  >> PS_DEPLOY:\Logs\$logPath
        $writeLog = 1
     }
}

#Write the Scheduled Task
try{

    #Basic Setup
    $Strider1 = New-ScheduledTaskTrigger -AtStartup #If you get the joke, congrats on owning Ace Combat 7, sets task trigger to startup
    $taskAction = New-ScheduledTaskAction -Execute 'C:\PS_RUN\SoloWingRegistry.bat' #Sets location and file to run

    #Deploys the Task
    Register-ScheduledTask -User $definedName -Password $clearPass -RunLevel Highest -Action $taskAction -Trigger $Strider1 -TaskName "PS_Deploy_LegalBypasser" -Description "Sidesteps the Legal Notice on startup by nuking the registry element on startup" -ErrorAction Stop | Out-Null
    Write-Host "Task Created Successfully!" -ForegroundColor DarkGreen
}

#Something went wrong
catch{

    "Failed to create scheduled task, now attempting to modify a possibly existing one" >> PS_DEPLOY:\Logs\$logPath
    try{
        "Task addition failed, Deleting and trying again" >> PS_DEPLOY:\Logs\$logPath

        #Overwrite an existing task, its possible for the Register to fail if one already exists
        Unregister-ScheduledTask -TaskName "PS_Deploy_LegalBypasser" -Confirm:$false -ErrorAction Stop | Out-Null #Its honestly easier to delete and try it again 
        Register-ScheduledTask -User $definedName -Password $clearPass -RunLevel Highest -Action $taskAction -Trigger $Strider1 -TaskName "PS_Deploy_LegalBypasser" -Description "Sidesteps the Legal Notice on startup by nuking the registry element on startup" -ErrorAction Stop | Out-Null
        Write-Host "Task was successfully modified!" -ForegroundColor DarkGreen
        "Delete and Add was successful" >> PS_DEPLOY:\Logs\$logPath
    }
    catch{
        #Bigtime problem if we hit this
        Write-Host "Fatal Error: Task Creation/Modification entirely failed, please contact James Mester for debugging purposes" -ForegroundColor DarkRed
        "Task Creation and Modification failed, Log Writer enabled" >> PS_DEPLOY:\Logs\$logPath
        $writeLog = 1
    }
}

#Test the arrays to ensure they're the same length
if($regName.Length -eq $regValue.Length){

    #If the array check comes back clean iterate through them
    for($i = 0; $i -le ($regName.Length - 1); $i += 1){
        $displayName = $regName[$i]
        $displayValue = $regValue[$i]

        #Attempt the registry addition
        try{
            Write-Host "Attempting to add $displayName to the Registry" -ForegroundColor Yellow
            New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name $displayName -Value $displayValue -PropertyType String -ErrorAction Stop | Out-Null
            Write-Host "Successfully added $regName[$i] to the Registry with a value of $displayValue" -ForegroundColor DarkGreen
        }
        #If it cant be added, it probably already exists, attempt modifying it
        catch{
            #Modify the registry value
            try{
                "Add Failed, Attempting Re-write to the $displayName value in the Registry" >> PS_DEPLOY:\Logs\$logPath
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name $displayName -Value $displayValue | Out-Null
                Write-Host "Successfully modified $displayName in the Registry to $displayValue" -ForegroundColor DarkGreen
            }

            #This should never trip, if it does then you likely have a permissions problem
            catch{
                Write-Host "Fatal Error! Could not modify the contents of $displayName!!! Do you have permissions to do so?"
                "System failed to add $displayName to Registry, Log Writer enabled" >> PS_DEPLOY:\Logs\$logPath
                $writeLog = 1
            }
        }
    }
}

#If we strike this case we have a problem
else{
    Write-Host "Fatal Error: regName and regValue arrays are not the same length! This could mean that there was a mishap in the configuration and could have lead to an out of bounds error!" -ForegroundColor DarkRed
    "Array check failure" >> PS_DEPLOY:\Logs\$logPath
}

#Writeout Log if it was triggered, dumps the entire Error variable
if($writeLog -eq 1){$Error >> PS_DEPLOY:\Logs\$logPath}

#Be Polite
Write-Host "Edits are done, returning to deployer" -ForegroundColor DarkGreen

#Pause before leaving
Pause