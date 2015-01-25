#Restore module
#Download module - https://github.com/MikeFal/PowerShell
import-module RestoreAutomation
Get-Command -Module RestoreAutomation
Get-Help New-Restore
Get-Help New-Restore -Full
Get-Help New-Restore -Examples

$srv = "localhost"
New-Restore -dir "C:\DBFiles\backups\restoredemo\" -server $srv  -database "restoredemo_copy"

Invoke-Sqlcmd -ServerInstance $srv -Query "drop database restoredemo_copy"
New-Restore -dir "C:\DBFiles\backups\restoredemo\" -server $srv -database "restoredemo_copy" -newdata "C:\DBFiles\restoredemo_copy" -newlog "C:\DBFiles\restoredemo_copy" -Execute

#Migrate database
Get-Help Sync-DBUsers
$db = "restoredemo_migration"
$srv = "localhost\ALBEDO"
New-Restore -dir "C:\DBFiles\backups\restoredemo" -server "localhost\ALBEDO" -database $db -newdata "C:\DBFiles\backups\migration" -newlog "C:\DBFiles\backups\migration" -Execute
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
$db = "CorruptMe"
$srv = "localhost"
New-Restore -server $srv -database $db -dir "C:\DBFiles\backups\corruptme" -newdata "C:\DBFiles\Data" -newlog "C:\DBfiles\Log" -Execute

Get-DBCCCheckDB -server $srv -database $db

#messy, let's try that again
Get-DBCCCheckDB -server $srv -database $db | Select level,messagetext,repairlevel | ft -AutoSize

#If we want the full DBCC check
Get-DBCCCheckDB -server $srv -database $db -Full | where {$_.level -gt 10} | Select messagetext,repairlevel | ft