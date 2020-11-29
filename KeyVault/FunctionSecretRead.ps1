using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$statusgood = $true

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

if ($name) {
    try
    {
        $secret = Get-AzKeyVaultSecret -VaultName 'SavillVaultRBAC' -Name $name
    }
    catch
    {
        $body = "Failure getting secret, $_"
        $statusgood = $false
    }
    if($secret -ne $null)
    {
        $text = $secret.SecretValue | ConvertFrom-SecureString -AsPlainText
        $body = "Secret text is $text from $name"
    }
    else
    {
        $body = "Could not read secret $name"
    }
}
else
{
    $body = "i need a secret"
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
