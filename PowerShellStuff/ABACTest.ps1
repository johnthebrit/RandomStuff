$localSrcFile = "C:\Users\john\OneDrive\Pictures\SavillCandy.jpg"
$ungrantedTag = @{'Project'='Avengers'}
$grantedTag = @{'Project'='JL'}
# Get new context for request
$bearerCtx = New-AzStorageContext -StorageAccountName "sascussavilltech"
# try ungranted tags
$content = Set-AzStorageBlobContent -File $localSrcFile -Container imagewrite -Blob "SavillCandy.jpg" -Tag $ungrantedTag -Context $bearerCtx
# try granted tags
$content = Set-AzStorageBlobContent -File $localSrcFile -Container imagewrite -Blob "SavillCandy.jpg" -Tag $grantedTag -Context $bearerCtx