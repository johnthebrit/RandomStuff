$subID = 'SubID'
$token = Get-AzAccessToken
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.Token
}
$r = Invoke-WebRequest -Uri "https://management.azure.com/subscriptions/$subID/providers/Microsoft.Compute/skus?api-version=2019-04-01" -Method Get -Headers $authHeader

$rarray = $r.Content | ConvertFrom-Json # | ConvertTo-Json #Make it pretty

foreach ($item in $rarray.value) {
    write-debug $item
    if($item.resourceType -eq 'disks')
    {
        $MaxSize = 0
        foreach ($attr in $item.capabilities) {
            if($attr.name -eq 'MaxSizeGiB') {
                $MaxSize = $attr.value
            }
        }
        write-output "$($item.name) - $($item.size) - $MaxSize"
    }
}
