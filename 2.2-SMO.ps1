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
if(Test-Path C:\IntroToPowershell\logins.sql) {Remove-Item C:\IntroToPowershell\logins.sql}
$logins= $smoserver.Logins
foreach($login in $logins) {$login.Script() | Out-File C:\IntrotoPowershell\logins.sql}

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