#Using SQL CMD
#sqlcmd - Just call within the script
sqlcmd -d tempdb -Q "select count(1) from sys.objects"

#create a script, run it against multiple instances
$sql="
SET NOCOUNT ON
select sp.name,count(1) db_count
from sys.server_principals sp
join sys.databases d on (sp.sid = d.owner_sid)
group by sp.name
"
sqlcmd -d tempdb -Q $sql

#Multi-instance execution
cls
$instances = @("localhost","localhost\ALBEDO")
foreach($instance in $instances){
   "Instance: $instance"
   $out=sqlcmd -S $instance -Q $sql 
   $out |Format-Table -AutoSize
}

#Messy! This is because sqlcmd outputs strings
$out[0].GetType().Name

#Load the SQL Server Powershell module
Import-Module sqlps -DisableNameChecking

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
$dbs = Invoke-SqlCmd -ServerInstance "localhost" -Query "select name from sys.databases where database_id in (1,3,4)"
foreach ($db in $dbs.name){
    $dbname = $db.TrimEnd()
    $sql = "BACKUP DATABASE $dbname TO DISK='C:\DBFiles\Backups\systemdbs\$dbname.bak' WITH COMPRESSION,INIT"
    Invoke-SqlCmd -ServerInstance "localhost" -Query  $sql
}

dir C:\DBFiles\backups\systemdbs

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
CD SQL\SHION\
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

#set all default dbs for non-system logins to tempdb
foreach($dblogin in $dblogins){
    $dblogin.defaultdatabase = 'tempdb'
}

dir logins -Force| Select-Object name,defaultdatabase

#Some of the generic functions won't work
New-Item database\poshtest

#So we will need to use traditional methods
Invoke-Sqlcmd -ServerInstance localhost -Database tempdb -Query "CREATE DATABASE poshtest"
dir databases

#But other things do work
Remove-Item databases\poshtest
dir databases

#Let's look at the CMS
CD "SQLSERVER:\SQLRegistration\Central Management Server Group\SHION"
dir

#we can see all the servers in our CMS
#now let's use it to run all our systemdb backups
cd C:\
$servers= dir "SQLSERVER:\SQLRegistration\Central Management Server Group\SHION"
foreach($server in $servers.Name){
    
    $dbs = Invoke-SqlCmd -ServerInstance $server -Query "select name from sys.databases where database_id in (1,3,4)"
    $pathname= "C:\DBFiles\Backups\"+$server.Replace('\','_')
    if(!(test-path $pathname)){mkdir $pathname}
    foreach ($db in $dbs.name){
        $dbname = $db.TrimEnd()
        $sql = "BACKUP DATABASE $dbname TO DISK='$pathname\$dbname.bak' WITH COMPRESSION,INIT"
        Invoke-SqlCmd -ServerInstance $server -Query  $sql
    }
}

dir C:\DBFiles\backups\SHION_ALBEDO

#SMO
#Powershell can acess the .NET SMO libraries
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

$smoserver = new-object ('Microsoft.SqlServer.Management.Smo.Server') 

#We can now interact with the server as it is an object
$smoserver | Get-Member
$smoserver.Version

#We can also drilldown into the parts of the server
$smoserver.Databases
$sysjobs = $smoserver.Databases["msdb"].Tables["sysjobs"]

#now we have a table object with its own properties
$sysjobs | Get-Member
$sysjobs.Indexes
$sysjobs.Script()

#we can now make collections
rm C:\PowershellDemo\logins.sql
$logins= $smoserver.Logins
foreach($login in $logins) {$login.Script() >> C:\PowershellDemo\logins.sql}

notepad C:\PowershellDemo\logins.sql

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