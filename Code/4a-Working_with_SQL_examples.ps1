#Add a list of servers to your CMS
$servers = @('HIKARU','MINMEI')

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
$dbs = Invoke-Sqlcmd -ServerInstance localhost -Database tempdb -Query "SELECT name FROM sys.databases WHERE database_id > 4"
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


#change all service accounts for all servers in the CMS
cd C:\
$account = ''
$password = ''

$servers= dir "SQLSERVER:\SQLRegistration\Central Management Server Group\SHION"
foreach($server in $servers.Name){
    $wmi = new-object ("Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer") $Server
		$svcs = $wmi.services | where {$_.Type -eq 'SqlServer'} 
    foreach($svc in $svcs){
        try{
            $svc.SetServiceAccount($account,$password)
        }
        catch{
            write-error[0]
    }
}

#Grow log file in 8GB chunks
#load assemblies
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
$ErrorActionPreference = 'Inquire'

function Expand-SqlLogFile{
  param(
  [string]$InstanceName = 'localhost',
  [parameter(Mandatory=$true)][string] $DatabaseName,
  [parameter(Mandatory=$true)][int] $LogSizeMB)

#Convert MB to KB (SMO works in KB)
[int]$LogFileSize = $LogSizeMB*1024

#Set base information
$srv = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $InstanceName
$logfile = $srv.Databases[$DatabaseName].LogFiles[0]
$CurrSize = $logfile.Size

#grow file
while($CurrSize -lt $LogFileSize){
  if(($LogFileSize - $CurrSize) -lt 8192000){$CurrSize = $LogFileSize}
  else{$CurrSize += 8192000}
  logfile.size = $CurrSize
  $logfile.Alter()
  }
}
#Call the function
Expand-SqlLogFile -DatabaseName 'test' -LogSizeMB 35000

#Check growth on SQL Instance