$smosrv = new-object ('Microsoft.SqlServer.Management.Smo.Server') 'WORF'
$smosrv.Configuration.MaxServerMemory.ConfigValue = 2000
$smosrv.Configuration.MinServerMemory.ConfigValue = 0
$smosrv.Configuration.MaxDegreeOfParallelism.ConfigValue = 1
$smosrv.Configuration.OptimizeAdhocWorkloads.ConfigValue = 1
$smosrv.Alter()