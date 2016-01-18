#Let's create a simple string variable
$simple = 'Hello'

#Look at its properties and methods
$simple | Get-Member

#Now call some of these
$simple.Length
$simple.IndexOf('l')
$simple.ToUpper()
$simple
 
#Now try some concatenation and interpolation. Notice the differences.
$simple + ' world!'
"$simple world!"
'$simple world!'

#Let's try some file manipulation
$directory = New-Item 'C:\PowershellLab' -ItemType Directory

#Explore the properties and methods. Notice what types of objects each method or property returns.
$directory | Get-Member

$directory
$directory.GetType()
$directory.Parent
$directory.Name
$directory.FullName
$directory.CreationTime

#Now let's make a new file
Set-Location $directory
$file = New-Item -ItemType File -Name Junk.txt

$file | Get-Member

$file
$file.GetType()
$file.Parent
$file.Name
$file.FullName
$file.CreationTime

#Creating this new file can affect our $directory variable
$directory.GetFiles()

#Let's clean up
Set-Location C:\
Remove-Item C:\PowershellLab -Recurse -confirm