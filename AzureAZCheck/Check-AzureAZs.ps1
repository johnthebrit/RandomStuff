function Check-AzureAzs {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$subList,
        [string]$locationName
    )

    $token = Get-AzAccessToken #This will default to Resource Manager endpoint
    $authHeader = @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $token.Token
    }

    $subID = $subList[0]
    $region = $locationName

    #list of subscriptions
    $subscriptionList = $null
    foreach($index in (1..($subList.count - 1))) {
        $subscriptionList += "`"$($subList[$index])`""
        if($index -lt ($subList.count - 1)) {
            $subscriptionList += ",`n"
        }
    }

    #use a here-string for the json body
    $Body = @"
{
    "location": "$($region)",
    "subscriptionIds": [
        $($subscriptionList)
    ]
}
"@

    #Submit the REST call
    $r = Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subID/providers/Microsoft.Resources/checkZonePeers/?api-version=2020-01-01" -Method POST -Body $Body -Headers $authHeader
}

Register-AzProviderFeature -FeatureName AvailabilityZonePeering -ProviderNamespace Microsoft.Resources
Get-AzProviderFeature -FeatureName AvailabilityZonePeering -ProviderNamespace Microsoft.Resources

Check-AzureAzs @("466c1a5d-e93b-4138-91a5-670daf44b0f8","5a7b82eb-ba40-42b9-80d9-8d33e15d6193") 'eastus'

$subList = @("466c1a5d-e93b-4138-91a5-670daf44b0f8","5a7b82eb-ba40-42b9-80d9-8d33e15d6193")
$locationname = 'southcentralus'