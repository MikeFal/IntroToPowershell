#Code reuse and extension
#Reusing scripts
#open 3.1-FileCount.ps1

#now call the script
C:\IntroToPowershell\3.1-FileCount.ps1 'C:\IntroToPowershell\'
C:\IntroToPowershell\3.1-FileCount.ps1 'notvalid'

#We can convert the script to a function call for better reuse
#open 3.2-FileCount_Function.ps1
C:\IntroToPowershell\3.2-FileCount_Function.ps1 'C:\IntroToPowershell\'

#funcations can be extremely useful for code reuse.  For example, if we re-wrote our code for getting a free space report:

function Get-FreeSpace{
    param([string] $hostname = ($env:COMPUTERNAME))

	gwmi win32_volume -computername $hostname  | where {$_.drivetype -eq 3} | Sort-Object name `
	 | ft name,label,@{l="Size(GB)";e={($_.capacity/1gb).ToString("F2")}},@{l="Free Space(GB)";e={($_.freespace/1gb).ToString("F2")}},@{l="% Free";e={(($_.Freespace/$_.Capacity)*100).ToString("F2")}}

}

Get-FreeSpace PICARD
Get-FreeSpace localhost

#We can also write our own modules to extend Powershell
#let's take our file count function, open 5c-FileCount_module.psm1
#once we import it, we can re-use it
Import-Module C:\IntroToPowershell\3.3-FileCount_module.psm1

Get-FileCount 'C:\IntroToPowershell\'
Get-FileCount 'Not Valid'

#We can get a listing of all our available modules
Get-Module -ListAvailable

#working with the profile
#We can use any of the functions in the profile, they're loaded at session start
#This function is part of my default profile
Get-FreeSpace

#easiest way to edit is...
powershell_ise $profile

#The profile may not exist, so you'd have to create it
#Let's rename the profile so we can create it, then we'll clean up afterwards.
$profilebak = "$profile.bak"
Move-Item $profile $profilebak

if(!(Test-Path $profile)){New-Item -Path $profile -ItemType file -Force}
powershell_ise $profile

#Add 'Import-Module SQLPS -disablenamechecking'
#Add the following function
function Beam-MeUp{
    param([string] $target)
    "Scotty, beam $target up."
}

#If we make changes, we can reload by "executing" the profile
. $profile

Beam-MeUp -target Kirk
Beam-MeUp -target Spock

#see, created.  Boom.  Now I'm going to move the previous profile back.
Remove-Item $profile
Move-Item $profilebak $profile