#DeployWinVerifyTrust.ps1 | This script will deploy the registry values needed to activate the Cert Pad Check on machines, also: GET OFF MY LAWN!!!!
#Built by James Mester

#Variables
$inputResponse
$invalidInput = 1
$bitFlag = 0
$failureFlag = 0

$Error.Clear() #Shouldnt be needed, but this clears the local shell's stored errors in case somebody was mucking around before they run the script

try{
    #Swap to the PS_Deploy Folder directly
    cd PS_Deploy:\ #-ErrorAction stop
}

#If that fails, scream from the rooftops and nope out
catch{
    Write-Host "Something went horribly wrong! Was unable to bind the PS_Deploy Folder on the network! This is pretty bad news. Did the file get renamed?!" -ForegroundColor DarkRed
    Write-Host "Terminating Shell, cannot proceed!" -ForegroundColor DarkRed
    pause #Hold temporarily before killing the shell
    #Disconnect the Drive
    cd C:\
    remove-psdrive "PS_Deploy" -Force -ErrorAction SilentlyContinue
    #Kill the instance
    exit
}

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

    
    #Check to see if this file is even there, if not then we're gonna have to create it
    if(-NOT (Test-Path HKLM:\SOFTWARE\Microsoft\Cryptography\WinTrust\Config)){
            
            #We're gonna try and do this properly, Because we dont mess with the registry by any means possible
            try{
                #Assumption: We know the Software\Microsoft hive will always exist, so we'll create the Cryptography and WinTrust folders silently, if the final hive cannot be created then we had an error, if it exists we never run this code
                New-Item -Path HKLM:\SOFTWARE\Microsoft\ -Name Cryptography -ErrorAction SilentlyContinue | Out-Null
                New-Item -Path HKLM:\SOFTWARE\Microsoft\Cryptography\ -Name WinTrust -ErrorAction SilentlyContinue | Out-Null
                New-Item -Path HKLM:\SOFTWARE\Microsoft\Cryptography\WinTrust\ -Name Config -ErrorAction stop | Out-Null
            }
            catch{
                Write-Host "Seems that there was an error trying to create the Registry Hive for the 32-bit node. Normally this is a permissions issue, expect additional errors" -ForegroundColor DarkRed
            }
        }
            

    #Does it exist already?
    try{ 
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\WinTrust\Config" -Name "EnableCertPaddingCheck" -Value "1" -PropertyType String -ErrorAction stop | Out-Null
        Write-Host "Successfully Created the EnableCertPaddingCheck 32-Bit Config" -ForegroundColor Green
        }

    #Try block errors out if it exists already, run the catch block. 
    catch{

        #Nested Try Catch, I'm sorry dad
        try{ 
            #Creation Failed, Write instead
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\WinTrust\Config" -Name "EnableCertPaddingCheck" -Value "1" -ErrorAction stop
            Write-Host "Successfully Set the EnableCertPaddingCheck 32-Bit Config to 1" -ForegroundColor Green
            }

        #WHAT DID YOU DO!?
        catch{
            Write-Host "Fatal Error: System attempted to Set the property for HKLM:\SOFTWARE\Microsoft\Cryptography\WinTrust\Config, this can only happen if the Creation AND the Assignment Failback failed. Meaning something HORRIBLE has occured here" -ForegroundColor DarkRed
            Write-Host "Writing WinVerifyError.log to the PS_Deploy Folder. Remember to delete this later" -ForegroundColor DarkRed
            $failureFlag = 1
            $Error >> PS_DEPLOY:\Logs\WinVerifyError.log #Dump Error Var to Log
        }
    } #End Base 32 Implementation

    #64 Bit Conditional
    if($bitFlag -eq 1){

        #Check to see if this file is even there, if not then we're gonna have to create it
        if(-NOT (Test-Path HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\Config)){
        
            #We're still doing this properly so that in case something blows up, its handled correctly
            try{
                #Assumption: We know the Software\Wow6432\Microsoft hive will always exist, so we'll create the Cryptography and WinTrust folders silently, if the final hive cannot be created then we had an error, if it exists we never run this code
                New-Item -Path HKLM:\SOFTWARE\Wow6432Node\Microsoft\ -Name Cryptography -ErrorAction SilentlyContinue | Out-Null
                New-Item -Path HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\ -Name Wintrust -ErrorAction SilentlyContinue | Out-Null
                New-Item -Path HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\ -Name Config -ErrorAction stop | Out-Null
            }

            #Something went wrong, which shouldnt happen but if it does we have this
            catch{
                Write-Host "Seems that there was an error trying to create the Registry Hive for the 64-bit node. Normally this is a permissions issue, expect additional errors" -ForegroundColor DarkRed
            }
            
        }

        #Attempt to add the Property if it exists
        try{ 
        
            #If it exists this throws a fatal error, catch and set
            New-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\Config" -Name "EnableCertPaddingCheck" -Value "1" -PropertyType String -ErrorAction stop | Out-Null
            Write-Host "Successfully Created the EnableCertPaddingCheck 64-Bit config" -ForegroundColor Green
            }

        #Try block errors out if it exists already, run the catch block. 
        catch{

            #Nested Try Catch, I'm sorry mom
            try{ 
                
                #Set the property
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\Config" -Name "EnableCertPaddingCheck" -Value "1" -ErrorAction stop | Out-Null
                Write-Host "Successfully Set the EnableCertPaddingCheck 64-Bit Config to 1" -ForegroundColor Green
            }

            #WHAT DID YOU DO!?
            catch{

                #This block usually only runs when the file path doesnt exist or the permissions arent there
                Write-Host "Fatal Error: System attempted to Set the property for HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\Config, this can only happen if the Creation AND the Assignment Failback failed. Meaning something HORRIBLE has occured here" -ForegroundColor DarkRed
                Write-Host "Writing WinVerifyError.log to the PS_Deploy Folder. Remember to delete this later" -ForegroundColor DarkRed
                $failureFlag = 1
                $Error >> PS_DEPLOY:\Logs\WinVerifyError.log #Dump Error Var to Log 
            }
        }
    } #End 64 Bit Conditional

    #Goodbye Message depending if the process completed with or without errors
    if($failureFlag -eq 0){Write-Host "Work should now be complete, returning to deployer. Remember to restart for these changes to take effect!!!" -ForegroundColor Green} #Success
    else{Write-Host "One or more operations did not complete successfully, please check the WinVerifyError.log file within PS_DEPLOY on the networkshare for further details" -ForegroundColor Red} #failureFlag was tripped

}

#User Says no
elseif($inputResponse -eq "N"){ Write-Host "Returning to deployer, user has declined implementation of the fix as this device is not a server" -ForegroundColor Yellow}

#Pause before Leaving 
Pause
