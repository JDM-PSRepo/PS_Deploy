#RemoveWinVerifyTrust.ps1 | This script will edit the registry values needed to deactivate the Cert Pad Check on machines, also: GET OFF MY LAWN!!!!
#Built by James Mester

#Variables
$inputResponse
$invalidInput = 1
$bitFlag = 0
$failureFlag = 0

$Error.Clear() #Shouldnt be needed, but this clears the local shell's stored errors in case somebody was mucking around before they run the script

try{
    #Swap to the PS_Deploy Folder directly
    cd PS_Deploy:\ -ErrorAction stop
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

#Welcome user, then promptly yell at them
Write-Host "Welcome to the Remover for WinVerifyTrust's Reg Edit. This is intended to rollback the fix for CVE-2013-3900's Security Vunderability" -ForegroundColor Yellow
Write-Host "WARNING! THIS REMOVER SHOULD ONLY BE RUN AGAINST SERVERS WHICH HAVE THE FIX DEPLOYED. ARE YOU SURE THAT THIS IS A SERVER WHICH SHOULD REASONABLY SEE ITS DEPLOYMENT? (Y/N)" -ForegroundColor DarkRed

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

    #Nested Try Catch, I'm sorry dad
    try{ 
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\WinTrust\Config" -Name "EnableCertPaddingCheck" -Value "" -ErrorAction Stop | Out-Null
        Write-Host "Success, 32-Bit node set to Null" -ForegroundColor Green
        }

    #Doesnt Exist, throw error (and hands)
    catch{
        Write-Host "Fatal Error: System attempted to Set the property for HKLM:\SOFTWARE\Microsoft\Cryptography\WinTrust\Config but could not, this usually implies the fix is NOT implemented on this device" -ForegroundColor DarkRed
        Write-Host "Writing RemoveWinVerifyError.log to the PS_Deploy Folder. Remember to delete this later" -ForegroundColor DarkRed
        $failureFlag = 1
        $Error >> PS_DEPLOY:\Logs\RemoveWinVerifyError.log #Dump Error Var to Log Folder
    }

    #64 Bit Conditional
    if($bitFlag -eq 1){

       
        #Nested Try Catch, I'm sorry mom
        try{ 
            #Set Value to 0 to negate the flag
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\Config" -Name "EnableCertPaddingCheck" -Value "" -ErrorAction Stop | Out-Null
            Write-Host "Success, 64-Bit node set to Null" -ForegroundColor Green
        }

        #Doesnt Exist, throw error (and Hanz)
        catch{
            Write-Host "Fatal Error: System attempted to Set the property for HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\Config but could not, this usually implies the fix is NOT implemented on this device" -ForegroundColor DarkRed
            Write-Host "Writing RemoveWinVerifyError.log to the PS_Deploy Folder. Remember to delete this later" -ForegroundColor DarkRed
            $failureFlag = 1
            $Error >> PS_DEPLOY:\Logs\RemoveWinVerifyError.log #Dump Error Var to Log Folder
        }
    }

    #Goodbye Message depending if the process completed with or without errors
    if($failureFlag -eq 0){Write-Host "Work should now be complete, returning to deployer. Remember to restart the device so that changes may take effect" -ForegroundColor Green} #Success
    else{Write-Host "One or more operations did not complete successfully, please check the WinVerifyError.log file within PS_DEPLOY on the networkshare for further details" -ForegroundColor Red} #failureFlag was tripped

}

#User Says no
elseif($inputResponse -eq "N"){ Write-Host "Returning to deployer, user has declined implementation of the fix as this device is not a server" -ForegroundColor Yellow}

#Pause before Leaving 
Pause
