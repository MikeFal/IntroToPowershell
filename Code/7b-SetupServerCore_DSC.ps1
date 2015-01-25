Write-Warning "Disable the firewall for DEMONSTRATION PURPOSES ONLY"
Set-NetFirewallProfile -Profile * -Enabled False

#create service account
$account="sqlsvc"
$pw="5qlp@55w0rd"

$comp=[ADSI] "WinNT://$ENV:ComputerName"
$user=$comp.Create("User",$account)
$user.SetPassword($pw)
$user.UserFlags = (65536+64)
$user.SetInfo()