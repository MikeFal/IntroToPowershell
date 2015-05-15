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
$smosrv = New-Object ('Microsoft.SqlServer.Management.Smo.Database') 'PICARD'

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
cd c:\
if(Test-Path 'C:\IntroToPowershell\RestoreAWLogs.sql'){Remove-Item 'C:\IntroToPowershell\RestoreAWLogs.sql'}
$files = Get-ChildItem '\\picard\C$\Backups\AdventureWorks2012\*.trn' | Sort-Object LastWriteTime 
$files |ForEach-Object {"RESTORE DATABASE [AdventureWorks2012] FROM DISK=N`'" + $_.FullName + "`' WITH NORECOVERY" | Out-File -Append 'C:\IntroToPowershell\RestoreAWLogs.sql' }

notepad 'C:\IntroToPowershell\RestoreAWLogs.sql'
