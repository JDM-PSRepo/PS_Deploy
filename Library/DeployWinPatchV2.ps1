#DeployWinPatch.ps1 v2.0 | by James Mester | WHY ARE YOU STILL ON MY LAWN!?!!!!
#Please help I've gone insane, Ill see you in $_Shell

#CONTROL VARIABLES | In the form of a 7 digit KB Number
$LOW_BOUND = 2500000 #Lowest KB#
$HIGH_BOUND = 6500000 #Highest KB#
$BREAKOUT = -1 #Breakout Flag, do not adjust this or you screw everything up and it cant ever exit the input loop
$MAX_FAIL = 5 #Up to 5 bad inputs can be put in before the shell kills itself, this can be adjusted up or down as needed

#Variables
$iterator = 0 #Keep this as zero for later
$currentKB = -1 #Arbitrary assignment, gets overwritten past an array check
$lastInput = 0 #Stores the cleansed input for Input-PromptRange
$recurseInput = 0 #Used exclusively for when Sub KB's are involved, gets set to 0 whenever its envoked
$dupeFlag = 0 #Means a duplicate was detected

#Dynamic Lists
$KBInput = New-Object System.Collections.Generic.List[System.Object] #List for the Ingest
$KBCompletion = New-Object System.Collections.Generic.List[System.Object] #List for the Completion Dump

$Error.Clear() #Just double check that the logging system is clear

try{
    #Swap to the WinPatch directory
    cd PS_Deploy:\WinPatch -ErrorAction Stop
}

#If that fails, scream from the rooftops and nope out
catch{
    Log-Alert -message "Something went horribly wrong! Was unable to bind WinPatch database in the PS_Deploy Folder on the network! This is pretty bad news. Did the file get renamed?! Exiting now!" -severity 5
    pause #Hold temporarily before killing the shell
    #Disconnect the Drive
    cd C:\
    remove-psdrive "PS_Deploy" -Force
    #Kill the instance
    exit
}

#Error checking is now handled by Input-PromptRange, we only need to watch the input value now thanks to that
while($BREAKOUT -ne $lastInput){

    #Pass input prompt to $lastInput so we can proceed
    $lastInput = Input-PromptRange -inputText 'Input a KB Number for Windows Patches, Please input 1 at at time | Use -1 to Proceed with Inputs' -minInput $LOW_BOUND -maxInput $HIGH_BOUND

    #Run the List in its entirety to check for duplicates
    foreach ($KBItem in $KBInput){
        #Check to see if any item matches, if so set the dupe flag
        if($KBItem -eq $lastInput){$dupeFlag = 1}
    }

    #Sentinel Check, bypass all Else Ifs
    if ( $lastInput -eq $BREAKOUT ){
        #Output notice of execution
        Log-Alert -message "Sentinel Detected, executing the request" -severity -2
    }

    #Was the dupe flag set? If so intercept it before it reaches the rest
    elseif($dupeFlag -eq 1){
        #Scold User and reset flag to prevent a lockout
        Log-Alert -message "The item $lastInput is a duplicate, try again" -severity 3
        $dupeFlag = 0
    }

    #Limit the availible patches from KB #'s, this is an effort to sanitize data and check bad inputs, modify these values on Lowbound and Highbound Vars. These values parody what gets cleansed by Input-PromptRange
    elseif ($compareInput -gt $LOW_BOUND -AND $compareInput -lt $HIGH_BOUND){

        #Test the path, if it exists then this is probably a folder and not a file, Validate with a Directory Info Check
        if(Test-Path .\$lastInput){
            #This line here checks to see if the item grabbed is a Directory and its info. If this evaluates as true its a Folder and that means we have sub-patches
            if((Get-Item .\$lastInput) -is [System.IO.DirectoryInfo]){
                
                #Reset the Recurse input to 0, this prevents a lockout situation if you ever need to do multiple sub KBs
                $recurseInput = 0

                #This object is indeed a folder, inform the user
                Log-Alert -message "You've input a KB# that has sub KB#'s, these are used by MS to differentiate different builds of the same master article" -severity 1
                Log-Alert -message "Please select one of the following by typing its name without the file extention" -severity 1

                #Spool Recursory While with Sentinel value
                while($recurseInput -ne $BREAKOUT){

                #Print the child items, but only the names, if you dont put the "Out-Host" this breaks completely
                Write-Output (Get-ChildItem .\$lastInput | Select Name) | Out-Host

                    #Seek new input from user on Sub KB
                    $recurseInput = Read-Host -Prompt 'Please Input your selection or do -1 to cancel'

                    #Run the List in its entirety, check to ensure no duplicates
                    foreach ($KBItem in $KBInput){
                        if($KBItem -eq "$lastInput\$recurseInput"){$dupeFlag = 1}
                    }

                        #Choice Tree
                        
                    #If User is backing out, bypass other cases to avoid weird double printing
                    if($recurseInput -eq -1){Log-Alert -message "Returning to previous menu" -severity 1}

                    #Asterisk catcher, I noticed this had a tendancy to slip through since it doesnt have a numerical sanitizer like the main loop
                    elseif($recurseInput -match "\*"){Log-Alert -message "Asterisk detected in input! You cant put these in here or else it could break stuff! I hope to have a universal add solution in a future version, sorry!" -severity 2}

                    #If its not a sentinel, then check for a dupe flag being set. Reset it once this is done
                    elseif($dupeFlag -eq 1){Log-Alert -message "This item is a duplicate, try again" -severity 3;$dupeFlag = 0}


                    #Not dupe or sentinel, then check its validity
                    elseif(Test-Path .\$lastInput\$recurseInput.cab){
                        
                        #File came back clean, add it
                        Log-Alert -message "File Selected, Appending" -severity -2
                        $KBInput.Add("$lastInput\$recurseInput")
                        $recurseInput = -1
                    }

                    #Dump case is invalid input, get angry at user
                    else{
                        Log-Alert -message "Invalid Input, remember to do this without the .cab file extention!" -severity 3
                    }
                }
            } #End SubKB Check Block
        } #End File Path Test block

        #If the file path doesnt exist, it can still be a file this is checked later in the script, so dont worry about it
        else{ 

            #Dump Result into List
            $KBInput.add($lastInput)

            #Print Dopamine because it worked
            Log-Alert -message "Successfully added KB$lastInput to the Queue" -severity -2
        }
    } #End Limit Check Block

    #All other inputs are considered bad user data
    else {
        
        #Failout is handled by PS_Function now. This shouldnt be triggered
        Log-Alert -message "Else case in the evaluation branch of DeployWinPatchV2 was struck. This means that Input-PromptRange passed back an invalid input!" -severity 4
    }
}

#Convert to array once the size has been established, this is just easier to iterate through since i'm not super familiar with lists in PowerShell
try{
    $KBArray = $KBInput.ToArray()
}
catch{
    
    #I dont think i'll need this but how many times have i said that and been wrong? (Answer: Quite a few)
    Log-Alert -message "List to Array conversion failed! This prevents the KB's from being installed. Contact James immedeatly!!!" -severity 5
}

#Check if its empty. If it is: print error and bypass installation code
if($KBArray.Length -eq 0){Log-Alert -message "No KB's have been selected, Exiting" -severity 1}

#If Array is >= 1, run it
elseif($KBArray -ge 1){
    Log-Alert -message "Now installing the following patches: $KBArray" -severity 1

    #Iterate through the array, using Less Than as operand to avoid OOB Error
    while ($iterator -lt $KBArray.Length){

        #Assign a KB variable as needed, you cant print the array individually anyway directly in a string
        $currentKB = $KBArray[$iterator]

        #Announce current installation
        Log-Alert -message "Installing KB$currentKB" -severity 1

        #If the file exists in the WinPatch Database, install it
        if(Test-Path .\$currentKB.cab){

            #Try Installation - Catch all errors
            try{
                
                #Ignore Check, this essentially is the closest you can get to forcing a package to go through. Avoids restarts as well. Also shuts up the input and hard crashes the attempt when failing to force the catch block
                Add-WindowsPackage -PackagePath .\$currentKB.cab -IgnoreCheck -NoRestart -Online -ErrorAction Stop| Out-Null

                #If you make to this part, that means the install worked. Append Completion List
                Log-Alert -message "Installed KB$currentKB" -severity -2
                Log-Alert -message "KB$currentKB Was installed successfully" -severity -1
                $KBCompletion.add("[KB$currentKB - Installed]")
                
            } #End Installation Try

            catch {
                #The installation failed, so append that to the Completion List
                Log-Alert -message "Something has gone wrong with KB$currentKB's Instllation. This has been appended to the current log for this instance" -severity 4
                $KBCompletion.add("[KB$currentKB - Failed: See log $logPath in the Logs Folder]")
            }
        }

        #If it doesnt, avoid attempting and print error
        else{ 

            #If something doesnt exist, write out a text file (or append) to get it set up
            Log-Alert -message "KB$currentKB is not in the Grand Rapids Database, writing a request file in the Database. Contact James to set it up" -severity 2
            "We need KB$currentKB added to the Database for $hostDevice by $currentUser" >> .\RequestedCAB.txt

            #Append the List to say that the problem was a missing KB, not an outright failure
            $KBCompletion.add("[KB$currentKB - Not in Database]")
        }

        #Increment by 1 at the end to proceed to the next patch
        $iterator++
    } #End Iterator
} #End Array Size Check

else{
    Log-Alert "A fatal error has occured, KBArray was not 0 or a postive integer. What did you do?" -severity 4
}

#Write out everything in a nice and clean format
Log-Alert -message "The following has been performed:" -severity 1
foreach($completed in $KBCompletion) {

    #Output colorized text based on result
    if($completed.contains("Installed")){Log-Alert -message "$completed" -severity -2} #Success
    elseif($completed.contains("Failed")){Log-Alert -message "$completed" -severity 3} #Failure
    else{Log-Alert "$completed" -severity 2} #Everything else is Yellow
}

#Leave the WinPatch folder to not cause trouble with other scripts
cd PS_DEPLOY:\
#Job's done
Write-Host "Work is complete, returning to deployer"