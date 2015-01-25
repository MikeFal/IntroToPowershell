#basic Powershell use

#already looked at deleting specific old files
dir C:\DBFiles\backups\backups\ -Recurse | Where-Object {$_.Extension  -eq ".trn" -and $_.LastWriteTime -lt (Get-Date).AddDays(-3)} | rm -WhatIf

#-------------------------------------------------------------
#We can use Get-Service to find our SQL Server services
Get-Service *SQL*

#What if we want to do a check for any SQL Server services not running?
Get-Service *SQL* | Where-Object {$_.Status -ne 'Running' -and $_.Name -like 'MSSQL*'}

#stop the service so it will cause an alert
Stop-Service MSSQLSERVER -force

#So it doesn't take much more to write a script to alert us if SQL Server isn't running
$svcs =Get-Service *SQL* | Where-Object {$_.Status -ne 'Running' -and $_.Name -like 'MSSQL*'}

$count = ($svcs | Measure-Object).Count
if($count -gt 0){
    Write-Warning "Count of stopped SQL Server instances is: $count"
}

#We could get even more clever and start all the services from that object
foreach($svc in $svcs){
    Start-Service $svc
}


#-------------------------------------------------------------
#Using Powershell to collect perfmon info

$counters=@("\LogicalDisk(C:)\Disk Bytes/sec"
,"\LogicalDisk(C:)\Avg. Disk sec/read"
,"\LogicalDisk(C:)\Avg. Disk Sec/Write"
,"\LogicalDisk(C:)\Disk Transfers/sec")

$sample = Get-Counter -Counter $counters 
$sample.CounterSamples | Select-Object -Property Path,CookedValue,Timestamp | Format-Table -AutoSize

#By creating a server list, we can execute our collection against multiple machines
$srvrs = @('HIKARU','MISA')
$samples=@()

foreach($srvr in $srvrs){
	$output=(Get-Counter -ComputerName $srvr -Counter $counters -ErrorAction SilentlyContinue).CounterSamples | Select-Object -Property Path,CookedValue,Timestamp
	if($output -ne $null){
		$output | Add-Member -Type NoteProperty -Name Server -Value $srvr					
		$output | Add-Member -Type NoteProperty -Name fullmount -Value $cleanmp		
		$samples+=$output
	}
}


#-------------------------------------------------------------
#This was a simple script I used to mass convert RedGate Backup files to native.
$files = ls X:\Backups *_RG*

foreach($x in $files){
	$old = $x.DirectoryName +"\" + $x.Name
	$new = $x.DirectoryName +"\" + $x.Name.Replace("_RG","")
	.\SQBConverter.exe $old $new
	}

#You can use loops to selectively move files from one server to another
#this script moves all of Server A's transaction log backups to server B
$source = 'ServerA'
$target = 'ServerB'
$dirs = ls \\$source\backups | where {$_.Name -ne $source}
foreach($dir in $dirs){
    if(!(Test-Path -Path \\$target\backups\$dir\transactionlogs)){New-Item -ItemType Directory -Path \\$target\backups\$dir\transactionlogs}
    robocopy \\$source\backups\$dir\transactionlogs \\$target\backups\$dir\transactionlogs
}


#-------------------------------------------------------------
#We can use some simple commands to build out restore statements for transaction logs
$path = 'C:\DBFiles\backups\backups'
$files = ls $path\*.trn | Sort-Object -Property lastwritetime
$out = @()
foreach($file in $files){
    $out += "RESTORE LOG [Vault_Xero] FROM DISK='W:\MSSQL\Backups\Vault_Xero\TransactionLogs\" + $file.name + "' WITH NORECOVERY"
}

$out | Out-File -FilePath C:\TEMP\restorelogs.sql


#If you have a cluster, you can use the commands to create directories (or other work) on each node consistently
Import-Module FailoverClusters
$cname = (Get-Cluster -name 'ServerA').name
$nodes = (get-clusternode -Cluster $cname).name
$jobscript = 'C:\Users\Adm-mike.fal\Documents\Backup - Full - DBA Database.sql'
foreach($node in $nodes){
    "Connecting to $node"
    sqlcmd -S $node -d msdb -i $jobscript -v RedeployJobs="YES"
}