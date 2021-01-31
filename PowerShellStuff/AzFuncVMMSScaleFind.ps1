#Module azTable and az.resourcegraph required via the requirements.psd1 file
#MI needs read at MG/sub level and contrib to its storage account

# Input bindings are passed in via param block.
param($Timer)

#Module azTable required
$statusGood = $true

#Table setup
$resourceGroupName = $env:FUNC_VMMS_STOR_RGName  #"RG-VMMS-Test"
$storageAccountName = $env:FUNC_VMMS_STOR_ActName  #"sasavvmmstst"
$tableName = $env:FUNC_VMMS_STOR_TblName #"VMMSScaleLogs"
$stateTableName = $env:FUNC_VMMS_STOR_TblStateName #"VMMSScaleLogState"
try {
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName `
            -Name $storageAccountName
        $storageContext = $storageAccount.Context
        $cloudTable = (Get-AzStorageTable –Name $tableName –Context $storageContext).CloudTable
        $cloudTableState = (Get-AzStorageTable –Name $stateTableName –Context $storageContext).CloudTable

        $lastRunRecord = Get-AzTableRow `
            -table $cloudTableState `
            -PartitionKey "VMMSScalePart" -RowKey "LastRun"
}
catch {
    $statusGood = $false
    Write-Output = "Failure connecting to table for user data, $_"
}

#Time here of last execution
#$startTime = (Get-Date).AddDays(-2) #Would read this in as the endDate from last execution
$startTime = $lastRunRecord.LastRunTime
$endTime = (Get-Date).ToUniversalTime().AddMinutes(-1) #1 minute ago

$currentSubID = (Get-AzContext).Subscription.Id

Write-Output "Finding scale actions between $startTime and $endTime"

$GraphSearchQuery = "Resources
| where type =~ 'Microsoft.Compute/virtualMachineScaleSets'
| join kind=inner (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
| project VMMSName = name, RGName = resourceGroup, SubName, SubID = subscriptionId, ResID = id"
$VMMSResources = Search-AzGraph -Query $GraphSearchQuery

if($null -eq $VMMSResources)
{
    $statusGood = $false
    $body = "Could not find any VMMS instances in accessible subscriptions"
}
else
{
    $scaleactions = @()

    foreach ($VMMSResource in $VMMSResources)
    {
        Write-Output "Resource found $($VMMSResource.VMMSName) in RG $($VMMSResource.RGName) in sub $($VMMSResource.Subname)($($VMMSResource.SubID))"

        if($currentSubID -ne $VMMSResource.SubID)
        {
            #Change subscription here first!
            Select-AzSubscription -Subscription $VMMSResource.SubID -WarningAction SilentlyContinue
            $currentSubID = $VMMSResource.SubID
        }

        #Get instance information about the VMMS instance
        $VMMSInstanceDetail = Get-AzVmss -ResourceGroupName $VMMSResource.RGName -VMScaleSetName $VMMSResource.VMMSName
        $SKUName = $VMMSInstanceDetail.Sku.Name

        #Find scale logs for desired time window
        $scalelogs = Get-AzLog -ResourceId $VMMSResource.ResID -StartTime $startTime.ToLocalTime() -EndTime $endTime.ToLocalTime() -WarningAction SilentlyContinue |
            Where-Object {$_.OperationName.Value -eq "Microsoft.Insights/AutoscaleSettings/ScaleupResult/Action" -or
                        $_.OperationName.Value -eq "Microsoft.Insights/AutoscaleSettings/ScaledownResult/Action"}
        $scalelogs = $scalelogs | Sort-Object -Property EventTimestamp

        $noOfScaleActions = 0
        foreach ($scalelog in $scalelogs) {
            Write-Output "$($scalelog.EventTimestamp) Scale from $($scalelog.properties.content.OldInstancesCount) to $($scalelog.properties.content.NewInstancesCount)"
            $scaleactions += , @($scalelog.EventTimestamp,$scalelog.properties.content.OldInstancesCount,$scalelog.properties.content.NewInstancesCount,$VMMSResource.VMMSName,$SKUName,$VMMSResource.Subname,$VMMSResource.SubID,$VMMSResource.RGName,$VMMSResource.ResID)
            $noOfScaleActions++
        }

        if($noOfScaleActions -eq 0)
        {
            Write-Output "No scale actions found, current scale count is $($VMMSInstanceDetail.Sku.Capacity)"
            $scaleactions += , @($endTime,$VMMSInstanceDetail.Sku.Capacity,$VMMSInstanceDetail.Sku.Capacity,$VMMSResource.VMMSName,$SKUName,$VMMSResource.Subname,$VMMSResource.SubID,$VMMSResource.RGName,$VMMSResource.ResID)
        }
    } #end of for each scale action

    $partitionKey = $endTime.ToString("yyyy-MM-dd") #the end time

    foreach ($action in $scaleactions)
    {
        #File Output
        #Write-Output "$($action[0]),$($action[1]),$($action[2]),$($action[3]),$($action[4]),$($action[5]),$($action[6]),$($action[7]),$($action[8])" | Out-file .\logs.csv -Append -Encoding ascii

        #Table Output
        $rowKey = "$($action[0].ToString("yyyyMMddHHmmss"))$($action[3])"
        #Create
        try {
            Add-AzTableRow `
                -table $cloudTable `
                -partitionKey $partitionKey `
                -rowKey $rowKey -property @{"ScaleEventTime"=$action[0];"OldInstanceCount"=$action[1];"NewInstanceCount"=$action[2];"VMMSInstanceName"=$action[3];"SKUName"=$action[4];"SubName"=$action[5];"SubID"=$action[6];"RGName"=$action[7];"ResID"=$action[8];}
        }
        catch {
            $statusGood = $false
            write-output "Failure creating table entry for scale event, $_"
        }
    }
} #end of if VMMS instances found

#Update the last execution time
try {
    $lastRunRecord.LastRunTime = $endTime
    $lastRunRecord | Update-AzTableRow -table $cloudTableState #commit the change
}
catch {
    $statusGood = $false
    write-output "Failure updating record for update time, $_"
}