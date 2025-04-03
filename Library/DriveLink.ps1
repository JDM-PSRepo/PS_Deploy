#DriveLink.ps1 v1.0 | This is the bridge between new computers and the File Server Link.

#Doublecheck line of sight with file server
if(Test-Connection ATCH-GRFS01 -ErrorAction Ignore){

    #File contains all the drive information and their login, itemize as an array of strings
    [string[]]$userIngest = Get-Content -Path C:\UserFile.txt
    $i = 0 #Zero this out so shit doesnt break later

    $userPass = Read-Host -Prompt 'Enter your Airtech Password' -AsSecureString
    $UserCredToken = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userIngest[0], $userPass

    #Iterate through the array, every odd index is the letter, even indexes are the path
    for($i = 1; $i -le $userIngest.Length-1; $i+=2){
            
        #Add Drive accordingly
        New-PSDrive -Name $userIngest[$i] -PSProvider "FileSystem" -Credential $userCredToken -Root $userIngest[$i+1] -Persist -Scope Global -ErrorAction Continue
    }

    Write-Host "Process Complete - It can take some time before your drives appear. Please wait 5-10 minutes"
    }
else {
    
    Write-host "File server test failed! Are you connected to a company network?" -ForegroundColor DarkRed
}
