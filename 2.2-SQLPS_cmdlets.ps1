#Using the cmdlets

Get-Command -Module SQLPS
Get-Command -Module SQLPS | Measure-Object

Get-SqlDatabase -ServerInstance PICARD -Name AdventureWorks2014

Get-SqlInstance -MachineName PICARD

Backup-SqlDatabase -ServerInstance PICARD -Database AdventureWorks2014  -BackupFile 'C:\TEMP\AdventureWorks2014.bak' -Initialize -CopyOnly -Script

Backup-SqlDatabase -ServerInstance PICARD -Database AdventureWorks2014  -BackupFile 'C:\TEMP\AdventureWorks2014.bak' -Initialize -CopyOnly

#Lets combine the Backup-SQLDatabase with the provider
#gonna clean up the directory first
dir 'C:\Backups' -Recurse | rm -Recurse -Force

#nothing up my sleeve
dir 'C:\Backups' -recurse

#now let's use it to run all our systemdb backups
cd C:\
$servers= @((dir "SQLSERVER:\SQLRegistration\Central Management Server Group\PICARD").Name)
$servers += 'PICARD'

foreach($server in $servers){
    
    $dbs = dir SQLSERVER:\SQL\$server\DEFAULT\DATABASES -Force | Where-Object {$_.IsSystemObject -eq $true -and $_.name -ne 'tempdb'}
    $pathname= "\\PIKE\Backups\"+$server.Replace('\','_')
    if(!(test-path $pathname)){New-Item $pathname -ItemType directory } 
    $dbs | ForEach-Object {Backup-SqlDatabase -ServerInstance $server -Database $_.name -BackupFile "$pathname\$($_.name).bak" -Initialize}
}

dir 'C:\Backups' -recurse


#Let's look at Invoke-SqlCmd
$sql=@'
SET NOCOUNT ON
select sp.name,count(1) db_count
from sys.server_principals sp
join sys.databases d on (sp.sid = d.owner_sid)
group by sp.name
'@

$sqlcmdout = sqlcmd -S PICARD -d tempdb -Q $sql
$invokesqlout = Invoke-Sqlcmd -ServerInstance PICARD -Database tempdb -Query $sql

$sqlcmdout
$invokesqlout

$sqlcmdout[0].GetType()
$invokesqlout[0].GetType()

$invokesqlout | gm

$invokesqlout.name