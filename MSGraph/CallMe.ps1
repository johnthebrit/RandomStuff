# Import necessary module
#Import-Module Microsoft.Graph

# Define the function to call Microsoft Graph API
function Get-GraphMe {
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    try {
        $r = Invoke-WebRequest -Uri "https://graph.microsoft.com/v1.0/me" -Method GET -Headers $authHeader -ErrorAction Stop
        $responseObject = $r.Content | ConvertFrom-Json
        Write-Output "$time - $($r.StatusCode) $($r.StatusDescription) $($responseObject.displayName)"
    } catch {
        Write-Output "$time Request failed:"
        Write-Output $_.Exception.Message
        $errorObject = $_.ErrorDetails | ConvertFrom-Json
        write-Output $errorObject.error.message
        #write-output $_
    }
}

#NOT CAE Capabable
#Connect-MgGraph -Scopes 'User.Read' #To reset and respond to challenge
#$req = Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/v1.0/me' -OutputType HttpResponseMessage
#$accessToken = $req.RequestMessage.Headers.Authorization.Parameter

#The below is used and required to get and RESET after a revoke
#Connect-AzAccount -AuthScope https://graph.microsoft.com -TenantId $tenantId
$accessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token #MS Graph audience

# Infinite loop to call the function every 15 seconds
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $accessToken
}

while ($true) {
    Get-GraphMe
    Start-Sleep -Seconds 15
}
