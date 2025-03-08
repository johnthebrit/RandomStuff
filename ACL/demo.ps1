# Define variables
$imageFile = "C:\Users\john\OneDrive\projects\GIT\RandomStuff\ACL\special.docx"
$containerName = "special"
$blobName = "special.docx"
$storageAccountName = "sascussavilltech"
$storageResourceGroup = "mgmt-centralus"
$ledgerUri = "https://savillledger.confidential-ledger.azure.com"
$identityUri = "https://identity.confidential-ledger.core.azure.com/ledgerIdentity/savillledger"

# Step 1: Fetch the network certificate from the identity endpoint
$certificateResponse = Invoke-RestMethod -Uri $identityUri -Method Get
$certificateBase64 = $certificateResponse.cert

# Convert the base64-encoded certificate to an X509Certificate2 object
$certificateBytes = [Convert]::FromBase64String($certificateBase64)
$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $certificateBytes


# Step 2: Upload image to Azure Blob Storage
az storage blob upload --account-name $storageAccountName --container-name $containerName --name $blobName --file $imageFile --auth-mode login

# Step 3: Compute SHA256 digest of the image
$imageContent = [System.IO.File]::ReadAllBytes($imageFile)
$digestBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($imageContent)
$digest = [BitConverter]::ToString($digestBytes) -replace "-", ""

# Step 4: Write Resource ID and Digest to Azure Confidential Ledger
$blobResourceId = "/subscriptions/$subID/resourceGroups/$storageResourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName/blobServices/default/containers/$containerName/blobs/$blobName"
$payload = @{
    ResourceId = $blobResourceId
    Digest = $digest
} | ConvertTo-Json -Depth 2

$accessToken = az account get-access-token --query accessToken -o tsv
$headers = @{
    Authorization = "Bearer $accessToken"
}

# Use the certificate to establish a secure connection
$ledgerResponse = Invoke-RestMethod -Method Post -Uri "$ledgerUri/app/transactions" -Body $payload -ContentType "application/json" -Headers $headers -Certificate $certificate -SkipCertificateCheck

# Step 5: Add Receipt from Ledger as Metadata to the Blob
$receipt = $ledgerResponse.receipt | ConvertTo-Json -Depth 2
$receiptMetadata = @{ receipt = $receipt }
az storage blob metadata update --account-name $storageAccountName --container-name $containerName --name $blobName --metadata $receiptMetadata


## Verify the integrity of the image

# Step 6: Fetch the Digest from the Ledger
$blobResourceId = "/subscriptions/$subID/resourceGroups/$storageResourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName/blobServices/default/containers/$containerName/blobs/$blobName"
$ledgerEntry = Invoke-RestMethod -Method Get -Uri "$ledgerUri/app/transactions?resourceId=$blobResourceId" -Headers @{
    Authorization = "Bearer $(az account get-access-token --query accessToken -o tsv)"
}

$ledgerDigest = ($ledgerEntry.data | ConvertFrom-Json).Digest

# Step 7: Compute the Current Digest of the Blob
# Download the blob locally
az storage blob download --account-name $storageAccountName --container-name $containerName --name $blobName --file $imageFile

# Compute the SHA256 digest
$imageContent = Get-Content -Path $imageFile -Raw -Encoding Byte
$currentDigestBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($imageContent)
$currentDigest = [BitConverter]::ToString($currentDigestBytes) -replace "-", ""

# Step 8: Compare the Two Digests
if ($ledgerDigest -eq $currentDigest) {
    Write-Output "The digests match! The blob has not been altered."
} else {
    Write-Output "The digests do not match! The blob may have been modified."
}