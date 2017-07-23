#First, clear the screen
Clear-Host

#already looked at deleting specific old files
dir '\\TARKIN\C$\Backups' -Recurse | 
    Where-Object {$_.Extension  -eq ".trn" -and $_.LastWriteTime -lt (Get-Date).AddHours(-3)} |
    Remove-Item -WhatIf

#Powershell can interface with .Net libraries, COM objects, other functionality.
#For example, we can use Powershell to interact directly with the WMI
$wmi=Get-WmiObject -Class Win32_ComputerSystem
$wmi | Get-Member

$wmi.NumberOfProcessors
$Wmi.NumberOfLogicalProcessors
$wmi.Domain

#We can format output in a couple different ways.  Table and list are the most commonly used options
$wmi |ConvertTo-Csv | Out-File C:\temp\wmi.txt
$wmi | Format-Table -AutoSize

#Note that the object doesn't display everything available.  We can control this with Select-Object.
$wmi | Select-Object Name,Domain,TotalPhysicalMemory,NumberOfProcessors,Model | Format-List

$wmi | Select-Object Name,Domain,TotalPhysicalMemory/1GB,NumberOfProcessors,Model | Format-Table -AutoSize
$wmi.TotalPhysicalMemory/1GB


#-------------------------------------------------------------
#We can use Get-Service to find our SQL Server services
Get-Service -computername TARKIN *SQL*

#What if we want to do a check for any SQL Server services not running?
Get-Service -computername TARKIN *SQL* | 
    Where-Object {$_.Status -ne 'Running' -and $_.Name -like 'MSSQL*'}

#stop the service so it will cause an alert
#We can't use Start-Service and Stop-Service remotely as is, we need to use Invoke-Command to run commands remotely
Invoke-Command -ComputerName TARKIN -scriptblock {Stop-Service MSSQLSERVER -force}

Get-Service -computername TARKIN *SQL* | 
    Where-Object {$_.Status -ne 'Running' -and $_.Name -like 'MSSQL*'}

#So it doesn't take much more to write a script to alert us if SQL Server isn't running
$svcs =Get-Service -computername TARKIN *SQL* | Where-Object {$_.Status -ne 'Running' -and $_.Name -like 'MSSQL*'}

$count = ($svcs | Measure-Object).Count
if($count -gt 0){
    Write-Warning "Count of stopped SQL Server instances is: $count"
}

#We could get even more clever and start all the services from that object
foreach($svc in $svcs){
    $svccmd = [ScriptBlock]::Create('Start-Service ' + $svc.Name)
    Invoke-Command -ComputerName TARKIN -scriptblock $svccmd
}

#Quick cheat, we have to restart the agent service
Invoke-Command -ComputerName TARKIN -scriptblock {Start-Service SQLSERVERAGENT}

#-------------------------------------------------------------
#Using Powershell to collect perfmon info

$counters=@("\LogicalDisk(C:)\Disk Bytes/sec"
,"\LogicalDisk(C:)\Avg. Disk sec/read"
,"\LogicalDisk(C:)\Avg. Disk Sec/Write"
,"\LogicalDisk(C:)\Disk Transfers/sec")

$sample = Get-Counter -Counter $counters 
$sample.CounterSamples | Select-Object -Property Path,CookedValue,Timestamp | Format-Table -AutoSize

#By creating a server list, we can execute our collection against multiple machines
$srvrs = @('VADER','TARKIN')
$samples=@()

foreach($srvr in $srvrs){
	$output=(Get-Counter -ComputerName $srvr -Counter $counters -ErrorAction SilentlyContinue).CounterSamples | Select-Object -Property Path,CookedValue,Timestamp
	if($output -ne $null){
		$output | Add-Member -Type NoteProperty -Name Server -Value $srvr					
		$output | Add-Member -Type NoteProperty -Name fullmount -Value $cleanmp		
		$samples+=$output
	}
}

$samples | Select-Object -Property Path,CookedValue,Timestamp

#-------------------------------------------------------------
#You can use loops to selectively move files from one server to another
#this script moves all of Server A's transaction log backups to server B
$source = 'TARKIN'
$target = 'VADER'
$dirs = Get-ChildItem \\$source\C$\backups | where {$_.Name -ne $source}
foreach($dir in $dirs){
    if(!(Test-Path -Path \\$target\C$\backups\$dir)){New-Item -ItemType Directory -Path \\$target\C$\backups\$dir}
    robocopy \\$source\C$\backups\$dir \\$target\C$\backup\$dir
}

dir \\$target\C$\backup\ -Recurse

#Clean up the copy
foreach($dir in $dirs){
    if(Test-Path -Path \\$target\C$\backup\$dir){Remove-Item -Path \\$target\C$\backup\$dir -Recurse -Force}
}


#-------------------------------------------------------------
#If you have a cluster, you can use the commands to create directories (or other work) on each node consistently
Import-Module FailoverClusters
$cname = (Get-Cluster -name 'TARKIN').name
$nodes = (get-clusternode -Cluster $cname).name

foreach($node in $nodes){
    "Connecting to $node"
    sqlcmd -S $node -d tempdb -Q 'ALTER DATABASE [model] SET RECOVERY SIMPLE;'
}