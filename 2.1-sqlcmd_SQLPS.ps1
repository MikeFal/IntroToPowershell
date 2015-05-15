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
$instances = @('PICARD','RIKER')
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
if(!(Test-Path '\\PICARD\C$\Backups')){New-Item -ItemType Directory -Path '\\PICARD\C$\Backups'}

foreach ($db in $dbs.name){
    $dbname = $db.TrimEnd()
    $sql = "BACKUP DATABASE $dbname TO DISK='C:\Backups\$instance-$dbname.bak' WITH COMPRESSION,INIT"
    Invoke-SqlCmd -ServerInstance $instance -Query  $sql
}

cd c:\
dir '\\PICARD\C$\Backups'

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

#We'll set them back now
foreach($dblogin in $dblogins){
    if($dblogin.issystemobject -eq $false){
        $dblogin.defaultdatabase = 'master'
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
#gonna clean up the directory first
dir 'C:\Backups' -Recurse | rm -Recurse -Force

#nothing up my sleeve
dir 'C:\Backups' -recurse

#now let's use it to run all our systemdb backups
cd C:\
$servers= @((dir "SQLSERVER:\SQLRegistration\Central Management Server Group\PICARD").Name)
$servers += 'PICARD'

foreach($server in $servers){
    
    $dbs = Invoke-SqlCmd -ServerInstance $server -Query "select name from sys.databases where database_id in (1,3,4)"
    $pathname= "\\HIKARUDC\Backups\"+$server.Replace('\','_')
    if(!(test-path $pathname)){New-Item $pathname -ItemType directory } 
    foreach ($db in $dbs.name){
        $dbname = $db.TrimEnd()
        $sql = "BACKUP DATABASE $dbname TO DISK='$pathname\$dbname.bak' WITH COMPRESSION,INIT"
        Invoke-SqlCmd -ServerInstance $server -Query  $sql
    }
}

dir 'C:\Backups' -recurse