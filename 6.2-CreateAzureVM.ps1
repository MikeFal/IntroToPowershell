#Login in to your AzureRM account
Login-AzureRMAccount

#Initialize values
$rgname = 'IntroToAzureVM'
$locName = 'East US 2'
$storage = 'IntroToAzureVMStorage'
$cred = Get-Credential -Message "Type the name and password of the local administrator account."
New-AzureRmResourceGroup -name $rgname -Location $locName

#Network assets
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name 'msftestsubnet' -AddressPrefix 10.0.0.0/24
$vnet = New-AzureRmVirtualNetwork -Name 'msftestvnet' -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $subnet
$pip = New-AzureRmPublicIpAddress -Name 'msftestip' -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic -DomainNameLabel 'msf-introvm-sql'
$nic = New-AzureRmNetworkInterface -Name 'msftestnic' -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id

#Create storage account, declare VHD storage paths
$storage = New-AzureRmStorageAccount -ResourceGroupName $rgname -Name 'msfintrotoazurevm' -Type Standard_LRS -Location $locName
$OSPath = $storage.PrimaryEndpoints.Blob.ToString() + "vhds/IntroToAzureOSDisk.vhd"
$DataPath = $storage.PrimaryEndpoints.Blob.ToString() + "vhds/IntroToAzureDataDisk.vhd"

#Find Image
Get-AzureRmVMImagePublisher -Location 'East US 2' | Where-Object {$_.PublisherName -like '*SQL*'}
Get-AzureRmVMImageOffer -Location 'East US 2' -PublisherName MicrosoftSQLServer
Get-AzureRmVMImageSku -Location 'East US 2' -PublisherName MicrosoftSQLServer -Offer SQL2016-WS2012R2

#Build VM configuration
$vm = New-AzureRmVMConfig -VMName 'IntroToAzureVM' -VMSize "Standard_DS1_V2"
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName 'IntroToAzureVM' -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftSQLServer -Offer SQL2016-WS2012R2 -Skus SQLDEV -Version "latest"
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
$vm = Set-AzureRmVMOSDisk -VM $vm -Name "IntroToAzureOS" -VhdUri $OSPath -CreateOption fromImage
$vm = Add-AzureRmVMDataDisk -VM $vm -Name "IntroToAzureData" -VhdUri $DataPath -Lun 0 -DiskSizeInGB 100 -CreateOption Empty -Caching None

#Create Azure VM
New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $vm

mstsc /v:msf-introvm-sql.eastus2.cloudapp.azure.com

#Run on VM to attach and format the volume
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!DO NOT RUN THIS ON YOUR LOCAL MACHINE!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Initialize-Disk -Number 2 -PartitionStyle MBR
New-Partition -DiskNumber 2 -UseMaximumSize -DriveLetter F
Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel SQLFiles -AllocationUnitSize 65536 -Confirm:$false

