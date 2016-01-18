#Import the module
Import-Module SQLPS -DisableNameChecking

#Get a listing of all the commands
Get-Command -Module SQLPS 

#We'll first check a simple cmdlet, Get-SqlDatabase
$db_cmdlet = Get-SqlDatabase -ServerInstance localhost -Name msdb

$db_cmdlet
$db_cmdlet | Get-Member 

#Note, this is actually the same as acquiring the object from the provider
$db_provider = Get-Item 'SQLSERVER:\SQL\localhost\DEFAULT\Databases\msdb'

$db_provider
$db_provider | Get-Member

#Both objects are the same because everything uses the SMO
$db_cmdlet
$db_provider

$db_cmdlet.GetType()
$db_provider.GetType()

#Let's look at sqlcmd versus Invoke-SQLCmd
$sql = 'SELECT name,recovery_model_desc FROM sys.databases;'

$out_sqlcmd = sqlcmd -S localhost -Q $sql
$out_invsql = Invoke-Sqlcmd -ServerInstance localhost -Query $sql

#Compare the two outputs
$out_sqlcmd
$out_invsql

#Now look at the kind of objects they are
$out_sqlcmd | Get-Member
$out_invsql | Get-Member

#Because Invoke-SqlCmd outputs datarow objects, it allows us more flexibility
$out_invsql.name
$out_invsql | Sort-Object name

#For more information, look at the help file.
Get-Help Invoke-Sqlcmd -ShowWindow

#Now let's look at the Backup-SqlDatabase cmdlet
Get-Help Backup-SqlDatabase -ShowWindow

#This gives us a handy way to backup databases
#Now we'll create a quick backup script
Backup-SqlDatabase -ServerInstance localhost -Database msdb -BackupFile 'C:\PowershellLab\msdb.bak' -Script

#We can combine this to backup a list of databases
$dbs = @('master','model','msdb')
$dbs | ForEach-Object {Backup-SqlDatabase -ServerInstance localhost -Database $_ -BackupFile "C:\PowershellLab\$_.bak" -Script}