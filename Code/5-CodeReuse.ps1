#Code reuse and extension
#Reusing scripts
#open 5a-FileCount.ps1

#now call the script
C:\IntroToPowershell\5a-FileCount.ps1 'C:\IntroToPowershell\'

#We can convert the script to a function call for better reuse
#open 5b-FileCount_Function.ps1
C:\IntroToPowershell\5b-FileCount_Function.ps1 'C:\IntroToPowershell\'

#funcations can be extremely useful for code reuse.  For example, if we re-wrote our code for getting a free space report:

function Get-FreeSpace{
    param([string] $hostname = ($env:COMPUTERNAME))

	gwmi win32_volume -computername $hostname  | where {$_.drivetype -eq 3} | Sort-Object name `
	 | ft name,label,@{l="Size(GB)";e={($_.capacity/1gb).ToString("F2")}},@{l="Free Space(GB)";e={($_.freespace/1gb).ToString("F2")}},@{l="% Free";e={(($_.Freespace/$_.Capacity)*100).ToString("F2")}}

}

Get-FreeSpace PICARD

#They can get pretty advanced
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

        $logfile.size = $CurrSize
        $logfile.Alter()
    }
}

#But once you write it, it's easy to call
Expand-SqlLogFile -DatabaseName corruptme -LogSizeMB 12000

#We can put functions in the profile, giving us a re-usable toolkit
#working with the profile
#easiest way to edit is...
notepad $profile

#The profile may not exist, so you'd have to create it
#Let's rename the profile so we can create it, then we'll clean up afterwards.
$profilebak = "$profile.bak"
Move-Item $profile $profilebak

if(!(Test-Path $profile)){New-Item -Path $profile -ItemType file -Force}

#see, created.  Boom.  Now I'm going to move the previous profile back.
Remove-Item $profile
Move-Item $profilebak $profile

#We can use any of the functions in the profile, they're loaded at session start
Get-FreeSpace

#Add log growth function
notepad $profile

#If we make changes, we can reload by "executing" the profile
. $profile

#now we can use the added function
Expand-SqlLogFile -DatabaseName corruptme -LogSizeMB 24000

#Working with modules
#We can get a listing of all our available modules
Get-Module -ListAvailable

#SQLPS is provided with SQL2012 client tools
#It provides the SQLPS provider as well as some functions
Get-Command -Module SQLPS

#What gets used a lot is Invoke-SqlCmd, a wrapper for sqlcmd

#We can also write our own modules to extend Powershell
#let's take our file count function, open 5c-FileCount_module.psm1
#once we import it, we can re-use it
Import-Module C:\IntroToPowershell\5c-FileCount_module.psm1

Get-FileCount 'C:\IntroToPowershell\'

#Open up the SQLCheck module and examine the Test-SQLConnection function
#Now let's load the module
Import-Module SQLCheck

#Now that function is available to us as if
Test-SQLConnection -Instances @('PICARD','PICARD\WESLEY','NotAValidServer')

#Cool. Now let's have some fun

$out = @()
for($port=1430;$port -le 1450;$port++){
    $row = Test-SQLConnection -Instances "PICARD,$port" | select InstanceName,StartupTime,@{name='Host';expression={'PICARD'}},@{name='Port';expression={"$port"}}
    $out+=$row
}

$out | Where-Object {$_.StartupTime -ne $null} | Format-Table


$CMS='PICARD'
$servers=@((dir "SQLSERVER:\SQLRegistration\Central Management Server Group\$CMS").Name)

$servers+=$cms
Test-SQLConnection -Instances $servers