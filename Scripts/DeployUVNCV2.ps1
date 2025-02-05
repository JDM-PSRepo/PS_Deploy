#DeployUVNCv2 by James Mester | Deploys UVNC Server

#===========[\/\/\/\/\/\/\/\/\/] <----YOU NEED TO MODIFY THIS SECTION OF THE CODE TO CHANGE THE FILE NAME
$vncFile = "UVNC_1420_Setup.exe"
#===========[/\/\/\/\/\/\/\/\/\] <----YOU NEED TO MODIFY THIS SECTION OF THE CODE TO CHANGE THE FILE NAME

#Variables
$success = $false
$install = $false
$complete = $false

#Clear Log
$Error.Clear()

#Alert user
Log-Alert -message "Launching DeployUVNC Version 2 | Begin retrieving payload" -severity -2

#Pull File from orbit | If it fails scream unconctrollably
try{Copy-item -Path PS_Deploy:\DeployFiles\UVNC\ -Destination C:\UVNC_Staging\ -recurse;$success = $true} #True gets set here by the way
catch {Log-Alert -message "WARNING! PAYLOAD RETREIVAL FAILED!!! DID THE FILE GET DELETED OR THE FILE NAME CHANGED?" -severity 5}

#If the pull down was successful, send it
if($success){
    
    #Success, begin install
    Log-Alert -message "Payload was snagged, beginning silent installation" -severity -2

    #Lets try this installation
    try{
        #Attempt installation
        Start-Process "C:\UVNC_Staging\$vncFile" -Args "/loadinf=C:\UVNC_Staging\SilentDeploy.inf /VerySilent /NoRestart" -Wait -NoNewWindow #Silently Install the file using the provided inf
        $install = $true #Even if the config fails we should be fine, the point is the installer is in place
        #Dump a pre-configured ini config file to make life easier
        try{Copy-item -Path "C:\UVNC_Staging\ultravnc.ini" -Destination "C:\Program Files\uvnc bvba\UltraVNC";} #Try Copy
        catch{Log-Alert -message "Something went wrong! The INI config file didnt get loaded in, but the install was successful. Did the file get changed or deleted? You may need to manually add it for this to work" -severity 2} #Moderate error if fail
        
    }

    #Throw an error
    catch{Log-Alert -message "Something went wrong with the installation. Either a file wasnt properly loaded, or you dont have permissions to do this!" -Severity 4}

    #If install passed, mod the registry
    if($install){
        #Light Nudge of what the intent is here.
        Log-Alert -message "Install Done, Modifying Registry to Accept MS Login Users" -severity -2
        #Build the ORL Hive, if success: Continue
        if(Modify-RegHive -hivePath HKLM:\SOFTWARE -hiveName ORL){
            #Build the WinVNC3 Hive, if success: Continue
            if(Modify-RegHive -hivePath HKLM:\SOFTWARE\ORL -hiveName WinVNC3){
                #Finally: Dump the needed registry value. DO NOT SCREW WITH THIS OR YOU BREAK EVERYTHING
                $complete = Modify-RegValue -regPath HKLM:\SOFTWARE\ORL\WinVNC3 -regName "ACL" -regValue ([byte[]](0x02,0x00,0x2C,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x24,0x00,0x03,0x00,0x00,0x00,0x01,0x05,0x00,0x00,0x00,0x00,0x00,0x05,0x15,0x00,0x00,0x00,0x7D,0x11,0x89,0xC5,0x59,0x53,0x58,0xEC,0xAF,0x4C,0xB8,0xBD,0x00,0x02,0x00,0x00))
            }
            #WinVNC3 Hive Creation Failure
            else{
                Log-Alert -message "Creation of WinVNC3 Hive Failed. Process is aborted" -severity 4
            }
        }
        #ORL Hive Creation Failure
        else{
            Log-Alert -message "Creation of ORL Hive Failed. Process is aborted" -severity 4
        }

    }
    #Installation Failure Error
    else{
        Log-Alert -message "Bypassing Registry Edit due to installation failure" -severity 2
    }
}
#If the payload fails, put the alert and go from there
else{
    Log-Alert -message "Payload failure. Installation and Registry Editing have been entirely bypassed" -severity 4
}

#The complete variable can only be set true if all others made it through, otherwise throw an error and complete
if($complete){Log-Alert -message "Process is complete!" -severity -2}
else{Log-Alert -message "One or more processes failed!" -severity 4}