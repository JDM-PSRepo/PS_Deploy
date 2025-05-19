#DriveLink.ps1 v1.0 | This is the bridge between new computers and the File Server Link.

#TODO: Render this system generic and see if theres a way we can sweep the drives completely. Maybe even store and check for a secure string since Secure Strings are device dependant?
$filePath = "C:\UserDriveFile.txt"
#File contains all the drive information and their login, itemize as an array of strings
[string[]]$dataIngest = Get-Content -Path $filePath

$bailout = 0

#Doublecheck line of sight with file server
if(Test-Connection $dataIngest[0] -ErrorAction Ignore){

	while($bailout -eq 0){
		#Pull information for the local login
		$userPass = Read-Host -Prompt 'Enter your Local Password' -AsSecureString
		$UserCredToken = New-Object -TypeName System.Management.Autom+ation.PSCredential -ArgumentList $dataIngest[1], $userPass
		
		#Iterate through the array, every odd index is the letter, even indexes are the path
		for($i = 2; $i -le $dataIngest.Length-1; $i+=2){
				
			try{	
			#Add Drive accordingly
			New-PSDrive -Name $dataIngest[$i] -PSProvider "FileSystem" -Credential $userCredToken -Root $dataIngest[$i+1] -Persist -Scope Global -ErrorAction Stop
			}
			#Throws if Username or Password is wrong
			catch [System.ComponentModel.Win32Exception]{
				Log-Alert "An Error has occured: Username or Password was likely incorrect. Was the UserDriveFile correctly edited? User is : $dataIngest[1]" -severity 3
				break
			}
			catch{
				Log-Alert "Warning: An unknown error has occured. Please check the logs for additional information" -severity 4
			}
		}
		

		Write-Host "Process Complete - Please wait 1-2 minutes for the drives to appear in your File Explorer"
	}
}
else {
    
    Write-host "File server test failed! Are you connected to a company network?" -ForegroundColor DarkRed
}
