#SMO
#Powershell can acess the .NET SMO libraries
#All the SMO classes are loaded with the module, but if you load them separately you can use the following syntax
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

$smoserver = new-object 'Microsoft.SqlServer.Management.Smo.Server' 'TARKIN' 

#We can now interact with the server as it is an object
$smoserver | Get-Member
$smoserver.VersionString

#We can also drilldown into the parts of the server
$smoserver.Databases

#now we have a table object with its own properties
$sysjobs = $smoserver.Databases["msdb"].Tables["sysjobs"]
$sysjobs | Get-Member
$sysjobs.Indexes[0].Script()
$sysjobs.Script()

#we can now make collections
if(Test-Path C:\Temp\logins.sql) {Remove-Item C:\Temp\logins.sql}
$smoserver.Logins | ForEach-Object {$_.Script() | Out-File C:\Temp\logins.sql -Append}

notepad C:\Temp\logins.sql

#we can also create objects
#this is a little trickier

$db = New-Object ('Microsoft.SqlServer.Management.Smo.Database') ($smoserver,'SMOTest')
$db | Get-Member

#Just creating the new object doesn't mean it's created (look in SMO)
#so let's create it
$db.Create()

dir SQLSERVER:\SQL\TARKIN\DEFAULT\DATABASES

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
dir SQLSERVER:\SQL\TARKIN\DEFAULT\DATABASES

#Cleanup!
$db.Drop()