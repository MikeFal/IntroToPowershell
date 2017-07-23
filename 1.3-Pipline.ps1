#First, clear the screen
Clear-Host

#Start exploring your objects by piping to Get-Member
[string]$string ="Earl Grey, hot."
$string | Get-Member

$integer=1
$integer | Get-Member

#You can also measure collections using Measure-Object
Get-Help about* | Measure-Object

#Remember our file writing example? Well, we can use the pipeline for this to make it easier
New-Item -ItemType Directory -Path 'C:\Test'
'The quick brown fox jumps over the lazy dog. Again.' | Out-File -FilePath 'C:\Test\Dummy.txt' -Append
notepad 'C:\Test\Dummy.txt'


#We can also use it for creating and removing things
$files = @('Junk1.txt','Junk2.txt','Junk3.txt','Junk4.txt')
$files | ForEach-Object {New-Item -ItemType file -Path "C:\Test\$_"}

Clear-Host
dir C:\Test

dir C:\Test | Remove-Item -WhatIf

Clear-Host
dir C:\Test

#let's start expanding other commands
#Getting free space information

#Get-WMIObject gives us access to different parts of the Windows OS
#Getting freespace for disk volumes uses win32_Volume
Get-WmiObject win32_volume | 
    where {$_.drivetype -eq 3} | 
    Sort-Object name | 
    Format-Table name, label,@{l="Size(GB)";e={($_.capacity/1gb).ToString("F2")}},@{l="Free Space(GB)";e={($_.freespace/1gb).ToString("F2")}},@{l="% Free";e={(($_.Freespace/$_.Capacity)*100).ToString("F2")}}

#remove old backup files
#nothing up my sleeve!
Get-ChildItem '\\TARKIN\C$\Backups' -recurse

#clean out 'old' TARKIN log backups
Get-ChildItem '\\TARKIN\C$\Backups' -Recurse | 
    Where-Object {$_.Extension  -eq ".trn" -and $_.LastWriteTime -lt (Get-Date).AddHours(-3)} |
    Remove-Item -WhatIf