#List clouds DM01
Get-AzEnvironment

#Show regions
Get-AzLocation | ft

#View the IP addresses for storage in South Central US DM02
$serviceTags = Get-AzNetworkServiceTag -Location southcentralus
($serviceTags.Values | Where-Object {$_.Name -eq "Storage.SouthCentralUS"}).Properties.AddressPrefixes
($serviceTags.Values | Where-Object {$_.Name -eq "Storage.SouthCentralUS"}).Properties.AddressPrefixes.count
