#SQLInventory example
#first, make sure database objects exist
#.\SQLInventoryObjects.sql

#import the module
Import-Module SQLInventory -Verbose
Get-command -Module SQLInventory

#note that the -Verbose tells us the verb it's not happy about and recommends a compliant alternative

#Open the module code and look at it


#run the primary inventory collection function
Get-SQLInventory -invlist @('localhost','localhost\ALBEDO')