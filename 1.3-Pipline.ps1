#Start exploring your objects by piping to Get-Member
[string]$string ="Earl Grey, hot."
$string | Get-Member

$integer=1
$integer | Get-Member

#You can also measure collections using Measure-Object
Get-Help about* | Measure-Object

#Remember our file writing example? Well, we can use the pipeline for this to make it easier
New-Item -ItemType Directory -Path 'C:\Test'
'The quick brown fox jumps over the lazy dog. Again.' | Out-File -FilePath 'C:\Test\Dummy.txt'
notepad 'C:\Test\Dummy.txt'

#We can also use it for removing things
New-Item -ItemType file -Path 'C:\Test\Junk1.txt'
New-Item -ItemType file -Path 'C:\Test\Junk2.txt'
New-Item -ItemType file -Path 'C:\Test\Junk3.txt'
New-Item -ItemType file -Path 'C:\Test\Junk4.txt'

cls
dir C:\Test

dir C:\Test | Remove-Item

cls
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
Get-ChildItem '\\PICARD\C$\Backups' -recurse

#clean out 'old' transaction log backups
Get-ChildItem '\\PICARD\C$\Backups' -Recurse | 
    Where-Object {$_.Extension  -eq ".trn" -and $_.LastWriteTime -lt (Get-Date).AddHours(-3)} |
    Remove-Item -WhatIf