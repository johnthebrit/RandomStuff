using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$computername = $Request.Query.ComputerName
if (-not $computername) {
    $computername = $Request.Body.ComputerName
}

Import-Module Az.ResourceGraph

$statusGood = $true

$GraphSearchQuery = "Resources
    | where type =~ 'Microsoft.Compute/virtualMachines'
    | where properties.osProfile.computerName =~ '$computername'
    | join (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
    | project VMName = name, CompName = properties.osProfile.computerName, RGName = resourceGroup, SubName, SubID = subscriptionId"

try {
    $VMresource = Search-AzGraph -Query $GraphSearchQuery
}
catch {
    $statusGood = $false
    Write-Error "Failure running Search-AzGraph, $_"
}

if($statusGood -and ($null -ne $VMresource))
{
    $ValueObject= [PSCustomObject]@{"Status"="Success";"ComputerName"="$ComputerName";"VMName"="$($VMresource.VMName)";"ResourceGroup"="$($VMresource.RGName)";"Subscription"="$($VMResource.SubID)"}
    $ValueJSON = ConvertTo-Json($ValueObject)
    $status = [HttpStatusCode]::OK
}
elseif ($statusGood -and ($null -eq $VMresource))
{
    $ValueJSON = "{`"Status`": `"Computer name not found`"}"
    $status = [HttpStatusCode]::OK
}
else
{
    $ValueJSON = "{`"Status`": `"Failed`"}"
    $status = [HttpStatusCode]::BadRequest
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $ValueJSON
})
