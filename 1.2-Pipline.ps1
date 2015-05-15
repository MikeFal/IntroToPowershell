#Start exploring your objects by piping to Get-Member
[string]$string ="Earl Grey, hot."
$string | Get-Member

$integer=1
$integer | Get-Member

#You can also measure collections using Measure-Object
Get-Help about* | Measure-Object

#let's start expanding other commands
#Getting free space information

#Getting freespace for disk volumes
Get-WmiObject win32_volume | `
    where {$_.drivetype -eq 3} | `
    Sort-Object name | `
    Format-Table name, label,@{l="Size(GB)";e={($_.capacity/1gb).ToString("F2")}},@{l="Free Space(GB)";e={($_.freespace/1gb).ToString("F2")}},@{l="% Free";e={(($_.Freespace/$_.Capacity)*100).ToString("F2")}}

#remove old backup files
#nothing up my sleeve!
dir '\\PICARD\C$\Backups' -recurse

#clean out 'old' transaction log backups
dir '\\PICARD\C$\Backups' -Recurse | `
Where-Object {$_.Extension  -eq ".trn" -and $_.LastWriteTime -lt (Get-Date).AddHours(-3)} |`
Remove-Item -WhatIf