#Variables
$accountName = 'savtechpsstorage2020'
$rgName = 'RG-SCUSPSStorage'
$storageSKU = 'Standard_LRS'
$location = 'southcentralus'
$storAccount = $null
$storContext = $null

#Check for the storage account
try {$storAccount = Get-AzStorageAccount -ResourceGroupName $rgName `
    -Name $accountName -ErrorAction 0}
    catch {write-output "Not found"}

if($null -eq $storAccount)
{


    #Create the storage account
    Write-Output "Creating account"
    $storAccount = New-AzStorageAccount -ResourceGroupName $rgName `
        -Name $accountName `
        -Location $location `
        -SkuName $storageSKU `
        -Kind StorageV2


}

else   #Check its the right type
{
    Write-Output "Account already exists"
    if($storAccount.SkuName -ne $storageSKU) #if not fix it
    {
        Write-Output "Changing account type"
        Set-AzStorageAccount -ResourceGroupName $rgName `
            -Name $accountName `
            -SkuName $storageSKU
    }
}



$storContext = New-AzStorageContext -StorageAccountName $storAccount.StorageAccountName -UseConnectedAccount


#Would need all the same checks here if it already exists before creation etc
#Create the container
New-AzStorageContainer -Name "images" `
    -Context $storContext
