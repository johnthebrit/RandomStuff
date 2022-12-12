#Bulkstart.ps1
#John Savill
#
#To download to your machine to a folder to then cope to your function app:
#Save-Module Az.ResourceGraph .\modules
#You can then zip it up and zip deploy into your function app
#
#this function definition must be in the profile.ps1 file and NOT the run.ps1
#also need to uplodate az.resourcegraph into the modules child folder main function app
#restart the app after changes to dependencies
#at the start import the az.resourcegraph
import-module az.resourcegraph
#then at the end of profile.ps1
function executeActionCommand
{
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory=$true)]
        [String]
        $commandToRun,
        [Parameter(Mandatory=$true)]
        [String]
        $resourceName,
        [Parameter(Mandatory=$true)]
        [String]
        $resourceType,
        [Parameter(Mandatory=$true)]
        [String]
        $actionType
    )

    #Being very lazy
    if($actionType -eq 'Start')
    {$outputBit = 'art'}
    elseif ($actionType -eq 'Stop')
    {$outputBit = 'opp'}

    Write-Output "St$($outputBit)ing $resourceType $resourceName"
    try {
        $commandBlock = [Scriptblock]::Create($commandToRun) #Need to make it a script block
        $status = & $commandBlock
        if(($status.StatusCode -ne 'Accepted') -and ($resourceType -eq 'VM'))   #would be Succeeded if not using NoWait against Status property when starting VM. AKS and VMSS are different and not checking currently
        {
            Write-Error "   * Error response st$($outputBit)ing $resourceName - $($status.status)"
            Write-Output "   * Executing - $commandToRun"
            Write-Output "  * Status - $status"
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error "   * Error st$($outputBit)ing $resourceType $resourceName"
        Write-Output $errorMessage
    }
}


#Main code time with a version in each function as either start or stop uncommented

$mode="Start"
#$mode="Stop"

$delayPeriod = 120 #wait 2 minutes between priority changes or whatever you need

if($mode -eq "Stop")
{
    $sortMode = "desc"
    $starting = $false
}
else
{
    $sortMode = "asc"
    $starting = $true
}

$query = @"
Resources
| where type in~ ('Microsoft.Compute/virtualMachines','microsoft.compute/virtualmachinescalesets','Microsoft.ContainerService/managedClusters')
| mv-expand tags
| extend tagKey = tostring(bag_keys(tags)[0])
| extend tagValue = tostring(tags[tagKey])
| where tagKey =~ 'Priority'
| extend priority = tagValue
| order by priority $sortMode
| project name, type, priority, resourceGroup, id
"@

#Find the resources
$resources = Search-AzGraph -Query $query
#Find the lowest current priority
$lowestPriority = $resources[0].priority

#Enumerate
foreach($resource in $resources)
{
    #If we are on a new priority batch
    if($resource.priority -ne $lowestPriority)
    {
        Write-Output "Priority $lowestPriority -> $($resource.priority) so sleeping for $delayPeriod seconds"
        Start-Sleep($delayPeriod) #wait
        $lowestPriority = $resource.priority #set as the new
    }

    #For each resource type
    switch ($resource.type) {
        'microsoft.compute/virtualmachines'
        {
            if($starting)
            { executeActionCommand "Start-AzVM -Name $($resource.name) -ResourceGroupName $($resource.resourceGroup) -NoWait -ErrorAction Stop" $resource.name "VM" "Start"}
            else
            { executeActionCommand "Stop-AzVM -Name $($resource.name) -ResourceGroupName $($resource.resourceGroup) -NoWait -ErrorAction Stop -Force" $resource.name "VM" "Stop"}
        }
        'microsoft.compute/virtualmachinescalesets'
        {
            $skipExecution=$false
            try {
                #Check if this VMSS is actually owned by AKS in which case we need to skip
                $vmssInfo = Get-AzVmss -VMScaleSetName $resource.name -ResourceGroupName $resource.resourceGroup -ErrorAction Stop

                if(($vmssInfo.VirtualMachineProfile.ExtensionProfile.Extensions.Type -contains "Compute.AKS.Linux.Billing") -or
                    ($vmssInfo.VirtualMachineProfile.ExtensionProfile.Extensions.Type -contains "Compute.AKS.Windows.Billing"))
                {
                    Write-Output "!! This VMSS is part of an AKS cluster and will be skipped. Action should be via the AKS resource"
                    $skipExecution=$true
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                Write-Error "   * Error getting VMSS information on $($resource.name)"
                Write-Output $errorMessage
            }

            if(!$skipExecution)
            {
                if($starting)
                { executeActionCommand "Start-AzVmss -VMScaleSetName $($resource.name) -ResourceGroupName $($resource.resourceGroup) -NoWait -ErrorAction Stop" $resource.name 'VMSS' 'Start'}
                else
                { executeActionCommand "Stop-AzVmss -VMScaleSetName $($resource.name) -ResourceGroupName $($resource.resourceGroup) -NoWait -ErrorAction Stop -Force" $resource.name 'VMSS' 'Stop'}
            }
        }
        'Microsoft.ContainerService/managedClusters'
        {
            if($starting)
            { executeActionCommand "Start-AzAksCluster -Name $($resource.name) -ResourceGroupName $($resource.resourceGroup) -NoWait -ErrorAction Stop" $resource.name 'AKS' 'Start' }
            else
            { executeActionCommand "Stop-AzAksCluster -Name $($resource.name) -ResourceGroupName $($resource.resourceGroup) -NoWait -ErrorAction Stop" $resource.name 'AKS' 'Stop' }
        }
        Default
        {
            Write-Output "Resource $($resource.name) of type $($resource.type) not handled"
        }
    }
}