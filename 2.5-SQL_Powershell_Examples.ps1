#Add a list of servers to your CMS
cd 'SQLSERVER:\SQLRegistration\Central Management Server Group\PICARD'
#remove to demo
if (Test-Path $(Encode-Sqlname KIRK)){Remove-Item KIRK}
if (Test-Path $(Encode-Sqlname SPOCK)){Remove-Item SPOCK}

$servers = @('KIRK','SPOCK')

foreach ($server in $servers)
{
	
	if (!(Test-Path $(Encode-Sqlname $server))) 
	{
        New-Item $(Encode-Sqlname $server) `
            -itemtype registration `
            -Value “server=$server;integrated security=true;name=$server” 
        }
}

dir 'SQLSERVER:\SQLRegistration\Central Management Server Group\PICARD'

#Configure SQL Server with the SMO:
$smosrv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') 'PICARD'

$smosrv.Configuration.MaxServerMemory.ConfigValue = 512
$smosrv.Configuration.DefaultBackupCompression.ConfigValue = 1
$smosrv.Configuration.IsSqlClrEnabled.ConfigValue = 1
$smosrv.Configuration.OptimizeAdhocWorkLoads.ConfigValue = 1
$smosrv.Configuration.Alter()

$smosrv.AuditLevel = [Microsoft.SqlServer.Management.Smo.AuditLevel]::Failure
$smosrv.NumberOfLogFiles =20
$smosrv.Alter()

$smosrv.jobserver.MaximumHistoryRows = 20000
$smosrv.jobserver.MaximumJobHistoryRows = 500
$smosrv.JobServer.Alter()

$smosrv.databases['model'].RecoveryModel = 'Simple'
$smosrv.databases['model'].Alter()


#Simple t-log restore script
Set-Location C:\Temp
$LastFull= Get-ChildItem '\\PICARD\C$\Backups\AdventureWorks2014\*.bak' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$logs = Get-ChildItem '\\PICARD\C$\Backups\AdventureWorks2014\*.trn' | Where-Object {$_.LastWriteTime -gt $LastFull.LastWriteTime} | Sort-Object LastWriteTime

$MoveFiles = @()
$MoveFiles += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile ('AdventureWorks2014_Data','C:\DBFiles\data\AdventureWorks2014New_Data.mdf')
$MoveFiles += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile ('AdventureWorks2014_Log','C:\DBFiles\log\AdventureWorks2014New_Log.ldf')

$db = 'AdventureWork2014New'
Restore-SqlDatabase -ServerInstance 'PICARD' -Database $db -RelocateFile $MoveFiles -BackupFile $LastFull.FullName -RestoreAction Database -NoRecovery -Script | Out-File 'C:\Temp\Restore.sql'
foreach($log in $logs){
    if($log -eq $logs[$logs.Length -1]){
        Restore-SqlDatabase -ServerInstance 'PICARD' -Database $db -BackupFile $log.FullName -RestoreAction Log -Script | Out-File 'C:\Temp\Restore.sql' -Append
    }
    else{
        Restore-SqlDatabase -ServerInstance 'PICARD' -Database $db -BackupFile $log.FullName -RestoreAction Log -NoRecovery -Script | Out-File 'C:\Temp\Restore.sql' -Append
    }
}
