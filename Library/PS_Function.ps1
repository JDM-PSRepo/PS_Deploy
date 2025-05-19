#PS_Function v2.0 | Good lord this thing is important, and stop reading my comments and GET OFF MY LAWN!!!!!!!
#Long story short this establishes a crud ton of functions that everything else needs so if you mess with it i'll bury you alive in a pile of rusty fillet knives
#Use this to get a value for a catch block by the way: $_.Exception.GetType().FullName

#Gathers the needed information to name a log file to pass back
Function New-LogName{
    
    #Create a log path name and set the variable so that we can make use of it later
    $hostDevice = Hostname #Grabs Machine Name
    $date = get-date -f 'MM-dd-yyyy a\t HH_mm' #Writes the name in a file friendly format
    $logPath = "$TEMP\PS_DEPLOY\PS_DEPLOY-main\Logs\PS_DEPLOY-$hostDevice-$date.txt" #Dynamically generates a log name on execute - Updated to use %temp% because we dont suck

    #Passes back the log file name
    return $logPath
}

#Logs the alert generated and prints a message depending on severity level
Function New-LogMessage($message,$severity){

    #Double check that someone didnt break the logs folder
    if(-NOT(Test-Path .\Logs\)){New-item -ItemType Directory -Name "Logs" -Path .\| Out-Null}
    
    #Decide based on severity
    switch($severity){
       -2 {Write-Host $message -ForegroundColor DarkGreen;$message >> .\Logs\$GLOBAL_LOGPATH;break} #Success
       -1 {$message >> .\Logs\$GLOBAL_LOGPATH;break} #Silent Log, Clean Logs there is no reason to keep them
        0 {$message >> .\Logs\$GLOBAL_LOGPATH;break} #Silent Log, Bypass Log Clearer, there could be something that goes Awry
        1 {Write-Host $message -ForegroundColor Yellow; $message >> .\Logs\$GLOBAL_LOGPATH;break} #General Notice
        2 {Write-Host $message -ForegroundColor DarkYellow; $message >> .\Logs\$GLOBAL_LOGPATH;break} #Minor Issue
        3 {Write-Host $message -ForegroundColor Red; $message >> .\Logs\$GLOBAL_LOGPATH;break} #Medium Issue
        4 {Write-Host $message -ForegroundColor DarkRed; $message >> .\Logs\$GLOBAL_LOGPATH;$Error >> .\Logs\$GLOBAL_LOGPATH;break} #High level Issue
        5 {for(($i=0);$i -lt 3;$i++){Write-Host $message -ForegroundColor DarkRed -BackgroundColor Black}; $message >> .\Logs\$GLOBAL_LOGPATH;$Error >> .\Logs\$GLOBAL_LOGPATH;break} #F***!!!!!!!!!
        default { #Bug detected, throw an error
            Write-Host $message -ForegroundColor DarkMagenta
            Write-Host "Warning! A categorization error has occured! Check whatever called New-LogMessage for $logPath" -ForegroundColor DarkRed
            $message >> .\Logs\$GLOBAL_LOGPATH
            "^^^^^CATEGORIZATION ERROR WITH A VALUE OF $severity OCCURED HERE^^^^^" >> .\Logs\$GLOBAL_LOGPATH
        }
    }

    #Clear out the Errors after we're done, keeps things tidy in here. Bypass if Silent Logger strikes 0
    if($severity -ne 0){$Error.Clear()}
}

#Prompt a check against a range of inputs, Automatically called by Get-DisplayOptions. Values can be provided to dictate a range of answers that are accepted
Function Get-PromptRange($inputText, $minInput, $maxInput){
    $BREAKOUT = -1 #Value to exit
    $BAILOUT = 5 #Value to escape if the user is big dumb
    $pebcak = 0 #Stupid User counter
    $userInput = 0 #User's input, can be whatever
    $compareInput = -999 #Santitized input, tested at a Try Catch

    #Begin Input Loop
    while($userInput -ne $BREAKOUT -AND $pebcak -lt $BAILOUT){
        
        #Read user input with defined prompt | By the way the $'s here are not needed. () evaluates one function and forces order of operations, $() allows for multiple functions to be evaluated at once indescriminantly
        $userInput = $(Write-Host $inputText": " -ForegroundColor White -NoNewline) + $(Read-Host)

        #Convert input string to integer to avoid funny buisness with people putting strings in
        try{
            $compareInput = [int]$userInput #If its a valid integer, this should work, otherwise it will fail
        }

        #Nyet Text =/= Number
        catch {
            New-LogMessage "The following Non-Integer input was given: $userInput | Please only provide an Integer" -severity 2
            $compareInput = -999 #Set this to a different value to prevent previously good attempts acting as a bypass for bad ones
        }

        #Check to see if its legit
        if($compareInput -eq $BREAKOUT){return -1} #Exiting, always return -1 to be safe
        elseif($compareInput -gt $minInput -AND $compareInput -lt $maxInput){return $compareInput} #Valid case was struck, return the Compared Input thats been santitized as Integer
        else{ #All other cases hit this
            Write-Host "That is not a valid input" -ForegroundColor Yellow
            New-LogMessage "User put in an input of: $userInput | Sanitized to: $compareInput | Current Errors: $pebcak" -severity -1
            $pebcak++
        }

        #User is dumb, force an exit
        if($pebcak -ge $BAILOUT){
            Write-Host "Too many bad inputs, exiting by force" -ForegroundColor Red
            New-LogMessage "pebcak was triggered, too many bad inputs" -severity -1
            return -1
        }
        
    }#End While Loop

    New-LogMessage -message "Unexpectly encountered the end of Get-PromptRange, this shouldnt happen under normal operating circumstances, forcing -1" -severity 4
    return -1 #emergency catchall
    
}

#TODO: REBUILD THIS TO TAKE IN A FILE AND A FILE PATH FILE NAME INSTEAD OF JUST AN ARRAY OF STRINGS
#Given an array of options the system will print them with alternating colors and then call Get-PromptRange to parse the response
Function Get-DisplayOptions($displayPrompt, $optionsArray, $specialMessage){
    #Counter to keep track
    $counter = 1
	
	#TODO: ADD THE RESPECTIVE VARIABLES NEEDED TO READ IN FROM A FILE 

    #Display prompt, and iterate through the option array
    Write-Host $DisplayPrompt -ForegroundColor DarkCyan
    foreach($option in $optionsArray){

        #Dump Options, Use counter to enumerate, Alternate color based on Modulo of Counter for Even/Odd
        if(($counter % 2) -eq 0){Write-Host "$Counter) $option" -ForegroundColor Gray}
        else{Write-Host "$Counter) $option" -ForegroundColor DarkGray}
        $counter++ #increment
    }

    #Dump a special message if one exists
    if($specialMessage.Length -gt 0){Write-Host $specialMessage -ForegroundColor DarkCyan}

    #Call Input Prompt and pass back the response
    $userResp = Get-PromptRange -inputText "Please choose a number from above" -minInput 0 -maxInput $counter
    return $userResp
}


#Adds a Hive to the Registry, Returns True if successful, False otherwise
#Does not create values
Function Set-RegHive($hivePath, $hiveName){
    #Add ORL Hive
    try{New-Item -Path $hivePath -name $hiveName -ErrorAction Stop;New-LogMessage -message "$hiveName Hive Added" -severity -2}
    catch [System.Security.SecurityException]{New-LogMessage -message "Access Denied. Escalate your permissions in order to perform this operation" -severity 4;return $false}
    catch [System.IO.IOException]{New-LogMessage -message "$hiveName Hive Already Exists, Continuing" -severity -2}
    catch {
        #Good job, you broke something
        New-LogMessage -message ($_.Exception.GetType().FullName) -severity -1
        New-LogMessage -message "WARNING!!! UNCATEGORIZED ERROR HAS OCCURED! WHAT DID YOU BREAK!?" -severity 5
        return $false
    }
    #If you made
    return $true
}

#Modifies or Adds a registry value based on given paremeters | Returns True if successful, returns False if failed | FAILS IF THE REGISTRY PATH DOESNT EXIST, USE Set-RegHive FOR THAT!
Function Set-RegValue($regPath, $regName, $regValue, $regProperty){

    if(Test-Path $regPath){
        
        #make sure we have a legitamate Name and Value
        if($regName.Length -ne 0 -AND $regValue.Length -ne 0){
        
            #If theres no length to the property, its likely a Hexadecimal Dump, thats fine just continue forward
            if($regProperty.Length -eq 0){
                
                #Push Forward with setting the property
                try{New-ItemProperty -Path $regPath -Name $regName -Value $regValue -ErrorAction Stop;New-LogMessage "Registry Property created successfully" -severity -2}
                catch{
                    #Issue occured with the New-ItemProperty, print to log, dont clear the error, push forward with setting the value
                    New-LogMessage -message "New-ItemProperty for $regName failed, switching to Setter | Non-Property Type Tree" -severity 0 
                    try{Set-ItemProperty -Path $regPath -Name $regName -Value $regValue -ErrorAction Stop;New-LogMessage "Registry Property set successfully" -severity -2}
                    catch [Microsoft.PowerShell.Commands.AccessDeniedException]{New-LogMessage -message "You do not have permissions to perform this operation" -severity 4;return $false} #Get permissions, Loser
                    catch{
                        #Catch and log the property of the unknown error so that we can snag it in th efuture or look up what is wrong.
                        New-LogMessage -message ($_.Exception.GetType().FullName) -severity 0
                        New-LogMessage "WARNING!!! Set-RegValue FAILED TO SET VALUE $regName TO $regValue IN NON-PROPERTY TREE THIS MEANS SOMETHING WENT PRETTY WRONG IN THE PROCESS, CHECK LOGS" -severity 4
                        return $false
                    }     
                }#End Try-Catch Chain   
            }

            #If we DO then have a length to our property, then it can be deliberately assigned, only because we sanitized earlier results
            else{
                #Push Forward with setting the property
                try{New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType $regProperty -ErrorAction Stop;New-LogMessage "Registry Property created successfully" -severity -2}
                catch{
                    #Issue occured with the New-ItemProperty, print to log, dont clear the error, push forward with setting the value. Keep in mind Set-ItemProperty does not support the -PropertyType flag!
                    New-LogMessage -message "New-ItemProperty for $regName failed, switching to Setter | Property Type Tree" -severity 0 
                    try{Set-ItemProperty -Path $regPath -Name $regName -Value $regValue -ErrorAction Stop;New-LogMessage "Registry Property set successfully" -severity -2}
                    catch [Microsoft.PowerShell.Commands.AccessDeniedException]{New-LogMessage -message "You do not have permissions to perform this operation" -severity 4;return $false}
                    catch{
                        #Snag and catch this error, if we dont it may be harder to reverse engineer what the hell is going on
                        New-LogMessage -message ($_.Exception.GetType().FullName) -severity 0
                        New-LogMessage -message "WARNING!!! Set-RegValue FAILED TO SET VALUE $regName TO $regValue IN PROPERTY TREE THIS MEANS SOMETHING WENT PRETTY WRONG IN THE PROCESS, CHECK LOGS" -severity 4
                        return $false}     
                }#End Try-Catch Chain   
            }
        }#End Name and Value Check = TRUE

        #Failed the Name or Value check, scream
        else{New-LogMessage "WARNING!!! regName HAD A VALUE OF: $regName AND regValue HAD A VALUE OF: $regValue. THESE ARE NOT LEGITAMATE AND TRIGGERED A LENGTH ERROR, BYPASSING EDIT" -severity 5;return $false}

    } #End Test Path Protector

    #If the path doesnt exist, this is a SEVERE issue and needs to be corrected, bypass all logic to alert user
    else{New-LogMessage -message "CATATROPHIC ERROR!!!! A PATH THAT DOES NOT EXIST WAS HANDED TO Set-RegValue!!! THIS SHOULD NOT OCCUR, THE PATH SHOULD BE MADE BEFOREHAND!!!" -severity 5;return $false}

    #Good job, you made it
    return $true

}

#Adds or Replaces a task based on given parameters | Returns true or false based on operation results
Function Set-LocalTask($taskUser, $clearPass, $taskAction, $taskTrigger, $taskName, $taskDesc){
    
    try{
        #Attempt to register the task
        Register-ScheduledTask -User $taskUser -Password $clearPass -RunLevel Highest -Action $taskAction -Trigger $taskTrigger -TaskName $taskName -Description $taskDesc -ErrorAction Stop | Out-Null
        New-LogMessage -message "Task successfully added!" -severity -2
    
    }
    catch [Microsoft.PowerShell.Commands.AccessDeniedException]{New-LogMessage -message "You do not have permissions to perform this action" -severity 4;return $false} #No permission, sucks to be you
    catch [Microsoft.Management.Infrastructure.CimException]{ #Task exists, try deleting and re-adding it
        try{
            New-LogMessage -message "Task exists, or likely exists, unregistering and rerunning the registry" -severity 0
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop | Out-Null #Its honestly easier to delete and try it again 
            Register-ScheduledTask -User $taskUser -Password $clearPass -RunLevel Highest -Action $taskAction -Trigger $taskTrigger -TaskName $taskName -Description $taskDesc -ErrorAction Stop | Out-Null
            New-LogMessage -message "Task has been successfully updated" -severity -2
        }
        #Everything Failed, Scream
        catch{ 
            #Snag and catch this error, if we dont it may be harder to reverse engineer what the hell is going on
            New-LogMessage -message ($_.Exception.GetType().FullName) -severity 0
            New-LogMessage -message "WARNING! UNCATEGORIZED ERROR HAS OCCURED. THIS ISNT GOOD. NOW WHERE'S MY DRAGONATOR!?" -severity 5
            return $false
        }
    }
    #Dump Case
    catch{
        #Snag and catch this error, if we dont it may be harder to reverse engineer what the hell is going on
        New-LogMessage -message ($_.Exception.GetType().FullName) -severity 0
        New-LogMessage -message "WARNING! THE SYSTEM ENCOUNTERED AN ERROR BESIDES PERMISSION AND PRE-EXISTING TASKS. SERIOUSLY WHAT DID YOU BREAK!?" -severity 5
        return $false
        }

    #Congradulations, nothing broke
    return $true
}

#Adds or Updates a user based on given parameters | Returns True if successful, returns False if failed
Function Set-LocalAdminUser($definedName, $securePass, $descUser){
    
    #Compound Username
    $runnerUser = "$hostDevice\$definedName"

    #Deploy the new local user to run this stuff
    try{
        #Create a new user, force its existence, and as a backup security measure: make it so the user cannot change their own password. Kinda moot as admin but i'm trying
        New-LogMessage -message "Adding User to the system" -severity -2
        New-LocalUser -AccountNeverExpires -Name $definedName -Password $securePass -Description $descUser -UserMayNotChangePassword -PasswordNeverExpires -ErrorAction Stop| Out-Null
        New-LogMessage -message "Service User Added Successfully" -severity -2 
        
    }

    catch [Microsoft.PowerShell.Commands.AccessDeniedException]{New-LogMessage -message "You do not have permissions to perform this operation" -severity 4;return -1} #No Perms, Ruh Roh. Your Rugged Raggy
    catch [Microsoft.PowerShell.Commands.MemberExistsException]{ #User is already in the system. Edit their credentials
        try{
            #Log and attempt the modification process using Set-LocalUser instead
            New-LogMessage -message "Creation Failed, Modification Branch Triggered!" -severity 0
            Set-LocalUser -AccountNeverExpires -Name $definedName -Password $securePass -Description $descUser -UserMayChangePassword $false -PasswordNeverExpires $true -ErrorAction Stop| Out-Null
            New-LogMessage -message "Service User Updated with new information" -severity -2
        }
        #If something else somehow comes up, freak out. Permissions should trip before a failed modification so I dont feel the need to put a Access Denied block here, plus it'll be in the logs so who cares
        catch{
            New-LogMessage -message ($_.Exception.GetType().FullName) -severity 0 #Catching the error
            New-LogMessage -message "User Modification failed entirely. This issue is logged and process is aborted" -severity 5
            return $false
        }
    } #End Modification Branch
    catch{
        New-LogMessage -message ($_.Exception.GetType().FullName) -severity 0 #Catching the error
        New-LogMessage -message "An unknown exception has occured! Check the logs and contact James immedeatly!!!" -severity 5
        return -1;
    } #Unknown Final Exception
    
    #If we've made it this far, we havent encountered a fatal error | BEGIN ADMIN ESCALATION

    try{
        #Escalate to Admin
        New-LogMessage -message "Escalating user to Local Admin" -severity -2
        Add-LocalGroupMember -Group "Administrators" -Member $runnerUser -ErrorAction Stop | Out-Null
        New-LogMessage -message "User successfully added and escalated to admin" -severity -2
    }
    catch [Microsoft.PowerShell.Commands.AccessDeniedException]{New-LogMessage -message "You do not have permissions to perform this operation" -severity 4;return $false} #Come back with better permissions, Imperial
    catch [Microsoft.PowerShell.Commands.MemberExistsException]{New-LogMessage -message "User is already in the system as an Administrator. No major problem detected, Op Successful" -severity -1;return $true} #Existing user bypass
    catch{
        New-LogMessage -message ($_.Exception.GetType().FullName) -severity 0 #Catching the error
        New-LogMessage -message "An unknown exception has occured! Check the logs and contact James immedeatly!!!" -severity 5
        return $false
    } #Unknown Error, you really screwed up dude
    
    #Congrats, you're now and admin and didnt irritate the machine gods!
    return $true
}



# Legacy code, none of this should be used but kept

<#
Function Add-AutologBypass($autoUser, $autoPass){

    #User Defined Variables. Dont mess with these unless you want to change something
    $regName = "AutoAdminLogon", "DefaultUserName", "DefaultPassword", "DefaultDomainName" #Values in the registry to modify
    $regValue = "1", "$autoUser", "$autoPass", "CORPLEAR" #Values to put in registry
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
    $regTotal = $true

    $Error.Clear() #Shouldnt be needed, but this clears the local shell's stored errors in case somebody was mucking around before they run the script

    #Script Success, Network Share was properly mounted and launched from Copy Paste Deployer
    New-LogMessage -message "Autologger + Bypass successfully launched, editing Registry to automatically login on start" -severity 1

    #Check to make sure that the PS_RUN folder exists, if not make it
    if(-NOT (Test-Path C:\PS_RUN)){New-item -ItemType Directory -Path "C:\" -Name "PS_RUN" | Out-Null; New-LogMessage -message "PS_RUN Created as it did not exist" -severity 1}
    else{New-LogMessage -message "PS_RUN already exists, Skipping File Creation" -severity 1}

    #Speak to User
    New-LogMessage -message "Deploying Batch Payload" -severity 1

    #Attempt to move the Batch File for the Registry Nuke into the PS_RUN folder. If this fails, alert the user.
    try{
        #Copy the Nuker Bat to local files
        Copy-Item .\DeployFiles\LegalBypass\SoloWingRegistry.bat -Destination C:\PS_RUN -Force -ErrorAction Stop | Out-Null
        New-LogMessage -message "Registry Batch Staged in PS_RUN" -severity -2
    }

    #Something borked, complain
    catch{
        New-LogMessage -message "Fatal Error: SoloWingRegistry.bat couldnt be relocated to the PS_RUN file?. Did the file get deleted?" -severity 4
        return $false
    }

    #Attempt to add the user, update the variable based on success or failure
    $userSuccess = Set-LocalAdminUser -definedName $definedName -securePass $securePass -descUser "Runs PS_RUN Files"

    #The task is tied to the user account, so if that fails then the task will fail.
    if($userSuccess){
        $taskSuccess = Set-LocalTask -taskUser $runnerUser -clearPass $clearPass -taskAction $taskAction -taskTrigger $Strider1 -taskName "PS_Deploy_LegalBypasser" -taskDesc "Sidesteps the Legal Notice on startup by nuking the registry element on startup"
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
            New-LogMessage -message "Attempting to add $displayName to the Registry" -severity 1
       
            #Load next registry value, log the results
            $regSuccess[$i] = Set-RegValue -regPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -regName $displayName -regValue $displayValue -regProperty String

            #Test for success, if it fails scream an error
            if($regSuccess[$i]){New-LogMessage -message "Successfully added $regName[$i] to the Registry with a value of $displayValue" -severity -2}
            else{New-LogMessage -message "Add of $displayName failed. This issue has been logged." -severity 4;$regTotal = $false}
        }
    }

    #If we strike this case we have a problem
    else{
        New-LogMessage -message "Fatal Error: regName and regValue arrays are not the same length! This could mean that there was a mishap in the configuration and could have lead to an out of bounds error!" -severity 5
        return $false
    }

    #If it was successful enough to make it this far, ensure that there was no registry add errors and return true. Otherwise, catchall false will save the day! (by making our life miserable)
    if($regTotal){return $true}
    return $false
}

Function Add-Autolog($autoUser, $autoPass){

    #User Defined Variables. Dont mess with these unless you want to change something
    $regName = "AutoAdminLogon", "DefaultUserName", "DefaultPassword", "DefaultDomainName" #Values in the registry to modify
    $regValue = "1", "$autoUser", "$autoPass", "CORPLEAR" #Values to put in registry
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
    $regTotal = $true

    $Error.Clear() #Shouldnt be needed, but this clears the local shell's stored errors in case somebody was mucking around before they run the script

    #Script Success, Network Share was properly mounted and launched from Copy Paste Deployer
    New-LogMessage -message "Autologger successfully launched, editing Registry to automatically login on start" -severity 1

    #Add the Autologin for GEN_GRATimeclock, at the very minimum if the legal bypass fails we can still always just add this
    #Test the arrays to ensure they're the same length
    if($regName.Length -eq $regValue.Length){

        #If the array check comes back clean iterate through them
        for($i = 0; $i -le ($regName.Length - 1); $i += 1){

            #Load the next item from the array
            $displayName = $regName[$i]
            $displayValue = $regValue[$i]

            #Speak to user
            New-LogMessage -message "Attempting to add $displayName to the Registry" -severity 1
       
            #Load next registry value, log the results
            $regSuccess[$i] = Set-RegValue -regPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -regName $displayName -regValue $displayValue -regProperty String

            #Test for success, if it fails scream an error
            if($regSuccess[$i]){New-LogMessage -message "Successfully added $regName[$i] to the Registry with a value of $displayValue" -severity -2}
            else{New-LogMessage -message "Add of $displayName failed. This issue has been logged." -severity 4;$regTotal = $false}
        }
    }

    #If we strike this case we have a problem
    else{
        New-LogMessage -message "Fatal Error: regName and regValue arrays are not the same length! This could mean that there was a mishap in the configuration and could have lead to an out of bounds error!" -severity 5
        return $false
    }

    #If it was successful enough to make it this far, ensure that there was no registry add errors and return true. Otherwise, catchall false will save the day! (by making our life miserable)
    if($regTotal){return $true}
    return $false
}
#>

