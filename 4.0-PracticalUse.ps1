#SQL Connection test
function Test-SQLConnection{
    param([parameter(mandatory=$true)][string[]] $Instances)

    $return = @()
    foreach($InstanceName in $Instances){
        $row = New-Object –TypeName PSObject –Prop @{'InstanceName'=$InstanceName;'StartupTime'=$null}
        try{
            $check=Invoke-Sqlcmd -ServerInstance $InstanceName -Database TempDB -Query "SELECT @@SERVERNAME as Name,Create_Date FROM sys.databases WHERE name = 'TempDB'" -ErrorAction Stop -ConnectionTimeout 3
            $row.InstanceName = $check.Name
            $row.StartupTime = $check.Create_Date
        }
        catch{
            #do nothing on the catch
        }
        finally{
            $return += $row
        }
    }
    return $return
}

Test-SQLConnection -Instances 'PICARD'

#Now let's load the module
Import-Module SQLCheck

#Now that function is available to us as if
Test-SQLConnection -Instances @('PICARD','RIKER','NotAValidServer')

#Cool. Now let's have some fun
$out = @()
for($port=1430;$port -le 1440;$port++){
    $row = Test-SQLConnection -Instances "PICARD,$port" | select InstanceName,StartupTime,@{name='Host';expression={'PICARD'}},@{name='Port';expression={"$port"}}
    $out+=$row
}

$out | Where-Object {$_.StartupTime -ne $null} | Format-Table

$CMS='PICARD'
$servers=@((dir "SQLSERVER:\SQLRegistration\Central Management Server Group\$CMS").Name)
$servers+=$cms
Test-SQLConnection -Instances $servers


function Export-SQLDacPacs{
    param([string[]] $Instances = 'localhost',
          [string] $outputdirectory=([Environment]::GetFolderPath("MyDocuments"))
        )

#get the sqlpackage executable
$sqlpackage = get-childitem 'C:\Program Files (x86)\Microsoft SQL Server\120\DAC\bin\sqlpackage.exe'

#declare a select query for databases
$dbsql = @"
SELECT name FROM sys.databases
where database_id >4 and state_desc = 'ONLINE'
"@

#loop through each instance
foreach($instance in $Instances){
    #set processing variables
    $dbs = Invoke-Sqlcmd -ServerInstance $instance -Database tempdb -Query $dbsql
    $datestring =  (Get-Date -Format 'yyyyMMddHHmm')
    $iname = $instance.Replace('\','_')

    #extract each db
    foreach($db in $dbs.name){
        $outfile = Join-Path $outputdirectory -ChildPath "$iname-$db-$datestring.dacpac"
        $cmd = "& '$sqlpackage' /action:Extract /targetfile:'$outfile' /SourceServerName:$instance /SourceDatabaseName:$db"
        Invoke-Expression $cmd
        }
    }
}

#But once you write it, it's easy to call
Export-SQLDacPacs -instances 'PICARD' -outputdirectory 'C:\IntroToPowershell'

function Optimize-SQLMemory{
<#
.SYNOPSIS
 Configures a SQL Server instance per the Jonathan Kehayias' guidelines.
.DESCRIPTION
 This script will configure your SQL Server instance per the guidelines
 found in Jonathan Kehayias' blog post: http://www.sqlskills.com/blogs/jonathan/how-much-memory-does-my-sql-server-actually-need/
 The rules are:
 - 1GB for initial OS reserve
 - +1GB per 4GB server RAM up to 16GB
 - +1GB per 8GB server RAM above 16
.PARAMETER
 -target SQL instance name, i.e. localhost\SQL2012, DBASERVER01
 -apply Switch parameter, call if you want to actually apply the changes. Otherwise, a report will be produced.
.EXAMPLE
 Optimize-SQLMemory -instance DBASERVER01 -apply
#>

param([parameter(Mandatory=$true)][string] $target
 , [Switch] $apply
 )

#load SMO
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
$smoserver = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $target

$sqlhost = $smoserver.ComputerNamePhysicalNetBIOS

#set memory variables
$totalmem = (gwmi Win32_ComputerSystem -computername $sqlhost).TotalPhysicalMemory/1GB
$sqlmem = [math]::floor($totalmem)

#calculate memory
while($totalmem -gt 0){
 if($totalmem -gt 16){
 $sqlmem -= [math]::floor(($totalmem-16)/8)
 $totalmem=16
 }
 elseif($totalmem -gt 4){
 $sqlmem -= [math]::floor(($totalmem)/4)
 $totalmem = 4
 }
 else{
 $sqlmem -= 1
 $totalmem = 0
 }
}

#if not in debug mode, alter config. Otherwise report current and new values.
$srv = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $target
 "Instance:" + $target
 "Max Memory:" + $srv.Configuration.MaxServerMemory.ConfigValue/1024 + " -> " + $sqlmem
 "Min Memory:" + $srv.Configuration.MinServerMemory.ConfigValue/1024 + " -> " + $sqlmem/2
if($apply){
 $srv.Configuration.MaxServerMemory.ConfigValue = $sqlmem * 1024
 $srv.Configuration.MinServerMemory.ConfigValue = $sqlmem/2 * 1024
 $srv.Configuration.Alter()
 "Configuration Complete!"
 }
}

Optimize-SQLMemory -target 'PICARD'

function Measure-SQLExecution{
    param($instancename
        ,$databasename = 'tempdb'
        ,[Parameter(ParameterSetName = 'SQLCmd',Mandatory=$true)]$sqlcmd
        ,[Parameter(ParameterSetName = 'SQLScript',Mandatory=$true)]$sqlscript)

    $output = New-Object System.Object
    $errval = $null

    $output | Add-Member -Type NoteProperty -Name InstanceName -Value $instancename
    $output | Add-Member -Type NoteProperty -Name DatabaseName -Value $databasename
    $output | Add-Member -Type NoteProperty -Name StartTime -Value (Get-Date)

    if($sqlscript){
        $output | Add-Member -Type NoteProperty -Name SQL -Value $sqlscript
        $sqlout = Invoke-Sqlcmd -ServerInstance $instancename -Database $databasename -InputFile $sqlscript -ErrorVariable errval
    }
    else{
        $output | Add-Member -Type NoteProperty -Name SQL -Value $sqlcmd
        $sqlout = Invoke-Sqlcmd -ServerInstance $instancename -Database $databasename -Query $sqlcmd -ErrorVariable errval
    }


    $output | Add-Member -Type NoteProperty -Name EndTime -Value (Get-Date)
    $output | Add-Member -Type NoteProperty -Name RunDuration -Value (New-TimeSpan -Start $output.StartTime -End $output.EndTime)
    $output | Add-Member -Type NoteProperty -Name Results -Value $sqlout
    $output | Add-Member -Type NoteProperty -Name Error -Value $errval

    return $output
}

#Measure-SQLExecution -instancename 'localhost' -databasename 'demoPartition' -sqlcmd 'exec usp_loadpartitiondata;'

$total = @()
$total += Measure-SQLExecution -instancename 'PICARD' -databasename 'demoPartition' -sqlcmd 'truncate table dbo.orders;'
$total += Measure-SQLExecution -instancename 'PICARD' -databasename 'demoPartition' -sqlcmd 'exec usp_loadpartitiondata;'
$total += Measure-SQLExecution -instancename 'PICARD' -databasename 'demoPartition' -sqlcmd 'exec usp_fragmentpartition;'
$total

$total | Select-Object InstanceName,DatabaseName,StartTime,EndTime,SQL,RunDuration | Export-Csv -Path 'C:\Temp\ExecutionLog.csv' -NoTypeInformation
notepad 'C:\Temp\ExecutionLog.csv'


#SQLInventory example
#first, make sure database objects exist
#.\SQLInventoryObjects.sql
Invoke-Sqlcmd -ServerInstance PICARD -Database master -Query "IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'MSFADMIN') DROP DATABASE MSFADMIN;"
Invoke-Sqlcmd -ServerInstance PICARD -Database master -InputFile 'C:\IntroToPowershell\SQLInventoryObjects.sql'

#import the module
Import-Module SQLInventory -Verbose
Get-command -Module SQLInventory

#note that the -Verbose tells us the verb it's not happy about and recommends a compliant alternative

#Open the module code and look at it


#run the primary inventory collection function
$CMS='PICARD'
$servers=@((dir "SQLSERVER:\SQLRegistration\Central Management Server Group\$CMS").Name)

$servers+=$cms
Get-SQLInventory -invlist $servers -invserv 'PICARD' -invdb 'MSFADMIN'

Invoke-Sqlcmd -ServerInstance PICARD -Database MSFADMIN -Query 'SELECT * FROM dbo.InstanceInventory;' | ft
Invoke-Sqlcmd -ServerInstance PICARD -Database MSFADMIN -Query 'SELECT * FROM dbo.MachineInventory;' | ft
