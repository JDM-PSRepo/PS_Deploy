# Run this script using system context - it will automatically convert to user context

Install-Module RunAsUser

$scriptblock = { # THE FOLLOWING NEEDS TO BE RAN USING USER CONTEXT WITH STANDARD PERMISSIONS - NOT WITH ELEVATED PERMISSIONS OR SYSTEM CONTEXT

# Force close Office apps
# Define the list of Office processes to force close
$officeProcesses = @("OUTLOOK", "WINWORD", "POWERPNT", "EXCEL", "ONENOTE", "Teams", "olk", "ms-teams")

# Iterate through each process and force close if running
foreach ($processName in $officeProcesses) {
    $runningProcess = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($runningProcess) {
        $runningProcess | ForEach-Object {
            $_.Kill()
        }
    }
}


# Force close OneDrive and unlink OneDrive account
Get-Process onedrive | Stop-Process -Force
Start-Sleep 5

$regPath = Join-Path -Path 'HKCU:\Software\Microsoft\OneDrive\Accounts' -ChildPath 'Business*' -Resolve
if($regPath){
    Remove-Item -Path "$regPath" -Recurse -Force
}

# RESET OFFICE ACTIVATION STATE
# https://docs.microsoft.com/en-us/office/troubleshoot/activation/reset-office-365-proplus-activation-state

$Urls = @(
	"https://download.microsoft.com/download/e/1/b/e1bbdc16-fad4-4aa2-a309-2ba3cae8d424/OLicenseCleanup.zip",
	"https://download.microsoft.com/download/f/8/7/f8745d3b-49ad-4eac-b49a-2fa60b929e7d/signoutofwamaccounts.zip",
	"https://download.microsoft.com/download/8/e/f/8ef13ae0-6aa8-48a2-8697-5b1711134730/WPJCleanUp.zip"
	)

$BaseExtractPath = "C:\Temp\o365reset\"		

# create folder anyway
New-Item -ItemType Directory -Path $BaseExtractPath -Force

# download and extract files
foreach ($Url in $Urls) {
	$DownloadZipFile = $BaseExtractPath + $(Split-Path -Path $Url -Leaf)
	$ExtractPath = $BaseExtractPath
	write-host "Downloading: $Url"
	Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile
	$ExtractShell = New-Object -ComObject Shell.Application
	$ExtractFiles = $ExtractShell.Namespace($DownloadZipFile).Items()
	$ExtractShell.NameSpace($ExtractPath).CopyHere($ExtractFiles)	
}

# check if the files exist after extract
write-host "Test OLicenseCleanup.vbs: " -nonewline; Test-Path $BaseExtractPath\OLicenseCleanup\OLicenseCleanup.vbs
write-host "Test signoutofwamaccounts.ps1: " -nonewline; Test-Path $BaseExtractPath\signoutofwamaccounts.ps1
write-host "Test WPJCleanUp.cmd: " -nonewline; Test-Path $BaseExtractPath\WPJCleanUp\WPJCleanUp\WPJCleanUp.cmd

# execute each script
Set-Location $BaseExtractPath
write-host "Execute OLicenseCleanup.vbs: "
.\OLicenseCleanup\OLicenseCleanup.vbs -NoNewWindow -PassThru
Start-Sleep 3
write-host "Execute signoutofwamaccounts.ps1: "
.\signoutofwamaccounts.ps1 -NoNewWindow -PassThru
Start-Sleep 3
write-host "Execute WPJCleanUp.cmd: "
.\WPJCleanUp\WPJCleanUp\WPJCleanUp.cmd -NoNewWindow -PassThru
Start-Sleep 3

Set-Location "C:\Windows\System32"
Remove-Item $BaseExtractPath -Recurse -Confirm:$False

Get-ChildItem $env:LOCALAPPDATA\Microsoft\Outlook\* -Include *.ost, *.nst, *.pst | Remove-Item
Set-Location HKCU:
$Profiles = Get-ChildItem 'HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\Profiles' |foreach {
    Get-ChildItem $_.Name |foreach {
        Get-ChildItem -Path $_.Name
    } 
}
 
foreach($Profile in $Profiles){
    try{
        $AccountName = Get-ItemPropertyValue -Path $Profile.Name -Name 'Account Name' -ErrorAction Stop
        if($AccountName -like '*@*'){
            'HKCU:\' + ($Profile.Name.Split('\')[1..7] -join '\') | Remove-Item -Recurse
        }
    }catch{
        Continue
    }
}

#Clear Teams (classic) cache
try{
Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\*" | Remove-Item -Recurse -Force -Confirm:$false
 
}
catch{
echo $_
}

#Clear Teams (new) cache
 try{
    Remove-Item -Path "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe" -Recurse -Force -Confirm:$false
  }
catch{
echo $_
}
 }

# Save the scriptblock contents to a file
$scriptblockContent = @"
`$scriptblock = $($scriptblock.ToString())
"@
Set-Content -Path "C:\T2T Migration Cleanup Script.ps1" -Value $scriptblockContent

invoke-ascurrentuser -scriptblock $scriptblock
