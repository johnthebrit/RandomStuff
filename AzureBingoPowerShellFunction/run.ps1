using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "Azure GetBingoEntry function processed a request."

# Interact with query parameters or the body of the request.
$ResetGame = $Request.Query.ResetGame
if (-not $ResetGame) {
    $ResetGame= $Request.Body.ResetGame
}

$statusGood = $true

$sessionID = $Request.Headers."x-forwarded-for".Split(":")[0]

$resourceGroupName = $env:FUNC_STOR_RGName  #='RG-USSC-AzureBingoFunction'
$storageAccountName = $env:FUNC_STOR_ActName  #='sasavusscbingodata'
$tableName = $env:FUNC_STOR_TblName #='bingostatedata'
$blobContainer = $env:FUNC_STOR_BlobContainer #='bingodata'
$blobDataFile = $env:FUNC_STOR_BlobDataFile #= 'bingodata.txt'

try {
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName `
        -Name $storageAccountName
    $storageContext = $storageAccount.Context
    $cloudTable = (Get-AzStorageTable –Name $tableName –Context $storageContext).CloudTable

    #Read the items for the sessionID
    $records = Get-AzTableRow `
                -table $cloudTable `
                -PartitionKey $sessionID
}
catch {
    $statusGood = $false
    $body = "Failure connecting to table for state data, $_"
}

if ($ResetGame) {
    write-output "Received Game Reset"
    try {
        #Delete all for the sessionID
        $records | Remove-AzTableRow -table $cloudTable
        $records = $null
    }
    catch {
        $statusGood = $false
        $body = "Failure removing existing records, i.e. reset failed, $_"
        }
}

if($records) #if there are some
{
    $bingoPreCalled = $records | select-object -ExpandProperty RowKey
}
else {
    $bingoPreCalled = $null
}

$tempFile = "$((New-Guid).Guid).data"
try {
    Get-AzStorageBlobContent -Context $storageContext `
        -Container $blobContainer -Blob $blobDataFile `
        -Destination "$($env:temp)\$tempFile"
}
catch {
    $statusGood = $false
    $body = "Failure getting data file from blob, $_"
}

#Read in the data file from temp storage
$bingoSourceData = Get-Content "$($env:temp)\$tempFile" -ErrorAction:SilentlyContinue
Remove-Item "$($env:temp)\$tempFile"

if($bingoPreCalled -ne $null)
{
    $bingoData = Compare-Object -ReferenceObject $bingoSourceData -DifferenceObject $bingoPreCalled -PassThru
}
else
{
    $bingoData = $bingoSourceData
}

#Number of items
$bingoCount = $bingoData.Count
Write-Output "$bingoCount items left"

#Generate a random number based on the entries available
$dataItem = Get-Random -Maximum $bingoCount

#Selected data
$returnData = $bingoData[$dataItem]
#Add entry and returned
try {
    Add-AzTableRow -table $cloudTable -partitionKey $sessionID -rowKey $returnData
}
catch {
    $statusGood = $false
    $body = "Failure adding item to state table, $_"
}

if(!$statusGood)
{
    $status = [HttpStatusCode]::BadRequest
}
else
{
    $status = [HttpStatusCode]::OK
    $body = $returnData
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
