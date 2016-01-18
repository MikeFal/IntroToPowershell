<#
    Before running this, you should have a server core machine
    built and configured with name and networking.
#>
$pw='vanh0uten!42' | ConvertTo-SecureString -AsPlainText -force
$cred = New-Object System.Management.Automation.PSCredential ('STARFLEET\Administrator',$pw)
Add-Computer -DomainName 'starfleet.com' -Credential $cred -NewName WORF -Restart

#POST SERVER INIT, BASE CONFIGURATION
#configure powershell as default shell

#This is part of my base image, you would need to do this for your own environment
#Write-Warning "Set Powershell as default shell"
#set-itemproperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\WinLogon" shell 'powershell.exe -noexit -command "$psversiontable;import-module ServerManager"'

#Install .Net Framework
"Install .Net Libraries"
Add-WindowsFeature NET-Framework-Core -Source D:\sources\sxs

#update firewall
New-NetFirewallRule -DisplayName "Allow SQL Server" -Direction Inbound –LocalPort 1433 -Protocol TCP -Action Allow

#Create SQL Data directories
Write-Host 'Create default database directories'
New-Item -ItemType Directory -Path C:\DBFiles\Data -Force |ft
New-Item -ItemType Directory -Path C:\DBFiles\Log -Force | ft
New-Item -ItemType Directory -Path C:\DBFiles\TempDB -Force | ft

#install SQL Server
E:\setup.exe /CONFIGURATIONFILE='\\PIKE\InstallFiles\SQL2014_Core.ini'