#Create fileshare for witness
#New-Item -Path 'C:\QWitness' -ItemType Directory 
#New-SmbShare -name QWitness -Path 'C:\QWitness'
cls
$StartTime = Get-Date

#Create FailoverCluster
Import-Module FailoverClusters
New-Cluster -Name 'NCC1701' -StaticAddress '192.168.10.100' -NoStorage -Node @('KIRK','SPOCK') | Set-ClusterQuorum -FileShareWitness '\\hikarudc\qwitness'

Start-Sleep -Seconds 60

ipconfig /flushdns

Write-Host -ForegroundColor Cyan "Cluster Built...."
#Test-Cluster 'NC1701'

#Build AG Group

#Set initial variables
Import-Module SQLPS -DisableNameChecking
$AGName = 'ENTERPRISE'
$PrimaryNode = 'KIRK'
$IP = '192.168.10.101/255.255.255.0'

$replicas = @()
$cname = (Get-Cluster -name $PrimaryNode).name 
$nodes = (get-clusternode -Cluster $cname).name 


$nodes | ForEach-Object {Enable-SqlAlwaysOn -path "SQLSERVER:\SQL\$_\DEFAULT" -Force}

$sqlperms = @"
use [master];
GRANT ALTER ANY AVAILABILITY GROUP TO [NT AUTHORITY\SYSTEM];
GRANT CONNECT SQL TO [NT AUTHORITY\SYSTEM];
GRANT VIEW SERVER STATE TO [NT AUTHORITY\SYSTEM];

CREATE LOGIN [SDF\sqlsvc] FROM WINDOWS;
GRANT CONNECT ON endpoint::[HADR_Endpoint] to [SDF\sqlsvc];
"@

foreach($node in $nodes){
     $endpoint = New-SqlHadrEndpoint HADR_Endpoint -Port 5022 -Path SQLSERVER:\SQL\$node\DEFAULT
     Set-SqlHadrEndpoint -InputObject $endpoint -State "Started"
     $replicas += New-SqlAvailabilityReplica -Name $node -EndpointUrl "TCP://$($node):5022" -AvailabilityMode 'SynchronousCommit' -FailoverMode 'Automatic' -AsTemplate -Version 12
     Invoke-Sqlcmd -ServerInstance $node -Database master -Query $sqlperms
}

$nodes | Where-Object {$_ -ne $PrimaryNode} | ForEach-Object {Enable-SqlAlwaysOn -path "SQLSERVER:\SQL\$_\DEFAULT" -Force}

New-SqlAvailabilityGroup -Name $AGName -Path "SQLSERVER:\SQL\$PrimaryNode\DEFAULT" -AvailabilityReplica $replicas
$nodes | Where-Object {$_ -ne $PrimaryNode} | ForEach-Object {Join-SqlAvailabilityGroup -path "SQLSERVER:\SQL\$_\DEFAULT" -Name $AGName}

New-SqlAvailabilityGroupListener -Name $AGName -staticIP $IP -Port 1433 -Path "SQLSERVER:\Sql\$PrimaryNode\DEFAULT\AvailabilityGroups\$AGName"

Write-Host -ForegroundColor Cyan "AG Built...."

#Install AdventureWorks
$sqlrestore = @"
RESTORE DATABASE AdventureWorks2012 
FROM DISK=N'\\HIKARUDC\InstallFiles\Backups\AdventureWorks2012.bak'
WITH NORECOVERY,REPLACE;
"@

$cname = (Get-Cluster -name 'KIRK').name 
$nodes = (get-clusternode -Cluster $cname).name 

foreach ($node in $nodes){
    Invoke-Sqlcmd -ServerInstance $node -Database master -Query $sqlrestore -QueryTimeout 0
}

$sqlprimary = @"
RESTORE DATABASE AdventureWorks2012 WITH RECOVERY;
ALTER AVAILABILITY GROUP [ENTERPRISE] ADD DATABASE [AdventureWorks2012];
"@
Invoke-Sqlcmd -ServerInstance KIRK -Database master -Query $sqlprimary -QueryTimeout 0

$sqlsecondary = "ALTER DATABASE [AdventureWorks2012] SET HADR AVAILABILITY GROUP = [ENTERPRISE];"

Invoke-Sqlcmd -ServerInstance SPOCK -Database master -Query $sqlsecondary -QueryTimeout 0

Write-Host -ForegroundColor Cyan "AdventureWorks2012 deployed...."

$timestring = 'AG BUILD TIME: [' + ((Get-Date) - $StartTime) + ']'
Write-Host -ForegroundColor Cyan $timestring

#Test Failovers
$validatequery = "SELECT @@SERVERNAME [AGNode] ,count(1) [AW_Table_Count] FROM [AdventureWorks2012].[sys].[tables]"


Invoke-Sqlcmd -ServerInstance ENTERPRISE -Database master -Query $validatequery

Invoke-Sqlcmd -ServerInstance SPOCK -Database master -Query "ALTER AVAILABILITY GROUP [ENTERPRISE] FAILOVER"
Invoke-Sqlcmd -ServerInstance ENTERPRISE -Database master -Query $validatequery

Invoke-Sqlcmd -ServerInstance KIRK -Database master -Query "ALTER AVAILABILITY GROUP [ENTERPRISE] FAILOVER"
Invoke-Sqlcmd -ServerInstance ENTERPRISE -Database master -Query $validatequery

Write-Host -ForegroundColor Cyan "AG Validated...."