#Add a list of servers to your CMS
cd 'SQLSERVER:\SQLRegistration\Central Management Server Group\TARKIN'
#remove to demo
if (Test-Path $(Encode-Sqlname VADER)){Remove-Item VADER}

$servers= @('VADER')

foreach ($server in $servers)
{
	
	if (!(Test-Path $(Encode-Sqlname $server))) 
	{
        New-Item $(Encode-Sqlname $server) `
            -itemtype registration `
            -Value “server=$server;integrated security=true;name=$server” 
        }
}

dir 'SQLSERVER:\SQLRegistration\Central Management Server Group\TARKIN'

#Configure SQL Server with the SMO:
$smosrv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') 'TARKIN'

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
$OutPath = 'C:\Temp\Restore.sql'
$LastFull= Get-ChildItem '\\TARKIN\C$\Backups\WideWorldImporters\*.bak' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$logs = Get-ChildItem '\\TARKIN\C$\Backups\WideWorldImporters\*.trn' | Where-Object {$_.LastWriteTime -gt $LastFull.LastWriteTime} | Sort-Object LastWriteTime

$MoveFiles = @()
$MoveFiles += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile ('WWI_Primary','C:\DBFiles\data\WideWorldImportersNew_Data.mdf')
$MoveFiles += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile ('WWI_UserData','C:\DBFiles\Data\WideWorldImportersNew_UserData.ndf')
$MoveFiles += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile ('WWI_InMemory_Data_1','C:\DBFiles\data\WideWorldImportersNew_InMemory_Data_1')
$MoveFiles += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile ('WWI_Log','C:\DBFiles\log\WideWorldImportersNew_Log.ldf')

$db = 'WideWorldImportersNew'
Restore-SqlDatabase -ServerInstance 'TARKIN' -Database $db -RelocateFile $MoveFiles -BackupFile $LastFull.FullName -RestoreAction Database -NoRecovery -Script | Out-File $OutPath
foreach($log in $logs){
    if($log -eq $logs[$logs.Length -1]){
        Restore-SqlDatabase -ServerInstance 'TARKIN' -Database $db -BackupFile $log.FullName -RestoreAction Log -Script | Out-File $OutPath -Append
    }
    else{
        Restore-SqlDatabase -ServerInstance 'TARKIN' -Database $db -BackupFile $log.FullName -RestoreAction Log -NoRecovery -Script | Out-File $OutPath -Append
    }
}

notepad $OutPath

#We can also just restore it
Restore-SqlDatabase -ServerInstance 'TARKIN' -Database $db -RelocateFile $MoveFiles -BackupFile $LastFull.FullName -RestoreAction Database -NoRecovery
foreach($log in $logs){
    if($log -eq $logs[$logs.Length -1]){
        Restore-SqlDatabase -ServerInstance 'TARKIN' -Database $db -BackupFile $log.FullName -RestoreAction Log
    }
    else{
        Restore-SqlDatabase -ServerInstance 'TARKIN' -Database $db -BackupFile $log.FullName -RestoreAction Log -NoRecovery
    }
}
