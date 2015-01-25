<#
    Before running this, you should have a server core machine
    built and configured with name and networking.
#>

#POST SERVER INIT, BASE CONFIGURATION
#configure powershell as default shell
Write-Warning "Set Powershell as default shell"
set-itemproperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\WinLogon" shell 'powershell.exe -noexit -command "$psversiontable;import-module ServerManager"'

#Install .Net Framework
"Install .Net Libraries"
Install-WindowsFeature NET-Framework-Core

#update firewall
Write-Warning "Disable the firewall for DEMONSTRATION PURPOSES ONLY"
Set-NetFirewallProfile -Profile * -Enabled False

#Could also use netsh if you want
#netsh firewall set opmode disable

#Create SQL Data directories
Write-Host 'Create default database directories'
New-Item -ItemType Directory -Path C:\DBFiles\Data -Force |ft
New-Item -ItemType Directory -Path C:\DBFiles\Log -Force | ft
New-Item -ItemType Directory -Path C:\DBFiles\TempDB -Force | ft

#create service account
Write-Host "Create Local SQL Server Service Account"
$account="sqlsvc"
$pw="5qlp@55w0rd"

$comp=[ADSI] "WinNT://$ENV:ComputerName"
$comp | Get-Member
$user=$comp.Create("User",$account)
$user.SetPassword($pw)

#Set service account so user can't change password and password never expires
$user.UserFlags = (65536+64)
$user.SetInfo()

#reboot
Restart-Computer

#AFTER THE RESTART, INSTALL
cd \\HIKARU\InstallFiles\SQL2014
.\setup.exe /CONFIGURATIONFILE=SQL2014_Core.ini