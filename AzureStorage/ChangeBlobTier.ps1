$rgName = "RG-YouTube"
$accountName = "savillyoutube"
$containerName = "videos"

$storAccount = Get-AzStorageAccount -ResourceGroupName $rgName -Name $accountName
$storCtx = $storAccount.Context

$blobs = Get-AzStorageBlob -Container $containerName -Context $storCtx | Where-Object {$_.AccessTier -ne "Archive"}
foreach ($blob in $blobs) {
    $blob.ICloudBlob.SetStandardBlobTier("Archive")
}
