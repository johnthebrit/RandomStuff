$videoIds = Get-Content -Path "C:\Users\john\OneDrive\Captions\videoids.json" | ConvertFrom-Json

$videoDetails = @()
foreach($video in $videoIds)
{
    $cleanedTitle = $video.snippet.title -replace '[^a-zA-Z0-9]', ''
    $newVideo = @{$cleanedTitle = $video.id.videoId}
    $videoDetails += $newVideo
}

# Set the context for your storage account
$storageAccount = "savilltecheast2knowledge"
$storageRG = "RG-AI-Search"
$storageContainer = "text"

$storageContext = (Get-AzStorageAccount -ResourceGroupName $storageRG -Name $storageAccount).Context

# List all blobs in a container
$blobs = Get-AzStorageBlob -Container $storageContainer -Context $storageContext
foreach ($blob in $blobs)
{
    Write-Output "Working on $($blob.name)"

    $props = $blob.blobclient.GetProperties()

    if($props.Value.Metadata.DocName -eq $null)
    {
        Write-Output "No metadata found, adding"

        $docName = $blob.Name -replace "\.txt$", "" #remove only from end of the string
        $cleanDocName = $docName -replace '[^a-zA-Z0-9]', ''

        $videoMatch = $null

        $videoDetails.keys | ForEach-Object {
            $maxLength = [Math]::Min($cleanDocName.Length, $_.Length)

            # Compare the substrings
            if ($cleanDocName.Substring(0, $maxLength) -eq $_.Substring(0, $maxLength)) {
                Write-Host "Found match $($videoDetails.$_)"
                $videoMatch = $videoDetails.$_
            }
        }

        Write-Output $videoDetails.$docName

        $metadata = New-Object System.Collections.Generic.Dictionary"[String,String]"
        $metadata.Add("DocName",$docName)
        if($videoMatch -ne $null)
        {
            $metadata.Add("VideoURL","https://youtu.be/$videoMatch")
        }else
        {
            $metadata.Add("VideoURL","https://www.youtube.com/channel/UCpIn7ox7j7bH_OFj7tYouOQ")
        }

        $blob.BlobClient.SetMetadata($metadata, $null)
    }
    else {
        Write-Output "Existing metadata found, skipping"
    }
}