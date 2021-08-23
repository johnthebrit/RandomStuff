#Your sub here for later
$subid = '466c1a5d-e93b-4138-91a5-670daf44b0f8'

#Many commands use REST behind the scenes
Get-AzResourceGroup -debug

#Invoke-WebRequest does not do much to the response
$r = Invoke-WebRequest -Uri https://azure.microsoft.com/updates/feed/
$r
$r.Content

#Invoke-RestMethod is for calls that return rich format response and translates the response, e.g. JSON to a custom object
Invoke-RestMethod -Uri https://azure.microsoft.com/updates/feed/ |
  Format-Table -Property title, description, pubDate


#We often need to authenticate so need a token which is passed to the command

#For Azure we can use our existing context
$azContext = Get-AzContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
#Create a hash table for the auth header as we have multiple headers
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
}

#OR MUCH easier
$token = Get-AzAccessToken #This will default to Resource Manager endpoint
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.Token
}

#Again WebRequest we see everything but have to do more work
$r1 = Invoke-WebRequest -Uri https://management.azure.com/subscriptions/$subid/resourcegroups?api-version=2016-09-01 -Method GET -Headers $authHeader
$r1.Content | ConvertFrom-Json | ConvertTo-Json -depth 100 #make it look pretty
$r1.Headers["x-ms-ratelimit-remaining-subscription-reads"] #But I can go poke around other values

#RestMethod much cleaner
$r2 = Invoke-RestMethod -Uri https://management.azure.com/subscriptions/$subid/resourcegroups?api-version=2016-09-01 -Method GET -Headers $authHeader
$r2.value

#Be careful of special characters like $. Have to escape it with `
$UriString = "https://management.azure.com/subscriptions/$subID/providers/Microsoft.Compute/skus?api-version=2019-04-01&`$filter=location eq 'eastus2'"
$r = Invoke-RestMethod -Uri $UriString -Method Get -Headers $authHeader
$r.value

#Can token get for other audiences
$accessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token #MS Graph audience
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $accessToken
}

#Submit the REST call for the list guest users!
### NOTE IN POWERSHELL I HAVE TO ESCAPE THE $ or it gets ignored!!!!
$r = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/?`$filter=userType eq 'guest'" -Method GET -Headers $authHeader
$r.value


#Can have a body and PATCH (from AzureVMs\UserData.ps1) to update something and still uses the familiar $authHeader
#use a here-string for the json body
$Body = @"
{
    "properties": {
        "userData": "$userDataBase64"
    }
}
"@

#Submit the REST call
$r = Invoke-WebRequest -Uri "https://management.azure.com/$($resourceID)?api-version=2021-03-01" -Method PATCH -Body $Body -Headers $authHeader
