#SQL Agent Job example

#backup your databases
#get a collection of databases
$dbs = Invoke-Sqlcmd -ServerInstance localhost -Database tempdb -Query "SELECT name FROM sys.databases WHERE database_id > 4"

#Get a formatted string for the datetime
$datestring =  (Get-Date -Format 'yyyyMMddHHmm')

#loop through the databases
foreach($db in $dbs.name){
    $dir = "C:\Temp\$db"
    #does the backup directory exist?  If not, create it
    if(!(Test-Path $dir)){New-Item -ItemType Directory -path $dir}
    
    #Get a nice name and backup your database to it
    $filename = "$db-$datestring.bak"
    $backup=Join-Path -Path $dir -ChildPath $filename
    Backup-SqlDatabase -ServerInstance localhost -Database $db -BackupFile $backup 
    #Delete old backups
    Get-ChildItem $dir\*.bak| Where {$_.LastWriteTime -lt (Get-Date).AddMinutes(-1)}|Remove-Item

}

#now, copy and paste this into an agent job and schedule it!