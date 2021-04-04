
#Connect as managed identity
Connect-AzAccount -Identity


#Read a secret
$secret = Get-AzKeyVaultSecret -VaultName "SavillVaultRBAC" -Name "Secret1"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
Write-Output $secretValueText


#Create token for Key Vault audience from current context
$kvAccessToken = (Get-AzAccessToken -ResourceUrl 'https://vault.azure.net').Token #Az module 5.1 and above
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $kvAccessToken
}

#Create the auth header based on managed identity from within Azure resource
$audience = 'https://vault.azure.net'
$token = Invoke-RestMethod -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$audience" -Headers @{ 'Metadata' = 'true' }
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.access_token
}



#Encrypt and decrypt
$encodedhello = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("Hello World"))
$Body = "{ `"alg`": `"RSA1_5`", `"value`": `"$encodedhello`" }"
$r = Invoke-WebRequest -Uri https://savillvaultrbac.vault.azure.net/keys/SigningKey1/a10c4d24ccf74033b64896c97d92dfdb/encrypt?api-version=7.1 -Method POST -Body $body -Headers $authHeader
$r.Headers
$r.Content
$encrypted = ($r.content | convertfrom-json).value


$Body = "{ `"alg`": `"RSA1_5`", `"value`": `"$encrypted`" }"
$r = Invoke-WebRequest -Uri https://savillvaultrbac.vault.azure.net/keys/SigningKey1/a10c4d24ccf74033b64896c97d92dfdb/decrypt?api-version=7.1 -Method POST -Body $body -Headers $authHeader
$decryptvalue=($r | convertfrom-json).value+'=' #adding a pad =
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($decryptvalue))




#Get a hash value for a string
$stringAsStream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stringAsStream)
$writer.write("Test for Key Vault hash")
$writer.Flush()
$stringAsStream.Position = 0
$hashvalue = Get-FileHash -InputStream $stringAsStream | Select-Object Hash -ExpandProperty Hash

#To get the public key
$r = Invoke-WebRequest -Uri https://savillvaultrbac.vault.azure.net/keys/SigningKey1/a10c4d24ccf74033b64896c97d92dfdb?api-version=7.1 -Method Get -Headers $authHeader
$r.Content | ConvertFrom-Json | ConvertTo-Json #Make it pretty
$pubkey = ($r.Content | ConvertFrom-Json).Key.n

#https://docs.microsoft.com/en-us/rest/api/keyvault/sign/sign
$Body = "{ `"alg`": `"PS384`", `"value`": `"$hashvalue`" }"
$r = Invoke-WebRequest -Uri https://savillvaultrbac.vault.azure.net/keys/SigningKey1/a10c4d24ccf74033b64896c97d92dfdb/sign?api-version=7.1 -Method POST -Body $body -Headers $authHeader
$r.Headers
$r.Content
$digest = ($r.content | convertfrom-json).value
