$stgName = "sascussavilltech3"
$rgName =  "RG-SCUSA"
$stg = Get-AzStorageAccount -StorageAccountName $stgName -ResourceGroupName $rgName
$stg.identity

Set-AzStorageAccount -ResourceGroupName $rgName -AccountName $stgName -AssignIdentity