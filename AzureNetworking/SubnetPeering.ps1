#Register the feature and check the status until registered
az feature register --namespace Microsoft.Network --name AllowMultiplePeeringLinksBetweenVnets
az feature show --name AllowMultiplePeeringLinksBetweenVnets --namespace Microsoft.Network --query 'properties.state' -o tsv

#Current known VNET routes
az network nic show-effective-route-table -n demovm974 -g RG-DemoVM --query "value[?starts_with(nextHopType, 'Vnet') || starts_with(nextHopType, 'VNet')].{NextHopType:nextHopType, AddressPrefix:join(',', addressPrefix)}" -o table

$subscriptionId = az account show --query "id" -o tsv
#Subnet level peering add
$remoteVnet = "/subscriptions/$subscriptionID/resourceGroups/RG-NetworkManager/providers/Microsoft.Network/virtualNetworks/vnet-scus-spoke3"
az network vnet peering create --name dev_scus_to_spoke3-scus --vnet-name Vnet-Dev-Connect-SCUS --resource-group RG-SCUSA --remote-vnet $remoteVnet `
  --allow-vnet-access --allow-forwarded-traffic `
  --peer-complete-vnet false --local-subnet-names infra --remote-subnet-names subnet2 subnet3

$remoteVnet = "/subscriptions/$subscriptionID/resourceGroups/RG-SCUSA/providers/Microsoft.Network/virtualNetworks/Vnet-Dev-Connect-SCUS"
az network vnet peering create --name spoke3-scus_to_dev_scus --vnet-name vnet-scus-spoke3 --resource-group RG-NetworkManager --remote-vnet $remoteVnet `
  --allow-vnet-access --allow-forwarded-traffic `
  --peer-complete-vnet false --local-subnet-names subnet2 subnet3 --remote-subnet-names infra

#Check the state of the peering
az network vnet peering list --vnet-name Vnet-Dev-Connect-SCUS --resource-group RG-SCUSA -o table

#What routes are known specific to VNET
az network nic show-effective-route-table -n demovm974 -g RG-DemoVM --query "value[?starts_with(nextHopType, 'Vnet') || starts_with(nextHopType, 'VNet')].{NextHopType:nextHopType, AddressPrefix:join(',', addressPrefix)}" -o table

#Clean up
az network vnet peering delete --name dev_scus_to_spoke3-scus --vnet-name Vnet-Dev-Connect-SCUS --resource-group RG-SCUSA
az network vnet peering delete --name spoke3-scus_to_dev_scus --vnet-name vnet-scus-spoke3 --resource-group RG-NetworkManager