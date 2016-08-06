#Cmdlets - the core functionality
Get-Command
Get-Command | Measure-Object #Don't worry about the pipe

Get-Command -Name *New*

Get-Help Get-Command
Get-Help Get-Command -Full
Get-Help Get-Command -ShowWindow
Get-Help Get-Command -Online

#More than just cmdlets, we also have topics
get-help about*

#Practical use
Get-Command 'New*Firewall*'

Get-Help New-NetFirewallRule -ShowWindow

#To find out the current time, use Get-Date
Get-Date

#If we want to create a new file or directory, we use New-Item
New-Item -ItemType Directory -Path 'C:\Test'

#Want to see if something is there? Use Test-Path
Test-Path 'C:\Test'

#There are various ways to write output. If we want to write to a file, we can use Out-File
Out-File -InputObject 'The quick brown fox jumps over the lazy dog.' -FilePath 'C:\Test\Dummy.txt'

#We don't have to use cmdlets to do everything, we can call executables
notepad.exe 'C:\Test\Dummy.txt'

#To delete it, we can use Remove-Item (since we're removing a directory, we need to use -recurse and -force to remove everything in it.)
Remove-Item -Path 'C:\Test' -Recurse -Force

#We can test connections with Test-Connection. It's like ping, but while ping is it's own executable, this is part of the language
Test-Connection PICARD

#Get-ChildItem gets all the contents of a directory
Get-ChildItem C:\

#Cmdlets can have aliases to make them easier to use
#dir is and alias for Get-ChildItem
dir C:\

#We can see all the aliases for a cmdlet
Get-Alias -Definition Get-ChildItem

#Another example is 'ps', which lists all of our running processes.
ps

#This is aliased to Get-Process
Get-alias -Name ps
Get-Process

#Want to clear the screen?  This is clearing the host.
Clear-Host
Get-Alias -Definition Clear-Host

#Aliases should be used when working adhoc. If writing a script, use the full cmdlet name. The next guy might be you!