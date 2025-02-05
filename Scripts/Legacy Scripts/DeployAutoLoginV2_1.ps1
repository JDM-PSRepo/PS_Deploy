#DeployAutoLogin.ps1 v2.1 | James Mester | Quit reading my comments, and GET OFF MY LAWN!
#Too Bad, Buddy | This twisted game needs to be reset | We'll reset everything to Zero with this V2
#Established Registry Based Autologin to a Client PC over RCT's Powershell Instance, this script can also be run locally too with the Copy Paste Deployer, modified to work with the super deployer

#The intent of this verison is to add the ability to destinguish between timeclocks and LPS dashboards, allowing us to image a PC and just run this script and be done with it.

#While Controllers
$BREAKOUT = -1 #Breakout Flag, do not adjust this or you screw everything up and it cant ever exit the input loop
$MAX_FAIL = 5 #Up to 5 bad inputs can be put in before the shell kills itself, this can be adjusted up or down as needed

#Pre-Established Variables, dont mess with this unless you know what they do
$regName = "AutoAdminLogon", "DefaultUserName", "DefaultPassword", "DefaultDomainName" #Values in the registry to modify
$regValue = "1", "GEN_GRATimeclock", "Lear2021", "CORPLEAR" #Values to put in registry
$hostDevice = Hostname #Grabs Machine Name
$definedName = "PS_RUNNER" #Change this if you want to modify the name of the User
$runnerUser = "$hostDevice\$definedName" #Dont modify this, its automatically generated from prior variables
$clearPass = "SR71Blackb!rd" #I'm not a fan of clear text passwords, but nobody should have access to this file and it only controls admin rights to signage PC's with no user access nor network power so, im gonna do it. Sorry mom. The right way is a pain in the butt
$securePass = $clearPass | ConvertTo-SecureString -AsPlainText -Force #This is my way of saying this is bad and i have to override windows's safeguards, but outputting secure strings to files requires byte keys and i dont wanna.
$stupidUser = 0 #PEBCAK Detector, increments till $MAX_FAIL, in which it kills the script
$lastInput = 0 #Used to store keyboard inputs

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


#New Stuff Here



#Begin while Catch
while ($BREAKOUT -ne $lastInput -AND $stupidUser -lt $MAX_FAIL){

    #Grabs user input and stores it
    Write-Host "If this is a setup for a new PC, please input the following:" -ForegroundColor Yellow
    Write-Host "1) This is a Timeclock" -ForegroundColor DarkYellow
    Write-Host "2) This is a Visitor's Kiosk" -ForegroundColor Yellow
    Write-Host "3) This is a Signage Board" -ForegroundColor DarkYellow
    Write-Host "4) This is a LPS Dashboard" -ForegroundColor Yellow
    $lastInput = Read-Host -Prompt "Input -1 if you'd like to skip this process, otherwise please enter a number to pre-install the needed items"
    
    #Convert input to integer for comparison, otherwise all integers pass the validation check against high and low bound
    try{
        $compareInput = [int]$lastInput #If its a valid integer, this should work, otherwise it will fail
    }
    catch {
        $compareInput = -999 #Set this to a different value to prevent previously good attempts acting as a bypass for bad ones
    }

     #Sentinel Check
    if ( $lastInput -eq $BREAKOUT ){

        #Output notice of execution
        Write-Host "Sentinel Detected, executing the request" -ForegroundColor Green
    }

    switch($compareInput){
        
        1 {}#Timeclock Deployment
        2 {}#Visitors Kiosk Deployment
        3 {}#Irfan View Setup
        4 {

            Write-Host "You've Inputted an LPS Dash Deployment, please input the following:" -ForegroundColor Yellow
            Write-Host "1) WL60% OP20A" -ForegroundColor DarkYellow
            Write-Host "2) WL60% Main" -ForegroundColor Yellow
            Write-Host "3) WL40% OP20B" -ForegroundColor DarkYellow
            Write-Host "4) WL60% Main" -ForegroundColor Yellow
            Write-Host "5) WL Marraige Line" -ForegroundColor DarkYellow
            $lastInput = Read-Host -Prompt "Input your chosen answer, choosing anything else will skip this process"

            try{
                $compareInput = [int]$lastInput #If its a valid integer, this should work, otherwise it will fail
            }
            catch {
                $compareInput = -999 #Set this to a different value to prevent previously good attempts acting as a bypass for bad ones
            }

            switch($compareInput)
                1{Copy-item -Path PS_DEPLOY:\DeployFiles\LPSDash\AutoLPSDash_40_Main.bat -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
                2{Copy-item -Path PS_DEPLOY:\DeployFiles\LPSDash\AutoLPSDash_40_Main.bat -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
                3{Copy-item -Path PS_DEPLOY:\DeployFiles\LPSDash\AutoLPSDash_40_Main.bat -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
                4{Copy-item -Path PS_DEPLOY:\DeployFiles\LPSDash\AutoLPSDash_40_Main.bat -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
                5{Copy-item -Path PS_DEPLOY:\DeployFiles\LPSDash\AutoLPSDash_40_Main.bat -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"

            
        
        
        
        
        }#LPS Dashboard
        default {Write-Host "You've selected an invalid option, please read from the options again";$stupidUser++}

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