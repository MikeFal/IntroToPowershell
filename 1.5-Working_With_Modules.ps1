#Get Loaded Modules
Get-Module

#See locally installed modules
Get-Module -ListAvailable

#Load a Module for use
#With PowerShell 3.0, modules can auto-load
Import-Module Rubrik

#List commands in a module
Get-Command -Module Rubrik

#Using the PowerShell Gallery (PowerShell 5.0+)
#Find a module in the gallery (https://www.powershellgallery.com/)
Find-Module Azure

#Install a module from the Gallery
#Must be done from an admin session
Install-Module Azure -Force

#Update an installed module with the latest version
Update-Module Azure

#Uninstall a module
Uninstall-Module Azure -WhatIf