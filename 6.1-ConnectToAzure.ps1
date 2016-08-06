#Must be run from an elevated session
Install-Module Azure
Install-Module AzureRM

#What do we have?
Get-Module -ListAvailable *Azure*

#Available Cmdlets?
Get-Command -Module Azure
Get-Command -Module Azure | Measure-Object 

#Get-Command won't work for AzureRM, use it for the individual Module
Get-Command -Module AzureRM.Sql

#Let's get logged in
Add-AzureAccount
Get-AzureSubscription
Get-AzureSubscription | Where-Object {$_.DefaultAccount -like '*outlook.com'} | Select-AzureSubscription

#Now for AzureRM
Add-AzureRmAccount
Get-AzureRmSubscription