#SQL Agent Job example

#Prep the demo by clearing out current backups
dir C:\Backups\ -Recurse | rm -Recurse -Force

#backup your databases
#get a collection of databases
$dbs = Invoke-Sqlcmd -ServerInstance localhost -Database tempdb -Query "SELECT name FROM sys.databases WHERE database_id > 4"

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

#now, copy and paste this into an agent job and schedule it!