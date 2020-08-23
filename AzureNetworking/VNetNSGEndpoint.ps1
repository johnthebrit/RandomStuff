$serviceTags = Get-AzNetworkServiceTag -Location southcentralus
$serviceTags.Values | Where-Object {$_.Name -eq "Storage.SouthCentralUS"}
($serviceTags.Values | Where-Object {$_.Name -eq "Storage.SouthCentralUS"}).Properties.AddressPrefixes
($serviceTags.Values | Where-Object {$_.Name -eq "Storage.SouthCentralUS"}).Properties.AddressPrefixes.count
