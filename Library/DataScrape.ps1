"Making a file"

#Essential Vars
$launchCode = $false #Check Flag
$filePath = "%TEMP%\Logs\$(Hostname)-Scrape.txt"
$dumpLocation = "C:\" #Default location is to pump this into C:, but adding a change script down the road.
$ejectFlag = $false
$promptFlag = $false
$promptInput = ""
$errorFlag = $false

#Check if file can be made
try{
    "Begin Data Dump" >> $filePath
    $launchCode = $true
    }
catch{
    "Data file creation failed. Did you run it as admin?"
    $errorFlag = $true
    }

#Want to save somewhere else than C?
while($promptFlag = $false){

    if($errorFlag){break}

    $promptInput = Read-Host -Prompt "Would you like to save to a different location than $dumpLocation for the dump file? Y/N"
	
    
    if($promptInput -eq "Y"){
        $promptFlag = $true
    }
    elseif($promptInput -eq "N"){
        $promptFlag = $true
        $ejectFlag = $true
    }
    else{
        Write-Host "Invalid input, try again" -ForegroundColor Red 
    }
}
	
while(($ejectFlag = $false){
	$dumpLocation = Read-Host -Prompt "Where would you like to save?"

    if(Test-Path -Path $dumpLocation){
        Write-Host "Successfully targeted file location, beginning now" -ForegroundColor Green
        $ejectFlag = $true
    }
    else{
        Write-Host "Invalid file location of $dumpLocation please try again" -ForegroundColor Red
    }


#If yes, send it
if($launchCode -eq $true){

    if($errorFlag){break}

    #Dump deets
    "`n`nDumping Host Name" >> $filePath
    Hostname >> $filePath

    "`n`nDumping active user"
    WhoAmI >> $filePath

    "`n`nDumping Networking Info" >> $filePath
    IPCONFIG /ALL >> $filePath

    "`n`nDumping DSREGCMD config" >> $filePath
    DSREGCMD /status >> $filePath

    "`n`nGetting everything else" >> $filePath
    Get-ComputerInfo >> $filePath

    "Writeout complete!" 

    #Try to copy it to a known network location for ease of use
	try{
        Copy-item -Path $filePath -Destination $dumpLocation
        "File Copied over!"
        }
    catch{
        "File copy failed, try it manually?"
		
        }
    }
}
