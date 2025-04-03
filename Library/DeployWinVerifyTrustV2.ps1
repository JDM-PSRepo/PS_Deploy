#DeployWinVerifyTrustV2 by James Mester | A "refined" version that uses my PS_Functions system. Also.... GET OFF MY LAWN!!!!!!!!

#Check variables. Is this needed? No. But it allows for debugging if I really want. realistically I should merge this into an array but i'm not going to rigtht his second.
$hive1 = $false
$hive2 = $false
$hive3 = $false
$hive4 = $false
$hive5 = $false
$hive6 = $false
$32Bit = $false
$64Bit = $false
$success = $false
$errCount = 0

#Clear Log
$Error.Clear()

#Alert user
Log-Alert -message "Launching DeployWinVerifyTrustV2 | Preparing. . ." -severity -2

#Welcome user, then promptly yell at them
Write-Host "Welcome to the deployer for WinVerifyTrust's Reg Edit. This is intended to fix CVE-2013-3900's Security Vunderability" -ForegroundColor Yellow
Write-Host "WARNING! THIS DEPLOYER SHOULD ONLY BE RUN AGAINST SERVERS WHICH NEED IT. ARE YOU SURE THAT THIS IS A SERVER WHICH SHOULD REASONABLY SEE ITS DEPLOYMENT? (Y/N)" -ForegroundColor DarkRed

#Lazy input code that doesnt repeat the warning over and over
while($invalidInput -eq 1){
    $inputResponse = Read-Host #Take in input

    #Check Valid Answers
    switch($inputResponse){
        'Y'{$invalidInput = 0} #Valid Option
        'N'{$invalidInput = 0} #Valid Option
        Default{Write-Host "I dont recognize that answer, please respond with Y or N" -ForegroundColor Red} #Bad Input
    }
}#Confirmation Loop End

#Sanitize Input Flag
$invalidInput = 1

#If they said yes go ahead
if($inputResponse -eq "Y"){

    #Ask User
    Write-Host "Is this system 32-bit or 64-bit? (32/64)" -ForegroundColor Yellow

    #Is this 32 or 64 bit?
    while($invalidInput -eq 1){
        $inputResponse = Read-Host #Input Answer from user

        #Check Valid Answers
        switch($inputResponse){
            64{$bitFlag = 1; $invalidInput = 0} #Add Extra REG Node, Exit
            32{$invalidInput = 0;} #Input is valid, Exit
            Default {Write-Host "I do not recognize that answer, please put 64 or 32 as your answer" -ForegroundColor Red} #Bad Input
        }
    } #End User Prompt

    #Begin adding the 32 Bit Operations, this is required no matter what
    $hive1 = Modify-RegHive -hivePath HKLM:\SOFTWARE\Microsoft\ -hiveName Cryptography
    $hive2 = Modify-RegHive -hivePath HKLM:\SOFTWARE\Microsoft\Cryptography\ -hiveName WinTrust
    $hive3 = Modify-RegHive -hivePath HKLM:\SOFTWARE\Microsoft\Cryptography\WinTrust\ -hiveName Config
    $32bit = Modify-RegValue -regPath "HKLM:\SOFTWARE\Microsoft\Cryptography\WinTrust\Config" -regName "EnableCertPaddingCheck" -regValue "1" -regProperty String

    #If this is a 64 bit system, dump the rest as well
    if($bitFlag -eq 1){
        
        $hive4 = Modify-RegHive -hivePath HKLM:\SOFTWARE\Wow6432Node\Microsoft\ -hiveName Cryptography
        $hive5 = Modify-RegHive -hivePath HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\ -hiveName WinTrust
        $hive6 = Modify-RegHive -hivePath HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\WinTrust\ -hiveName Config
        $64bit = Modify-RegValue -regPath "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\WinTrust\Config" -regName "EnableCertPaddingCheck" -regValue "1" -regProperty String
    }


    #Completion Check, this is a really dumb an inefficient way of doing this. I dont care.
    if($hive1 -eq $false){$errCount++}
    if($hive2 -eq $false){$errCount++}
    if($hive3 -eq $false){$errCount++}
    if($hive4 -eq $false){$errCount++}
    if($hive5 -eq $false){$errCount++}
    if($hive6 -eq $false){$errCount++}
    if($32Bit -eq $false){$errCount++}
    if($64Bit -eq $false){$errCount++}

    #If we even go above 0, throw one final alert
    if($errCount -gt 0){Log-Alert -message "One or more processes failed! Check Alerts that may have been generated or Logs! Failed with an Error Count of $errCount" -severity 4}


}#User Says no, or anything else for that matter
else{ Write-Host "Returning to deployer, user has declined implementation of the fix as this device is not a server" -ForegroundColor Yellow}

#Pause before Leaving 
Pause
