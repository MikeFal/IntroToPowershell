#Load the SMO assembly
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

#Now we'll create an object for our server
#The default is the localhost, but we can pass an instance name if we wanted something specific
$smoserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') 'localhost'

#What type of object is it?
$smoserver.GetType()

#This is the same type of object used by the provider
(Get-Item SQLSERVER:\SQL\localhost\DEFAULT).GetType()

#Call the .Databases property
$smoserver.Databases

#This should look familiar
dir SQLSERVER:\SQL\localhost\DEFAULT\Databases -Force

#Everything we work with directly in the provider is just way to access SMO objects.

#Recalling our Get-SqlDatabase call, we can reference the msdb database as part of the SMO objects
#The SMO supports a named array index
$smoserver.Databases['msdb']

#use the properties and methods via the SMO gives us direct access to a lot of settings
$smodb = New-Object ('Microsoft.SqlServer.Management.Smo.Database') ($smoserver,'PowershellLab')
$smodb.Script()

$smodb.Create()

$smoserver.Databases['PowershellLab']

#Not only can we look at properties, we can also alter them
#Note, though, that we need to use the .Alter() method when we make changes to apply them to the database
$smodb.ReadOnly = $true
$smodb.Alter()

$smodb | Select-Object name,ReadOnly

#Some properties can't be changed directly, but can be done using the methods.
$smodb.Owner
$smodb.ReadOnly = $false
$smodb.Alter()
$smodb.SetOwner('sa')
$smodb.Owner

#why does the object not show the change in ownership? Because it is in memory.
#We need to refresh the object to make sure it represents the current state.
$smodb.Refresh()
$smodb.Owner

#Finally, we can get rid of the database using the .Drop() method
$smodb.Drop()