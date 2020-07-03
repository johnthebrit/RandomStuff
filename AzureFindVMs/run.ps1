using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

#Import Az.ResourceGraph (not required as loaded via requirements.psd1)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

#Set initial status
$statusGood = $true

# Interact with query parameters or the body of the request.
$ostype = $Request.Query.OSType

if (-not $ostype) {
    $ostype = $Request.Body.OSType
}

#Find the VM resource via the computername
$GraphSearchQuery = "Resources
| where type =~ 'Microsoft.Compute/virtualMachines'
| where properties.storageProfile.osDisk.osType =~ '$ostype'
| join kind=inner (ResourceContainers | where type=='microsoft.resources/subscriptions'| project SubName=name, subscriptionId) on subscriptionId
| project name, OSType = properties.storageProfile.osDisk.osType,CompName = properties.osProfile.computerName, RGName = resourceGroup,SubID = subscriptionId, SubName
"
$VMresources = Search-AzGraph -Query $GraphSearchQuery

if($VMresources -eq $null)
{
    $statusGood = $false
    $body = "Could not find a matching VM resource"
}
else
{
    $body = $VMresources
}

if(!$statusGood) {
    $status = [HttpStatusCode]::BadRequest
}
else {
    $status = [HttpStatusCode]::OK
}

$BodyJSON = ConvertTo-Json($body)


# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $BodyJSON
})
