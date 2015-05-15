#Using SQL CMD
#sqlcmd - Just call within the script
sqlcmd -S PICARD -d tempdb -Q "select count(1) from sys.objects"

#create a script, run it against multiple instances
$sql="
SET NOCOUNT ON
select sp.name,count(1) db_count
from sys.server_principals sp
join sys.databases d on (sp.sid = d.owner_sid)
group by sp.name
"
sqlcmd -S PICARD -d tempdb -Q $sql

#Multi-instance execution
cls
$instances = @("PICARD","PICARD\WESLEY")
foreach($instance in $instances){
   "Instance: $instance"
   $out=sqlcmd -S $instance -Q $sql 
   $out |Format-Table -AutoSize
}

#What kind of output is this?
$out[0].GetType().Name

#Load the SQL Server Powershell module
Import-Module sqlps -verbose #-DisableNameChecking

#What's available to us?
Get-Command -Module sqlps
Get-Command -Module sqlps | Measure-Object |Select Count

#And we can use Get-Help to get more info
Get-Help Invoke-Sqlcmd -ShowWindow

cls
foreach($instance in $instances){
   "Instance: $instance"
   $ISout=Invoke-Sqlcmd -ServerInstance $instance -Query $sql 
   $ISout |ft -AutoSize
}

$ISout | Get-Member

#We can use Invoke-Sqlcmd almost like sqlcmd, but since we have a data row we can use it to easily drive other functionality
$instance = 'PICARD'
$dbs = Invoke-SqlCmd -ServerInstance $instance -Query "select name from sys.databases where database_id in (1,3,4)"
foreach ($db in $dbs.name){
    $dbname = $db.TrimEnd()
    $sql = "BACKUP DATABASE $dbname TO DISK='C:\DBFiles\Backups\$instance-$dbname.bak' WITH COMPRESSION,INIT"
    Invoke-SqlCmd -ServerInstance $instance -Query  $sql
}

cd c:\
dir '\\PICARD\C$\DBFiles\backups'

#SQL Provider
#--------------------------------------
#By loading SQLPS,we also load the SQL Server Provider
cls
Get-PSDrive

#Change to the SQL Server Provider
CD SQLSERVER:\
dir

#We can browse our SQL Servers as if they were directories
cls
CD SQL\PICARD\
dir

CD DEFAULT
dir

dir Databases
dir databases -Force
$dbout = dir databases -Force
$dbout | gm
$dbout | where {$_.readonly -eq $false}

$dbout | select name,createdate,@{name='DataSizeMB';expression={$_.dataspaceusage/1024}} | Format-Table -AutoSize

#let's work with logins
$dblogins = dir logins 
$dblogins
$dblogins | gm

dir logins -Force| Select-Object name,defaultdatabase


#set all default dbs for non-system logins to tempdb
foreach($dblogin in $dblogins){
    if($dblogin.issystemobject -eq $false){
        $dblogin.defaultdatabase = 'tempdb'
    }
}

dir logins -Force| Select-Object name,defaultdatabase

#Some of the generic functions won't work
New-Item database\poshtest

#So we will need to use traditional methods
Invoke-Sqlcmd -ServerInstance PICARD -Database tempdb -Query "CREATE DATABASE poshtest"
dir databases

#But other things do work
Remove-Item databases\poshtest
dir databases

#Let's look at the CMS
CD "SQLSERVER:\SQLRegistration\Central Management Server Group\PICARD"
dir

#we can see all the servers in our CMS
#now let's use it to run all our systemdb backups
cd C:\
$servers= @((dir "SQLSERVER:\SQLRegistration\Central Management Server Group\PICARD").Name)
$servers += 'PICARD'

foreach($server in $servers){
    
    $dbs = Invoke-SqlCmd -ServerInstance $server -Query "select name from sys.databases where database_id in (1,3,4)"
    $pathname= "C:\DBFiles\Backups\"+$server.Replace('\','_')
    [scriptblock]$cmd = [scriptblock]::Create("if(!(test-path $pathname)){mkdir $pathname}")
    Invoke-Command -ComputerName 'PICARD' -ScriptBlock $cmd  
    foreach ($db in $dbs.name){
        $dbname = $db.TrimEnd()
        $sql = "BACKUP DATABASE $dbname TO DISK='$pathname\$dbname.bak' WITH COMPRESSION,INIT"
        Invoke-SqlCmd -ServerInstance $server -Query  $sql
    }
}

dir '\\PICARD\C$\DBFiles\Backups' -recurse

#SMO
#Powershell can acess the .NET SMO libraries
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

$smoserver = new-object ('Microsoft.SqlServer.Management.Smo.Server') 'PICARD' 

#We can now interact with the server as it is an object
$smoserver | Get-Member
$smoserver.Version

#We can also drilldown into the parts of the server
$smoserver.Databases

#now we have a table object with its own properties
$sysjobs = $smoserver.Databases["msdb"].Tables["sysjobs"]
$sysjobs | Get-Member
$sysjobs.Indexes
$sysjobs.Script()

#we can now make collections
rm C:\IntroToPowershell\logins.sql
$logins= $smoserver.Logins
foreach($login in $logins) {$login.Script() >> C:\IntrotoPowershell\logins.sql}

notepad C:\IntrotoPowershell\logins.sql

#we can also create objects
#this is a little trickier

$db = New-Object ('Microsoft.SqlServer.Management.Smo.Database') ($smoserver,'SMOTest')
$db | Get-Member

#Just creating the new object doesn't mean it's created (look in SMO)
#so let's create it
$db.Create()

#but we don't want the files in the default location.  So now the fun begins.
$db.Drop()

#First we have to declare our files
$dbname = 'SMOTest'
$db = New-Object ('Microsoft.SqlServer.Management.Smo.Database') ($smoserver,$dbname)
$fg = New-Object ('Microsoft.SqlServer.Management.Smo.FileGroup') ($db,'PRIMARY')
$mdf = New-Object ('Microsoft.SqlServer.Management.Smo.DataFile') ($fg,"$dbname`_data01")
$ldf = New-Object ('Microsoft.SqlServer.Management.Smo.LogFile') ($db,"$dbname`_log")
$mdf.FileName = "C:\DBFiles\Data\$dbname`_data01.mdf"
$mdf.Size = (100 * 1024)
$mdf.Growth = (10 * 1024)
$mdf.GrowthType = 'KB'
$db.FileGroups.Add($fg)
$fg.Files.Add($mdf)

$ldf.FileName = "C:\DBFiles\Log\$dbname`_log.ldf"
$ldf.Size = (10 * 1024)
$ldf.Growth = (10 * 1024)
$ldf.GrowthType = 'KB'
$db.LogFiles.Add($ldf)

#and we can look at the script to create it
$db.Script()

#or we can just create it
$db.Create()


#Cleanup!
$db.Drop()

#Agent Jobs
#SQL 2008 supports Powershell as a job step

#Script 1 (backup user dbs, cleanup old files)

#backup your databases
#get a collection of databases
$dbs = Invoke-Sqlcmd -ServerInstance localhost -Database tempdb -Query "SELECT name FROM sys.databases WHERE database_id > 4 and STATE_DESC = 'ONLINE'"

#Get a formatted string for the datetime
$datestring =  (Get-Date -Format 'yyyyMMddHHmm')

#loop through the databases
foreach($db in $dbs.name){
    $dir = "C:\Backups\$db"
    #does the backup directory exist?  If not, create it
    if(!(Test-Path $dir)){New-Item -ItemType Directory -path $dir}
    
    #Get a nice name and backup your database to it
    $filename = "$db-$datestring.bak"
    $backup=Join-Path -Path $dir -ChildPath $filename
    $sql = "BACKUP DATABASE $db TO DISK = N'$backup' WITH COMPRESSION"
    Invoke-Sqlcmd -ServerInstance localhost -Database tempdb -Query $sql -QueryTimeout 6000
    #Delete old backups
    Get-ChildItem $dir\*.bak| Where {$_.LastWriteTime -lt (Get-Date).AddMinutes(-1)}|Remove-Item

}


#script 2 - Backup user db logs
#backup your databases
#get a collection of databases
$dbs = Invoke-Sqlcmd -ServerInstance localhost -Database tempdb -Query "SELECT name FROM sys.databases WHERE database_id > 4 and STATE_DESC = 'ONLINE' and RECOVERY_MODEL_DESC != 'SIMPLE'"

#Get a formatted string for the datetime
$datestring =  (Get-Date -Format 'yyyyMMddHHmm')

#loop through the databases
foreach($db in $dbs.name){
    $dir = "C:\Backups\$db"
    #does the backup directory exist?  If not, create it
    if(!(Test-Path $dir)){New-Item -ItemType Directory -path $dir}
    
    #Get a nice name and backup your database to it
    $filename = "$db-$datestring.trn"
    $backup=Join-Path -Path $dir -ChildPath $filename
    $sql = "BACKUP LOG $db TO DISK = N'$backup'"
    Invoke-Sqlcmd -ServerInstance localhost -Database tempdb -Query $sql -QueryTimeout 6000
    #Delete old backups
    Get-ChildItem $dir\*.trn| Where {$_.LastWriteTime -lt (Get-Date).AddDays(-3)}|Remove-Item

}
