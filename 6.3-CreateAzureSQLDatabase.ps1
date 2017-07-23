#Set variables
$resourcegroup = 'IntroAzureSQL'
$location = 'West US'
$servername = 'msf-azugsrv'
$dbname = 'msf-sqlintrodb'
$localIP = (Invoke-WebRequest -Uri https://api.ipify.org).Content.trim()

$pw = ConvertTo-SecureString -AsPlainText -Force 'Buzz@ff!'
$cred = New-Object pscredential ('the_dude',$pw)


#Create Resource Group to hold SQL components
New-AzureRmResourceGroup -Name $resourcegroup -Location $location

#Create SQL Server
New-AzureRmSqlServer -ResourceGroupName $resourcegroup -Location $location -ServerName $servername -SqlAdministratorCredentials $cred -ServerVersion '12.0'

#Create Server Firewall rules
New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourcegroup -ServerName $servername -AllowAllAzureIPs
New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourcegroup -ServerName 'msf-azugsrv' -FirewallRuleName 'AzureGlobalBC' -StartIpAddress $localIP -EndIpAddress $localIP

New-AzureRmSqlDatabase -ResourceGroupName $resourcegroup -ServerName $servername -Edition Basic -DatabaseName $dbname

#Connect SSMS to the new session
$cmd = "SSMS -S '$servername.database.windows.net' -d 'master' -U '$($cred.UserName)' -p '$($cred.GetNetworkCredential().Password)' -nosplash"# 'C:\TEMP\IntroToAzureSQL.sql'"
Invoke-Expression $cmd
