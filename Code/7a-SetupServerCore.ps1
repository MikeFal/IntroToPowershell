<#
    Before running this, you should have a server core machine
    built and configured with name and networking.
#>
rename-computer 'RIKER'
restart-computer

#join domain 
$pw = 'vanh0uten!42' | convertto-securestring -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ('SDF\Administrator',$pw)
Add-Computer -DomainName 'SDF.local' -Credential $cred
restart-computer

#POST SERVER INIT, BASE CONFIGURATION
#configure powershell as default shell

#This is part of my base image, you would need to do this for your own environment
#Write-Warning "Set Powershell as default shell"
#set-itemproperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\WinLogon" shell 'powershell.exe -noexit -command "$psversiontable;import-module ServerManager"'

#Install .Net Framework
"Install .Net Libraries"
Install-WindowsFeature NET-Framework-Core -Source D:\sources\sxs

#update firewall
New-NetFirewallRule -DisplayName "Allow SQL Server" -Direction Inbound –LocalPort 1433 -Protocol TCP -Action Allow

#Create SQL Data directories
Write-Host 'Create default database directories'
New-Item -ItemType Directory -Path C:\DBFiles\Data -Force |ft
New-Item -ItemType Directory -Path C:\DBFiles\Log -Force | ft
New-Item -ItemType Directory -Path C:\DBFiles\TempDB -Force | ft

#create service account if you want a local account, we will use a domainaccount
#Write-Host "Create Local SQL Server Service Account"
#$account="sqlsvc"
#$pw="5qlp@55w0rd"

#$comp=[ADSI] "WinNT://$ENV:ComputerName"
#$comp | Get-Member
#$user=$comp.Create("User",$account)
#$user.SetPassword($pw)

#Set service account so user can't change password and password never expires
#$user.UserFlags = (65536+64)
#$user.SetInfo()

#install SQL Server
\\HIKARUDC\InstallFiles\SQLServer\SQL2014\setup.exe /CONFIGURATIONFILE='\\HIKARUDC\InstallFiles\SQLServer\\SQL2014_Core.ini'