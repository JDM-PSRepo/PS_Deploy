#DeployWinPatch.ps1 v1.3 | by James Mester | GET OFF MY LAWN!!!!
#Please help I've gone insane, Ill see you in $_Shell

#CONTROL VARIABLES | In the form of a 7 digit KB Number
$LOW_BOUND = 2500000 #Lowest KB#
$HIGH_BOUND = 6500000 #Highest KB#
$BREAKOUT = -1 #Breakout Flag, do not adjust this or you screw everything up and it cant ever exit the input loop
$MAX_FAIL = 5 #Up to 5 bad inputs can be put in before the shell kills itself, this can be adjusted up or down as needed
$FORCE_LOGGING = 0 #Set to 0 if you want this to be disabled, but if its on it will generate a file 

#Variables
$iterator = 0 #Keep this as zero for later
$currentKB = -1 #Arbitrary assignment, gets overwritten past an array check
$stupidUser = 0 #PEBCAK Detector, increments till $MAX_FAIL, in which it kills the script
$lastInput = 0 #Used to store keyboard inputs
$recurseInput = 0 #Used exclusively for when Sub KB's are involved, gets set to 0 whenever its envoked
$dupeFlag = 0 #Means a duplicate was detected

#Dynamic Lists
$KBInput = New-Object System.Collections.Generic.List[System.Object] #List for the Ingest
$KBCompletion = New-Object System.Collections.Generic.List[System.Object] #List for the Completion Dump

#Logging Data
$currentUser = WhoAmI #Grabs Username
$hostDevice = Hostname #Grabs Machine Name
$date = get-date -f 'MM-dd-yyyy a\t HH_MM' #Writes the name in a file friendly format
$logPath = "WinPatch-$hostDevice-$date.txt" #Dynamically generates a log name on execute
$writeLog = 0 #0 Means no error occured and no log is generated, if you want outputs for everything use $FORCE_LOGGING

#Check that the logging file is present, if not create it, otherwise the log write will error out
if(-NOT (Test-Path .\Logs)){New-item -ItemType Directory -Name "Logs" | Out-Null}

$Error.Clear() #Shouldnt be needed, but this clears the local shell's stored errors in case somebody was mucking around before they run the script

#Change Directory, Catches a catastrophic situation where the WinPatch folder is gone which breaks the rest of the script. This script operates exclusively in this directory
try{
    #Swap to the WinPatch directory
    cd PS_Deploy:\WinPatch -ErrorAction Stop
}

#If that fails, scream from the rooftops and nope out
catch{
    Write-Host "Something went horribly wrong! Was unable to bind WinPatch database in the PS_Deploy Folder on the network! This is pretty bad news. Did the file get renamed?!" -ForegroundColor DarkRed
    Write-Host "Terminating Shell, cannot proceed!" -ForegroundColor DarkRed
    pause #Hold temporarily before killing the shell
    #Disconnect the Drive
    cd C:\
    remove-psdrive "PS_Deploy" -Force
    #Kill the instance
    exit
}

#Loop until breakout is given or the user gets things wrong three times. Failover for bad user inputs is simply a redundancy, code should self close
while($BREAKOUT -ne $lastInput -AND $stupidUser -lt $MAX_FAIL){

    #Grabs user input and stores it
    $lastInput = Read-Host -Prompt 'Input a KB Number for Windows Patches, Please input 1 at at time | Use -1 to Proceed with Inputs'
    
    #Convert input to integer for comparison, otherwise all integers pass the validation check against high and low bound
    try{
        $compareInput = [int]$lastInput #If its a valid integer, this should work, otherwise it will fail
    }
    catch {
        $compareInput = -999 #Set this to a different value to prevent previously good attempts acting as a bypass for bad ones
    }

    #Run the List in its entirety
    foreach ($KBItem in $KBInput){

        #Check to see if any item matches, if so set the dupe flag
        if($KBItem -eq $lastInput){
            $dupeFlag = 1
        }
    }

    #Sentinel Check, bypass all Else Ifs
    if ( $lastInput -eq $BREAKOUT ){

        #Output notice of execution
        Write-Host "Sentinel Detected, executing the request" -ForegroundColor Green
    }

    #Was the dupe flag set? If so intercept it before it reaches the rest
    elseif($dupeFlag -eq 1){

        #Scold User and reset flag to prevent a lockout
        Write-Host "This item is a duplicate, try again" -ForegroundColor Red
        $dupeFlag = 0
    }

    #Limit the availible patches from KB #'s, this is an effort to sanitize data and check bad inputs, modify these values on Lowbound and Highbound Vars
    elseif ($compareInput -gt $LOW_BOUND -AND $compareInput -lt $HIGH_BOUND){

        #Test the path, if it exists then this is probably a folder and not a file, Validate with a Directory Info Check
        if(Test-Path .\$lastInput){
            if((Get-Item .\$lastInput) -is [System.IO.DirectoryInfo]){
                
                #Reset the Recurse input to 0, this prevents a lockout situation if you ever need to do multiple sub KBs
                $recurseInput = 0

                #This object is indeed a folder, inform the user
                Write-Host "You've input a KB# that has sub KB#'s, these are used by MS to differentiate different builds of the same master article" -ForegroundColor Yellow
                Write-Host "Please select one of the following by typing its name without the file extention" -ForegroundColor Yellow

                #Spool Recursory While with Sentinel value
                while($recurseInput -ne $BREAKOUT){

                #Print the child items, but only the names, if you dont put the "Out-Host" this breaks completely
                Write-Output (Get-ChildItem .\$lastInput | Select Name) | Out-Host

                    #Seek new input from user on Sub KB
                    $recurseInput = Read-Host -Prompt 'Please Input your selection or do -1 to cancel'

                    #Run the List in its entirety, check to ensure no duplicates
                    foreach ($KBItem in $KBInput){

                        #Check to see if any item matches, if so set the dupe flag
                        if($KBItem -eq "$lastInput\$recurseInput"){
                            $dupeFlag = 1
                        }
                    } 
                        

                    #If User is backing out, bypass other cases to avoid weird double printing
                    if($recurseInput -eq -1){
                        Write-Host "Returning to previous menu" -ForegroundColor Yellow
                    }

                    #If its not a sentinel, then check for a dupe
                    elseif($dupeFlag -eq 1){
                        #Scold User and reset flag to prevent a lockout
                        Write-Host "This item is a duplicate, try again" -ForegroundColor Red
                        $dupeFlag = 0
                    }

                    #Not dupe or sentinel, then check its validity
                    elseif(Test-Path .\$lastInput\$recurseInput.cab){
                        
                        #File came back clean, add it
                        Write-Host "File Selected, Appending" -ForegroundColor Green
                        $KBInput.Add("$lastInput\$recurseInput")
                        $recurseInput = -1
                    }

                    #Dump case is invalid input, get angry at user
                    else{
                        Write-Host "Invalid Input, remember to do this without the .cab file extention!" -ForegroundColor Red
                    }
                }
            }
        } #End File Check Block

        #If the file path doesnt exist, it can still be a file this is checked later in the script, so dont worry about it
        else{ 

            #Dump Result into List
            $KBInput.add($lastInput)

            #Print Dopamine because it worked
            Write-Host "Successfully added KB$lastInput to the Queue" -ForegroundColor Green
        }
    } #End Limit Check Block

    #All other inputs are considered bad user data
    else {

        #Increment failure counter
        $stupidUser++

        #Too many bad inputs, kill the program
        if($stupidUser -eq $MAX_FAIL){
            #Write out notice of shell closure, Pause input so they can read it
            Write-Host "Too many invalid inputs detected, failsafe triggered: closing shell" -ForegroundColor DarkRed
            pause
            #Disconnect the Drive
            cd C:\
            remove-psdrive "PS_Deploy" -Force
            #Kill the shell entirely because you did a bad
            exit
        }

        #Gentle Reminder        
        Write-Host "Invalid input, use -1 to continue or please input a 7 digit KB number between '$LOW_BOUND' and '$HIGH_BOUND'. If you need a number beyond these ranges, the orginal script needs to be modified" -ForegroundColor Red
    }
}

#Convert to array once the size has been established, this is just easier to iterate through since i'm not super familiar with lists in PowerShell
$KBArray = $KBInput.ToArray()

#Check if its clean
if($KBArray.Length -eq 0){
    
    #Print error, bypass all other code
    Write-Host "No KB's have been selected, Exiting" -ForegroundColor Yellow
}

#If Array is >= 1, run it
elseif($KBArray -ge 1){
    Write-Host "Now installing the following patches: $KBArray" -ForegroundColor Yellow

    #Iterate through the array, using Less Than as operand to avoid OOB Error
    while ($iterator -lt $KBArray.Length){

        #Assign a KB variable as needed, you cant print the array individually anyway directly in a string
        $currentKB = $KBArray[$iterator]

        #Announce current installation
        Write-Host "Installing KB$currentKB" -ForegroundColor Green

        #If the file exists in the WinPatch Database, install it
        if(Test-Path .\$currentKB.cab){

            #Try Installation - Catch all errors
            try{
                
                #Ignore Check, this essentially is the closest you can get to forcing a package to go through. Avoids restarts as well.
                Add-WindowsPackage -PackagePath .\$currentKB.cab -IgnoreCheck -NoRestart -Online

                #If you make to this part, that means the install worked. Append Completion List
                Write-Host "Installed KB$currentKB" -ForegroundColor Green
                $KBCompletion.add("[KB$currentKB - Installed]")
                
            } #End Installation Try

            catch {

                #If this is the first time, trip the log writer
                if($writeLog -eq 0){
                    Write-Host "Something has gone wrong with KB$currentKB's Instllation. A Log will be generated when the script is complete" -ForegroundColor DarkRed
                    $writeLog = 1
                }
                #Subsequent failures, provide different text as needed to make sense
                else{
                    Write-Host "Something has gone wrong with KB$currentKB's Instllation. This error will also be availible in the generated log file" -ForegroundColor DarkRed
                }

                #The installation failed, so append that to the Completion List
                $KBCompletion.add("[KB$currentKB - Failed: See log $logPath in the Logs Folder]")
            }
        }

        #If it doesnt, avoid attempting and print error
        else{ 

            #If something doesnt exist, write out a text file (or append) to get it set up
            Write-Host "KB$currentKB is not in the Grand Rapids Database, writing a request file in the Database. Contact James to set it up" -ForegroundColor Red 
            "We need KB$currentKB added to the Database for $hostDevice by $currentUser" >> .\RequestedCAB.txt

            #Append the List to say that the problem was a missing KB, not an outright failure
            $KBCompletion.add("[KB$currentKB - Not in Database]")
        }


        #Increment by 1 at the end to proceed to the next patch
        $iterator++
    } #End Iterator
} #End Array Size Check

else{
    Write-Host "A fatal error has occured, KBArray was not 0 or a postive integer. What did you do?" -ForegroundColor DarkRed
}
#If Force Logging is enabled, dump KBCompletion into it first
if($FORCE_LOGGING -eq 1){$KBCompletion >> PS_DEPLOY:\Logs\$logPath;$writeLog = 1}

#Writeout Log if it was triggered, dumps the entire Error variable
if($writeLog -eq 1){$Error >> PS_DEPLOY:\Logs\$logPath}

#Write out everything in a nice and clean format
Write-Host "The following has been performed:" -ForegroundColor Yellow
foreach($completed in $KBCompletion) {

    #Output colorized text based on result
    if($completed.contains("Installed")){ Write-Host "$completed" -ForegroundColor Green} #Success
    elseif($completed.contains("Failed")){ Write-Host "$completed" -ForegroundColor Red} #Failure
    else{Write-Host "$completed" -ForegroundColor Yellow} #Everything else is Yellow
}

#Leave the WinPatch folder to not cause trouble with other scripts
cd PS_DEPLOY:\
#Job's done
Write-Host "Work is complete, returning to deployer"