
#Simple t-log restore script
if(Test-Path 'C:\IntroToPowershell\RestoreDummyLogs.sql'){Remove-Item 'C:\IntroToPowershell\RestoreDummyLogs.sql'}
$files = Get-ChildItem '\\picard\Backups\dummy\*.trn' | Sort-Object LastWriteTime 
$files |ForEach-Object {"RESTORE DATABASE [dummy] FROM DISK=N`'" + $_.FullName + "`' WITH NORECOVERY" | Out-File -Append 'C:\IntroToPowershell\RestoreDummyLogs.sql' }

#extract all your database schemas as dacpacs
$server = 'PICARD'
$dbs = Invoke-Sqlcmd -ServerInstance $server -Database tempdb -Query 'SELECT name FROM sys.databases WHERE database_id >4'

foreach($db in $dbs.name){
    $cmd = "& 'C:\Program Files (x86)\Microsoft SQL Server\120\DAC\bin\sqlpackage.exe' /action:Extract /targetfile:'C:\IntroToPowershell\$db.dacpac' /SourceServerName:$server /SourceDatabaseName:$db"
    Invoke-Expression $cmd
}

#Add a list of servers to your CMS
$servers = @('RIKER','WORF')

foreach ($server in $servers)
{
	
	if (!(Test-Path $(Encode-Sqlname $server))) 
	{
        New-Item $(Encode-Sqlname $server) `
            -itemtype registration `
            -Value “server=$server;integrated security=true;name=$server” 
        }
}

#backup databases in parallel
$dbs = Invoke-Sqlcmd -ServerInstance PICARD -Database tempdb -Query "SELECT name FROM sys.databases WHERE database_id > 4"
$datestring =  (Get-Date -Format 'yyyyMMddHHmm')

foreach($db in $dbs.name){
    $dir = "C:\Backups\$db"
    if(!(Test-Path $dir)){New-Item -ItemType Directory -path $dir}
    
    $filename = "$db-$datestring.bak"
    $backup=Join-Path -Path $dir -ChildPath $filename
    $sql = "BACKUP DATABASE $db TO DISK = N'$backup'"
    $cmd = "Invoke-Sqlcmd -ServerInstance localhost -Database tempdb -Query `"$sql`" -QueryTimeout 6000;"
    $cmd += "Get-ChildItem $dir\*.bak| Where {`$_.LastWriteTime -lt (Get-Date).AddMinutes(-1)}|Remove-Item;"
    [scriptblock]$cmdblock = [ScriptBlock]::Create($cmd)
    Start-Job $cmdblock
}


#change all service accounts for a list of servers
cd C:\
$account = 'SDF\sqlsvc'
$password = 'SQLp@55word'
#$password = '73gnat!9'

$servers= @('PICARD')

foreach($server in $servers){
    $wmi = new-object ("Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer") $Server
	$svcs = $wmi.services | where {$_.Type -eq 'SqlServer'} 

    $svcs | Select-Object DisplayName,ServiceAccount
   
    foreach($svc in $svcs){
        try{
            $svc.SetServiceAccount($account,$password)
        }
        catch{
            write-error $error[0]
        }
    }
   $svcs | Select-Object DisplayName,ServiceAccount
}


#Configure SQL Server with the SMO:
$smosrv = New-Object ('Microsoft.SqlServer.Management.Smo.Database') 'PICARD'

$smosrv.Configuration.MaxServerMemory.ConfigValue = 1024
$smosrv.Configuration.DefaultBackupCompression.ConfigValue = 1
$smosrv.Configuration.IsSqlClrEnabled.ConfigValue = 1
$smosrv.Configuration.OptimizeAdhocWorkLoads.ConfigValue = 1
$smosrv.Configuration.Alter()

$smosrv.AuditLevel = [Microsoft.SqlServer.Management.Smo.AuditLevel]::Failure
$smosrv.NumberOfLogFiles =99
$smosrv.Alter()

$smosrv.jobserver.MaximumHistoryRows = 100000
$smosrv.jobserver.MaximumJobHistoryRows = 2000
$smosrv.JobServer.Alter()

$smosrv.databases['model'].RecoveryModel = 'Simple'
$smosrv.databases['model'].Alter()