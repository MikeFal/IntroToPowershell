#Operators and variable comparison
Get-Help about_operators

#Symbols like '>' and '<' mean different things in standard shell scripting.

#You use -lt, -ne, -eq, and other phrases are used to perform logical compariso
'1 -eq 2 returns: ' + (1 -eq 2)
'1 -lt 2 returns: ' + (1 -lt 2)

#For multiple conditions, use -and and -or
'1 -eq 1 -or 1 -gt 2 returns:' + (1 -eq 1 -or 1 -gt 2)
'1 -eq 1 -and 1 -gt 2 returns:' + (1 -eq 1 -and 1 -gt 2)

#Powershell also has control flow structures that you can use
#if(){
#}

#while/until(){
#}
#do{
#}while/until()

#foreach(){
#}

#switch(){
#}

Get-Help about_If
Get-Help about_While
Get-Help about_ForEach
Get-Help about_Switch

#Use If to check for things, like if a file or directory exists (and what to do if it doesn't)
New-Item -ItemType Directory -Path 'C:\TEMP'

If((Test-Path 'C:\TEMP') -eq $false){
    New-Item -ItemType Directory -Path 'C:\TEMP'
}

Remove-Item -Recurse 'C:\TEMP'
If((Test-Path 'C:\TEMP') -eq $false){New-Item -ItemType Directory -Path 'C:\TEMP'}

#while or until do things based on their conditions
#do is sytnax that allows you to put the while/until at the end of the loop instead of the beginning
$x=0
while($x -lt 10){
    New-Item -ItemType File -Path "C:\TEMP\WhileJunk$x.txt"
    $x++
}
cls
dir C:\TEMP

#We can also use for loops
for($y=0;$y -lt 10;$y++){
    New-Item -ItemType File -Path "C:\TEMP\ForJunk$y.txt"
}
cls
dir C:\TEMP

#You can deal with all the files as a collection
$files = dir C:\TEMP\ 
foreach($file in $files){
     Move-Item $file.FullName ($file.FullName -replace "txt","log")
}
#cls
dir C:\TEMP

#cleanup
dir C:\Temp | Remove-Item -Confirm

#Create an error
$x = 1/0

#We can pull out the most recent error if necessary
$Error[0]
$Error[0] | gm

#Try/Catch/Finally allow us to better handle errors
#Note that when we use catch, the red text doesn't show up.
cls
$x = 1
try{
    $x = 1/0
}
catch{
    Write-Warning "Operation failed."
}
finally{
    $x = 0
}

"`$x is $x"

#We can use throw or Write-Error to generate error messages
Write-Error "Something is wrong on the holodeck!"

throw "Something else is wrong on the holodeck!!"

#Write-Error does not respect Try/Catch and will immediately return an error message
#throw respects Try/Catch

try{
    Write-Error "Something is wrong on the holodeck!"
}
catch{
    Write-Warning "Something happened"
}

try{
    throw "Something else is wrong on the holodeck!!"
}
catch{
    Write-Warning "Something happened"
}