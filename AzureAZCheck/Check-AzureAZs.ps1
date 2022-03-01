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
    $r = Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subID/providers/Microsoft.Resources/checkZonePeers/?api-version=2022-01-01" -Method POST -Body $Body -Headers $authHeader
}