#Restore module
#Download module - https://github.com/MikeFal/PowerShell
import-module RestoreAutomation
Get-Command -Module RestoreAutomation
Get-Help New-Restore
Get-Help New-Restore -Full
Get-Help New-Restore -Examples

$srv = "PICARD"
$db='dummy2'
New-Restore -dir "\\PICARD\backups\dummy" -server $srv  -database $db

Invoke-Sqlcmd -ServerInstance $srv -Query "if exists (select 1 from sys.databases where name = '$db') drop database $db"
New-Restore -dir "\\PICARD\backups\dummy" -server $srv -database "dummy2" -newdata "C:\DBFiles" -newlog "C:\DBFiles" -Execute

#Migrate database
Get-Help Sync-DBUsers
$db = "dummy_migration"
$srv = "PICARD\WESLEY"
New-Restore -dir "\\PICARD\backups\dummy" -server 'PICARD\WESLEY' -database $db -newdata "C:\DBFiles\migration" -newlog "C:\DBFiles\migration" -Execute
Invoke-Sqlcmd -ServerInstance $srv -Query "ALTER AUTHORIZATION ON database::[$db] TO [sa]"
Sync-DBUsers -server $srv -database $db

#Create the logins
$logins=Sync-DBUsers -server $srv -database $db

foreach($login in $logins.name){
    Invoke-Sqlcmd -ServerInstance $srv -Query "CREATE LOGIN [$login] WITH PASSWORD='P@55w0rd'"
}

Sync-DBUsers -server $srv -database $db

#Restore testing
Get-Help Get-DBCCCheckDB
$srv = "PICARD"
$db='CorruptMe2'
Invoke-Sqlcmd -ServerInstance $srv -Query "if exists (select 1 from sys.databases where name = '$db') drop database $db"
New-Restore -server $srv -database $db -dir "\\PICARD\backups\corruptme" -newdata "C:\DBFiles\" -newlog "C:\DBfiles\" -Execute

Get-DBCCCheckDB -server $srv -database $db

#messy, let's try that again
Get-DBCCCheckDB -server $srv -database $db | Select level,messagetext,repairlevel | ft -AutoSize

#If we want the full DBCC check
Get-DBCCCheckDB -server $srv -database $db -Full | where {$_.level -gt 10} | Select messagetext,repairlevel | ft
