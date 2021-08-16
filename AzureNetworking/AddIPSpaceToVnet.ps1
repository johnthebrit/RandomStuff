Get-AzVirtualNetwork | fl name, resourcegroupname, AddressSpaceText
$vnet = Get-AzVirtualNetwork -Name VNet2 -ResourceGroupName RG-Networking
$vnet.AddressSpace.AddressPrefixes.Add("10.2.0.0/16")
$vnet | Set-AzVirtualNetwork