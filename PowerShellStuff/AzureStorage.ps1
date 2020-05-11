#This bit of code comes from an Azure Function where the variables below were configured as app settings for the function
#but you could change to anything
#Additionally logon to Azure has been completed using managed identity, i.e.
# Connect-AzAccount -Identity

$resourceGroupName = $env:FUNC_STOR_RGName  #'RG-USSC-OSExecuteFunction'
$storageAccountName = $env:FUNC_STOR_ActName  #"sasavusscuserelevate"
$tableName = $env:FUNC_STOR_TblName #"userelevationdata"
try {
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName `
        -Name $storageAccountName
        $storageContext = $storageAccount.Context
        $cloudTable = (Get-AzStorageTable –Name $tableName –Context $storageContext).CloudTable
}
catch {
    $statusGood = $false
    $body = "Failure connecting to table for user data, $_"
}


#Then this code writes, updates or removes from the table
try {
    #Check if record exists for the user and guest OS
    $record = Get-AzTableRow `
        -table $cloudTable `
        -PartitionKey "$tablePrincipalName" -RowKey ($VMresource.VMName)

    if($action -eq "Add")
    {
        if(!$record) #if does not exist
        {
            #Create
            Add-AzTableRow `
                -table $cloudTable `
                -partitionKey $tablePrincipalName `
                -rowKey ($VMresource.VMName) -property @{"ExpiryTime"="$expiryTime";"Principal"="$secprincipal";"ResourceGroup"="$($VMresource.RGName)";"Subscription"="$($VMResource.SubID)";}
        }
        else
        {
            #Need to update the expiry time. This assumes this new record should overwrite the existing even if potentially existing was a later time
            $record.ExpiryTime = "$expiryTime"
            $record | Update-AzTableRow -table $cloudTable #commit the change
        }
    }
    else #assume Remove
    {
        if($record) #if does exist
        {
            $record | Remove-AzTableRow -table $cloudTable
        }
    }
}
catch {
    $statusGood = $false
    $body = "Failure creating table entry for user but elevation was performed, $_"
}