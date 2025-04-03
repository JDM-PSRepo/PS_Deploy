# This script should be run using system context

# Unjoin devices from Entra ID
dsregcmd.exe /leave /debug

# Remove cached Intune certificates
Get-ChildItem 'Cert:\LocalMachine\My\' | Where-Object { 
    $_.Issuer -match "MS-Organization-Access|MS-Organization-P2P-Access \[\d+\]" 
} | ForEach-Object { 
    Remove-Item -Path $_.PSPath -Force 
}
