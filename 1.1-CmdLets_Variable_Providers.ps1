#A few things before we get started(these need to be run as administrator)
Update-Help
Set-ExecutionPolicy RemoteSigned -Force

#Execution policies are a security feature to protect against malicious scripts
get-help about_execution_policies

#What version of Powershell are we using?
$PSVersionTable

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

#Cmdlets can have aliases to make them easier to use
dir C:\

#dir is and alias for Get-ChildItem
Get-ChildItem C:\

#We can see all the aliases for a cmdlet
Get-Alias -Definition Get-ChildItem


#Variables and using variables
Get-Help about_variables -ShowWindow

#Powershell variables start with a $
$string="This is a variable"
$string

#We can use Get-Member to find out all the information on our objects
$string | Get-Member

#Powershell is strongly typed and uses .Net objects.
#Not just limited to strings and intgers

$date=Get-Date
$date
$date | gm #gm is the alias of Get-Member

#Because they are .Net types/classes, we can use the methods and properties.
$date.Day
$date.DayOfWeek
$date.DayOfYear
$date.ToUniversalTime()

#Powershell tries to figure out the variable type when it can(implicit types)
#We can also explicitly declare our type
[string]$datestring = Get-Date #could also use [System.String]
$datestring
$datestring|gm

#EVERYTHING is an object.  This means more than just basic types:
$file = New-Item -ItemType File -Path 'C:\TEMP\junkfile.txt'
$file | gm

$file.Name
$file.FullName
$file.Extension
$file.LastWriteTime

Remove-Item $file

#Concatenation and Interpolation
#The plus sign is used for concatenation

$temperature = 'Hot'
'Tea. Earl Grey. ' + $temperature + '.'

#We can use interpolation to make life easier and cleaner.
#Interpolation is a useful tool when working with variables, especially strings.
"Tea. Earl Grey. $temperature."
'Tea. Earl Grey. $temperature.'

#It is important to understand the difference between single and double quotes.

#` (the tick on the tilde key) is the escape character, use this when you need to get around special characters
"Tea. Earl Grey. `$temperature."

#cmdlets and functions will output objects.  You can work with them by using ()
(Get-ChildItem C:\Windows).Length

(Get-Date).AddDays(-3)

#Get-Help will give you the object type that the cmdlet outputs

#Arrays and collections
#Create a collection of commands starting with 'New'
$commands = Get-Command 'New*'
$commands.GetType()
$commands.Count

$commands[5] | gm

#You can create your own arrays
$commandarray = @('Make','It','So')
$commandarray

#You can merge and array with -Join
$commandarray -join ';'

#you can separate a string into an array with -split
$splitstring = 'Kirk,McCoy,Spock,Scott' -split ','
$splitstring
$splitstring.Count

#List all our Providers
Get-PSDrive

Get-PSDrive C | Get-Member

Get-PSDrive ENV | Get-Member

cd ENV:\ #Same as 'Set-Location ENV:\'
dir 

dir HKLM:\SOFTWARE

#we can easily refer to provider elements in some cases
$env:COMPUTERNAME
$env:UserName
$env:PATH

#More about providers when we talk about SQL Server