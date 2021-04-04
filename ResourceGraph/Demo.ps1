#1 Get basic info from ARM
Get-AzResource | Format-Table -AutoSize
Get-AzResource | Select-Object -First 3

#2 More detailed info via resource provider
Get-AzVM | Format-List

#3 Combination across 3 resources for VM, private IP and public IP
$VM=Get-AzVM -Name DEMOVM -ResourceGroupName RG-DEMOVM                  #VM resource
$nic = $vm.NetworkProfile.NetworkInterfaces[0].Id                       #references a NIC resoutce
$nicinfo = Get-AzNetworkInterface -ResourceId $nic                      #NIC resource
$privIP = $nicinfo.IpConfigurations[0].PrivateIpAddress                 #NIC property
$pubipid = $nicinfo.IpConfigurations[0].PublicIpAddress.Id              #references a public IP resource
$pubipaddr = (Get-AzPublicIpAddress | Where-Object {$_.Id -eq $pubipid}).IpAddress   #public IP property
Write-Output "VM $($VM.Name) has private IP $privIP and public IP $pubipaddr"

#4 Limits with ARM
#Look at HTTP response and the x-ms-ratelimit-remaining-subscription-reads
Clear-Host
Get-AzResourceGroup -Debug

#OR REST
#Create the auth header based on my current context
$azContext = Get-AzContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
}

$r = Invoke-WebRequest -Uri https://management.azure.com/subscriptions/466c1a5d-e93b-4138-91a5-670daf44b0f8/resourcegroups?api-version=2016-09-01 -Method GET -Headers $authHeader
$r.Headers["x-ms-ratelimit-remaining-subscription-reads"]


#Azure Resource Graph

#5 Show quota for resource graph note the x-ms-user-quota-resets-after and x-ms-user-quota-remaining values
Search-AzGraph -Query 'Resources | where type =~ "microsoft.compute/virtualmachines" | limit 5' -Debug

$Body = @"
{    "subscriptions": [
        "466c1a5d-e93b-4138-91a5-670daf44b0f8"
    ],
    "query": "Resources | project name, type | limit 5"
}
"@
$r = Invoke-WebRequest -Uri https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2019-04-01 -Method POST -Body $body -Headers $authHeader
$r.Headers
$r.Content

#6 Big query from PowerShell using a here-string
$query = @"
Resources
| where type =~ 'microsoft.compute/virtualmachines'
| extend nics=array_length(properties.networkProfile.networkInterfaces)
| mv-expand nic=properties.networkProfile.networkInterfaces
| where nics == 1 or nic.properties.primary =~ 'true' or isempty(nic)
| project vmId = id, vmName = name, nicId = tostring(nic.id)
| join kind=leftouter (
  Resources
  | where type =~ 'microsoft.network/networkinterfaces'
  | extend ipConfigsCount=array_length(properties.ipConfigurations)
  | mv-expand ipconfig=properties.ipConfigurations
  | where ipConfigsCount == 1 or ipconfig.properties.primary =~ 'true'
  | project nicId = id, privateIp = ipconfig.properties.privateIPAddress, publicIpId = tostring(ipconfig.properties.publicIPAddress.id)) on nicId
| project-away nicId1
| project vmId, vmName, privateIp, publicIpId
| join kind=leftouter (
  Resources
  | where type =~ 'microsoft.network/publicipaddresses'
  | project publicIpId = id, publicIpAddress = properties.ipAddress) on publicIpId
| project-away publicIpId1, publicIpId
"@
Search-AzGraph -Query $query | Format-List

#7 Look for changes on storage account via the change tracking of resource graph
$Body = @"
{
    "resourceId": "/subscriptions/466c1a5d-e93b-4138-91a5-670daf44b0f8/resourceGroups/RG-SCUSA/providers/Microsoft.Storage/storageAccounts/sascussavilltech2",
    "interval": {
        "start": "2021-03-28T00:00:00.000Z",
        "end": "2021-03-29T00:00:00.000Z"
    },
    "fetchPropertyChanges": true
}
"@
$r = Invoke-WebRequest -Uri https://management.azure.com/providers/Microsoft.ResourceGraph/resourceChanges?api-version=2018-09-01-preview -Method POST -Body $body -Headers $authHeader
$r.Content | ConvertFrom-Json | ConvertTo-Json -depth 100 #make it look pretty