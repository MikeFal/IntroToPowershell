#As we've seen already, the pipeline can be use with Get-Member
(Get-Date) | Get-Member

#A cmdlet will always process the -InputObject argument for the pipeline
#We can pass a string array to Out-File.
$OutFile = @('The quick brown fox','jumped over the lazy dog.')
New-Item 'C:\PowershellLab' -ItemType Directory
$OutFile | Out-File C:\PowershellLab\Lab1.txt

notepad C:\PowershellLab\Lab1.txt

#We can process objects across multiple pipelines
#Each new pipeline section will take the last processed object
$OutFile | Measure-Object | Out-File C:\PowershellLab\Lab2.txt

#note what gets written to the file
notepad C:\PowershellLab\Lab2.txt

#We can refer to the current object in the pipeline with the generic $_ variable
#In this example, we will filter on the LastWriteTime property of each file
#(nothing will return, this is ok)

Get-ChildItem C:\PowershellLab | Where-Object {$_.LastwriteTime -lt (Get-Date).AddDays(-1)} 

#Let's clean up
Set-Location C:\
Remove-Item C:\PowershellLab -Recurse -confirm