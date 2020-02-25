#Define base
$GitBasePath = 'C:\Users\john\OneDrive\projects\GIT\RandomStuff\SharedVHD'


$rgName = 'RG-SharedDisk-WCUS'
$location = 'westcentralus'

New-AzResourceGroup -Name $rgName -Location $location

#https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disks-shared-enable
#Create a shared disk

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile "$GitBasePath\SharedDiskCreate.json"

$sharedDisk = Get-AzDisk -ResourceGroupName $rgName -DiskName 'P15SharedDisk'
#https://docs.microsoft.com/en-us/azure/virtual-machines/windows/proximity-placement-groups
#Must be in the same PPG

$ppgName = "PPG-SharedDisk-WCUS"
$ppg = New-AzProximityPlacementGroup `
   -Location $location `
   -Name $ppgName `
   -ResourceGroupName $rgName `
   -ProximityPlacementGroupType Standard

#Use an availability set as well
$availsetName = "AS-SharedDisk-WCUS"
$availset = New-AzAvailabilitySet `
    -Location $location `
    -Name $availsetName `
    -ResourceGroupName $rgName `
    -Sku Aligned `
    -ProximityPlacementGroupId $ppg.Id `
    -PlatformUpdateDomainCount 1 `
    -PlatformFaultDomainCount 1 #value of 1 requured for shared vhd

#Create the VMs
$VNetName = "VNet-Infra-WCUS"
$VNetRG = "RG-Infra-WCUS"
$VNetSubnetName = "ClusterSubnet"

#Get the network subnet
$VNet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $VNetRG
$VNetSubnet = Get-AzVirtualNetworkSubnetConfig -Name $VNetSubnetName -VirtualNetwork $VNet

# Antimalware extension
$SettingsString = '{ "AntimalwareEnabled": true,"RealtimeProtectionEnabled": true}';
$allVersions= (Get-AzVMExtensionImage -Location $location -PublisherName "Microsoft.Azure.Security" -Type "IaaSAntimalware").Version
$typeHandlerVer = $allVersions[($allVersions.count)-1]
$typeHandlerVerMjandMn = $typeHandlerVer.split(".")
$typeHandlerVerMjandMn = $typeHandlerVerMjandMn[0] + "." + $typeHandlerVerMjandMn[1]

#Domain Join Strings
$string1 = '{
    "Name": "savilltech.net",
    "User": "savilltech.net\\john",
    "OUPath": "OU=Servers,DC=savilltech,DC=net",
    "Restart": "true",
    "Options": "3"
        }'
$string2 = '{ "Password": "<password>" }'

#Local Credential
$user = "localadmin"
$password = 'Pa55wordPa55word'
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword)

#Diagnostics account
$VMDiagName = "savmdiaglrs"
New-AzStorageAccount -ResourceGroupName $rgName -Location $location -Name $VMDiagName -SkuName Standard_LRS -Kind StorageV2

#VM Details
$VMSize = "Standard_D2s_v3"
$VMName = "savazuuswcfc01"  #and then repeat below for VMName 02

#Main VM configuration
# Create VM Object
$vm = New-AzVMConfig -VMName $VMName -VMSize $VMSize `
    -ProximityPlacementGroupId $ppg.Id -AvailabilitySetId $availset.Id

$nic = New-AzNetworkInterface -Name ('nic-' + $VMName) -ResourceGroupName $rgName -Location $location `
    -SubnetId $VNetSubnet.Id -PrivateIpAddress $VMIP

# Add NIC to VM
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id

# VM Storage
$vm = Set-AzVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2019-Datacenter -Version latest
$vm = Set-AzVMOSDisk -VM $vm  -StorageAccountType Premium_LRS -DiskSizeInGB 512 `
    -CreateOption FromImage -Caching ReadWrite -Name "$VMName-OS"
$vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $VMName `
    -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

# Connect the shared disk
$vm = Add-AzVMDataDisk -VM $vm -Name "P15SharedDisk" -CreateOption Attach `
    -ManagedDiskId $sharedDisk.Id -Lun 0

$vm = Set-AzVMBootDiagnostic -VM $vm -Enable -ResourceGroupName $rgName -StorageAccountName $VMDiagName

# Create Virtual Machine
New-AzVM -ResourceGroupName $rgName -Location $location -VM $vm

Set-AzVMExtension -ResourceGroupName $rgName -VMName $VMName -Name "IaaSAntimalware" `
    -Publisher "Microsoft.Azure.Security" -ExtensionType "IaaSAntimalware" `
    -TypeHandlerVersion $typeHandlerVerMjandMn -SettingString $SettingsString -Location $location

Set-AzVMExtension -ResourceGroupName $rgName -VMName $VMName -ExtensionType "JsonADDomainExtension" `
    -Name "joindomain" -Publisher "Microsoft.Compute" -TypeHandlerVersion "1.3" -Location $location `
    -SettingString $string1 -ProtectedSettingString $string2

#Waiting until ProvisioningState Succeeded
Get-AzVMExtension -Name "joindomain" -ResourceGroupName $rgName -VMName $VMName -Status


#Creating the cluster from savazuuswcfc01
#https://docs.microsoft.com/en-us/windows-server/failover-clustering/create-failover-cluster

$servers = ('savazuuswcfc01', 'savazuuswcfc02')
foreach ($server in $servers) {Install-WindowsFeature –Name Failover-Clustering –IncludeManagementTools -ComputerName $server}

#Bounce the servers after clustering installed
Restart-Computer -ComputerName $servers

#Here I init disk as GPT, created partition and formatted NTFS

#Test the cluster
Test-Cluster –Node ("savazuuswcfc01", "savazuuswcfc02") -ReportName c:\temp\clustervalidate-02232020.htm

#Use distributed network name for cluster since in Azure and Server 2019. Not using an ILB to host a singleton IP for the cluster
New-Cluster –Name savazuuswcfcl1 –Node ("savazuuswcfc01", "savazuuswcfc02") -ManagementPointNetworkType Distributed

#In the OU that the cluster name exists give the cluster account, savazuuswcfcl1, rights to create computer objects so can add other roles
#https://docs.microsoft.com/en-us/windows-server/failover-clustering/prestage-cluster-adds#grant-the-cno-permissions-to-the-ou

#Post creation changed to cloud witness
#Made the shared disk a CSV
#Enable file services role on all servers
foreach ($server in $servers) {Install-WindowsFeature –Name FS-FileServer -ComputerName $server}

#Deploy the role
#https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/hh831718(v=ws.11)
Add-ClusterScaleOutFileServerRole -Name savazuuswcsofs -Cluster savazuuswcfcl1
#Create a share

Resolve-DnsName savazuuswcfcl1
Resolve-DnsName savazuuswcsofs

dir \\savazuuswcsofs\data

Get-SmbConnection | fl *
#Note is continuously available