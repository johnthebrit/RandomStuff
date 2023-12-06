$videoIds = Get-Content -Path "C:\Users\john\OneDrive\Captions\videoids.json" | ConvertFrom-Json

# Set the context for your storage account
$storageAccount = "saveast2knowledgestore"
$storageRG = "RG-AI"
$storageContainer = "text"

$storageContext = (Get-AzStorageAccount -ResourceGroupName $storageRG -Name $storageAccount).Context

# List all blobs in a container
$blobs = Get-AzStorageBlob -Container $storageContainer -Context $storageContext
foreach ($blob in $blobs)
{
    Write-Output "Working on $($blob.name)"
    $docName = $blob.Name -replace "\.txt$", "" #remove only from end of the string



    $metadata = New-Object System.Collections.Generic.Dictionary"[String,String]"
    $metadata.Add("DocName",$docName)

    $blob.BlobClient.SetMetadata($metadata, $null)
}