#Create working directory before you go into the provider
cd C:\
if((Test-Path 'C:\PowershellLab') -eq $false){New-Item -ItemType Directory 'C:\PowershellLab'}

#Load the SQLPS module
Import-Module SQLPS -DisableNameChecking

#you should be in the SQLSERVER:\ path now
dir SQLSERVER:\

#Let's look at your local host
cd SQLSERVER:\SQL\localhost\DEFAULT
dir

#Look at your databases
dir databases
dir databases -Force

#Review the object type for your databases
#There are a lot of methods and properties, but take some time tosee what is available
dir databases | Get-Member

#Lets look at some of the other properties
dir databases | Select-Object name,LastBackupDAte,RecoveryModel,PrimaryFilePath,owner

#Lets script out the logins using the provider
dir logins | ForEach-Object {$_.Script() | Out-File 'C:\PowershellLab\logins.sql' -Append}
notepad 'C:\PowershellLab\logins.sql'

#Cleanup
cd C:\
Remove-Item 'C:\PowershellLab' -Recurse -Confirm