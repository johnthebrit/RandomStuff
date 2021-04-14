<#
Bulk Shutdown Azure Resources
v1.3
John Savill

Need to auth for PowerShell Azure module

Permissions required:
*/read permission on all objects to see
Microsoft.Compute/virtualMachineScaleSets/deallocate/action VMSS
Microsoft.Compute/virtualMachineScaleSets/virtualMachines/deallocate/action VMSS
Microsoft.Compute/virtualMachines/deallocate/action VM
Microsoft.ContainerService/managedClusters/write  AKS
Microsoft.Resources/tags/write write to any tag resource

Change Notes:

Version 1.1

-	Writes number completed every 20 records
-	Writes/adds tag to deallocated resources. Adds requirement for Microsoft.Resources/tags/write permission
-	Gets more detailed error code where possible and also writes information to JSON where possible including locked resources
-	Only changes subscription context if required
-	Suppress command expiring messages
-	Skipped resources have their own unique status now

Version 1.2

-   Switched to -whatif instead of -pretend
-   Check required columns in input files
-   Use a JSON file to specify the tag name, text and how often to write out progress records
-   Rename function to Start-AzureBulkShutdown to use a standard noun

Version 1.3

-   Add check on VMSS that is NOT part of AKS cluster by checking for billing extension presense


Example JSON configuration output generate
$configurationSettings = @{"tagName"="automated-deallocation";
                            "tagValue"="This has been auto-deallocated by a scheduled task";
                            "tagWrite"=$true;
                            "outputProgressInterval"=20}
$configurationSettings | ConvertTo-Json | Out-File -FilePath '.\bulkAzureShutdown.json'

#>

function Start-AzureBulkShutdown
{
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$false)]
        [String[]]
        $InputCSV,
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$false)]
        [String[]]
        $ExcludeSubList
    )

    $statusGood = $true

    #Silence warnings about changing cmdlets
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true" > $null

    #read in configuration
    try {
        $configurationSettingsFile = Get-Content -Path '.\bulkAzureShutdown.json' -ErrorAction Stop
        $configurationSettings = $configurationSettingsFile | convertfrom-json -AsHashTable
    }
    catch {
        Write-Error "Error reading configuration file: `n $_ "
        $statusGood = $false
    }

    #read in resources
    try {
        $resourceList = Import-Csv -Path $InputCSV
    }
    catch {
        Write-Error "Error reading resource file: `n $_ "
        $statusGood = $false
        $resourceList = $null
    }

    #List of protected subs
    try {
        $excludeSubArrayDetail = Import-Csv -Path $ExcludeSubList
        #Make sure have the Sub ID column which is all we need
        if(Get-Member -inputobject $excludeSubArrayDetail[0] -name "Sub ID" -membertype Properties)
        {
            $protectSubList = $excludeSubArrayDetail | select-object -Property 'Sub ID' -ExpandProperty 'Sub ID'
            #[string[]]$protectSubList = Get-Content -Path $ExcludeSubList #OLD CODE IF TEXT FILE
        }
        else
        {
            write-error "Input subscription file format failed"
            $statusGood = $false
        }

    }
    catch {
        Write-Error "Error reading subscription exception file: `n $_ "
        $statusGood = $false
    }

    if($statusGood)
    {
        #Check have the required columns in resource file
        if((Get-Member -inputobject $resourceList[0] -name "SubscriptionID" -membertype Properties) -and
        (Get-Member -inputobject $resourceList[0] -name "Subscription" -membertype Properties) -and
        (Get-Member -inputobject $resourceList[0] -name "Rsc Type" -membertype Properties) -and
        (Get-Member -inputobject $resourceList[0] -name "Resource Name" -membertype Properties) -and
        (Get-Member -inputobject $resourceList[0] -name "RscID" -membertype Properties))
        {
            write-output "Input resource file format check good"
        }
        else
        {
            write-error "Input resource file format failed"
            $statusGood = $false
        }
    }

    if($statusGood)
    {
        #Create array of custom objects for resources
        $resourceObjectArray = @()
        $exemptObjectArray = @()

        $vmcount = 0
        $vmsscount = 0
        $akscount = 0
        $unknowncount = 0

        Write-Output "Performing data analysis`n`n"

        foreach($resource in $resourceList)
        {
            #check the subscription is not in the exception list
            if($protectSubList -contains $resource.subscriptionID) #not case sensitive
            {
                Write-Output "  $($resource.'Resource Name') is in an exempt subscription and will be skipped [$($resource.subscriptionID)]"
                $exemptResource = $true
            }
            else {
                $exemptResource = $false

                #Only count resources that are not exempt
                switch ($resource.'Rsc Type') {
                    'VM' {$vmcount++}
                    'VMSS' {$vmsscount++}
                    'AKS' {$akscount++}
                    Default {$unknowncount++}
                }
            }

            #Custom hash table to convert to custom object
            $resourceEntry = @{'SubName'=$resource.Subscription;
	        'SubID'=$resource.SubscriptionID;
	        'ResourceType'=$resource.'Rsc Type';
	        'ResourceName'=$resource.'Resource Name';
	        'ResourceID'=$resource.RscID;
            'ExemptStatus'=$exemptResource;
            'ActionStatus'='';
            'Information'='';
            }
	        $resourceObject = New-Object -TypeName PSObject -Property $resourceEntry

            if($exemptResource) #we will track the exempt in a separate object array so they cannot be processed by the action code
            {
                $exemptObjectArray += $resourceObject
            }
            else
            {
                $resourceObjectArray += $resourceObject
            }
        } #end of foreach looking at each resource

        $origResourceCount = ($resourceList | Measure-Object).Count
        $actionResourceCount = ($resourceObjectArray | Measure-Object).Count
        $exemptResourceCount = ($exemptObjectArray | Measure-Object).Count

        Write-Output "`n`nOut of $origResourceCount a total of $exemptResourceCount resource[s] are in protected subscriptions and $actionResourceCount will be actioned"
        Write-Output "VM Count :   $vmcount"
        Write-Output "VMSS Count : $vmsscount"
        Write-Output "AKS Count :  $akscount"

        write-output "`nDo you wish to proceed with actions?"
        $userInput = Read-Host -Prompt 'Type YES (upper case) to continue>'

        if($userInput -ceq 'YES') #Must be uppercase
        {
            Write-Output "`nContinuing. Pausing for 10 seconds if need to cancel"
            Start-Sleep -Seconds 10

            Write-Output "`nStarting actions at $(get-date)"

            $actionedSoFar=0

            $prevSubID='notarealsubatall'

            if($configurationSettings.tagWrite)
            {
                if($configurationSettings.tagValue.length -gt 256)
                {
                    Write-Error "Passed tag value is greated than 256 characters and will be truncated to 256"
                    $configurationSettings.tagValue=$configurationSettings.tagValue.SubString(0,256)
                }
                $tagToStamp = @{$configurationSettings.tagName=$configurationSettings.tagValue}
            }

            #Here goes
            foreach($actionObject in $resourceObjectArray)
            {
                $actionedSoFar++ #increment counter by 1
                if($actionedSoFar % $configurationSettings.outputProgressInterval -eq 0)  #modulo operator to see what is left is 0, i.e. increments of whatever set, e.g. 20
                {
                    Write-Output "`n-- Processed $actionedSoFar out of $actionResourceCount ($([int](($actionedSoFar/$actionResourceCount)*100))%) --`n"
                }

                Write-Output " - Resource $($actionObject.ResourceName) $($actionObject.ResourceType) will be stopped"

                if($PSCmdlet.ShouldProcess($actionObject.ResourceName))
                {
                    if($prevSubID -ne $actionObject.SubID)  #if this record has different subscription from previous we need to change
                    {
                        Write-Output "* Changing context to subscription $($actionObject.SubID)"
                        Set-AzContext -Subscription $actionObject.SubID  > $null #change to the subscription of the object quietly
                        $prevSubID = $actionObject.SubID #set last sub to this object sub
                    }

                    try {
                        $resourceObjInfo  = Get-AzResource -Id $actionObject.ResourceID -ErrorAction Stop #get the object based on the known ID
                    }
                    catch {
                        $actionObject.Information = $_.Exception.Message
                        $resourceObjInfo = $null #need to force to null since above failed
                    }

                    if($null -ne $resourceObjInfo) #if found an object
                    {
                        switch ($actionObject.ResourceType)
                        {
                            'VM'
                            {
                                try {
                                    $status = Stop-AzVM -Name $resourceObjInfo.Name -ResourceGroupName $resourceObjInfo.ResourceGroupName -Force -NoWait -ErrorAction Stop
                                    if($status.StatusCode -ne 'Accepted')   #would be Succeeded if not using NoWait against Status property
                                    {
                                        Write-Error " * Error response stopping $($resourceObjInfo.Name) - $($status.status)"
                                        $actionObject.ActionStatus = "ErrorStopping"
                                    }
                                    else {
                                        $actionObject.ActionStatus = "Success"
                                    }
                                }
                                catch {
                                    $errorMessage = $_.Exception.Message
                                    Write-Error "Error stopping $($resourceObjInfo.Name)"
                                    $errorCodePosition = $errorMessage.IndexOf("ErrorCode: ")
                                    if($errorCodePosition -ne -1) #if found
                                    {
                                        $errorCode = $errorMessage.Substring(($errorCodePosition+11),($errorMessage.Substring(($errorCodePosition+11)).IndexOf("`r")))  #return not newline
                                        $actionObject.ActionStatus = $errorCode
                                    }
                                    else
                                    {
                                        $actionObject.ActionStatus = "ErrorDuringStopAction"
                                    }
                                    Write-Output $errorMessage
                                    $actionObject.Information = $errorMessage
                                }
                            }
                            'VMSS'
                            {
                                $skipExecution=$false
                                try
                                {
                                    #Check if this VMSS is actually owned by AKS in which case we need to skip
                                    $vmssInfo = get-azvmss -VMScaleSetName $resourceObjInfo.Name -ResourceGroupName $resourceObjInf.ResourceGroupName -ErrorAction Stop
                                    if(($vmssInfo.VirtualMachineProfile.ExtensionProfile.Extensions.Type -contains "Compute.AKS.Linux.Billing") -or
                                        ($vmssInfo.VirtualMachineProfile.ExtensionProfile.Extensions.Type -contains "Compute.AKS.Windows.Billing"))
                                    {
                                        Write-Output "!! This VMSS is part of an AKS cluster and will be skipped. Shutdown should be via the AKS resource"
                                        $skipExecution=$true
                                        $actionObject.ActionStatus = "VMSSActiononAKSSkip"
                                        $actionObject.Information = "Stop was attempted on VMSS that is part of AKS cluster"
                                    }
                                }
                                catch {
                                    $errorMessage = $_.Exception.Message
                                    Write-Error "Error getting VMSS information on $($resourceObjInfo.Name)"
                                    Write-Output $errorMessage
                                    $actionObject.ActionStatus = "ErrorGettingVMSSInfo"
                                    $actionObject.Information = $errorMessage
                                    $skipExecution=$true
                                }
                                if(!$skipExecution)
                                {
                                    try {
                                        $status = Stop-AzVmss -VMScaleSetName $resourceObjInfo.Name -ResourceGroupName $resourceObjInfo.ResourceGroupName -Force -AsJob -ErrorAction Stop
                                        if($status.State -eq 'Failed')  #if not asjob we would check -ne 'Succeeded' against .Status but as job we really look for Running and don't want failed
                                        {
                                            Write-Error " * Error response stopping $($resourceObjInfo.Name)"
                                            #Need to get more data here, i.e. if locked
                                            $extendedStatus = (Receive-Job -Job $status -Keep 2>&1).Exception.message #get the rest of the data and have to redirect error out to std to actually capture!
                                            $errorCodePosition = $extendedStatus.IndexOf("ErrorCode: ")
                                            if($errorCodePosition -ne -1) #if found
                                            {
                                                $errorCode = $extendedStatus.Substring(($errorCodePosition+11),($extendedStatus.Substring(($errorCodePosition+11)).IndexOf("`r")))  #return not newline
                                                $actionObject.ActionStatus = $errorCode
                                            }
                                            else
                                            {
                                                $actionObject.ActionStatus = "ErrorStopping"
                                            }
                                            Write-Output $extendedStatus
                                            $actionObject.Information = $extendedStatus
                                        }
                                        else {
                                            $actionObject.ActionStatus = "Success"
                                        }
                                    }
                                    catch {
                                        $errorMessage = $_.Exception.Message
                                        Write-Error "Error stopping $($resourceObjInfo.Name)"
                                        $errorCodePosition = $errorMessage.IndexOf("ErrorCode: ")
                                        if($errorCodePosition -ne -1) #if found
                                        {
                                            $errorCode = $errorMessage.Substring(($errorCodePosition+11),($errorMessage.Substring(($errorCodePosition+11)).IndexOf("`r")))  #return not newline
                                            $actionObject.ActionStatus = $errorCode
                                        }
                                        else
                                        {
                                            $actionObject.ActionStatus = "ErrorDuringStopAction"
                                        }
                                        Write-Output $errorMessage
                                        $actionObject.Information = $errorMessage
                                    }
                                } #end of if not skip
                            }
                            'AKS'
                            {

                                $cluster = get-azakscluster -name $resourceObjInfo.Name -ResourceGroupName $resourceObjInfo.ResourceGroupName

                                if(($cluster.AgentPoolProfiles | Where-Object {$_.Mode -eq "System"}).count -eq 0) #if the system pool is 0 its already stopped
                                {
                                    Write-Output " $($resourceObjInfo.Name) is already stopped"
                                    $actionObject.ActionStatus = "Skipped"
                                    $actionObject.Information = "AlreadyStopped"
                                }
                                else
                                {

                                    if($cluster.AgentPoolProfiles.Type -eq 'VirtualMachineScaleSets') #can only stop if built on VMSS
                                    {
                                        #Write-Output "Resource AKS Cluster $clusterName is VMSS-based and is being stopped"
                                        #https://docs.microsoft.com/en-us/rest/api/aks/managedclusters/stop

                                        <#
                                        #Create token
                                        $accessToken = (Get-AzAccessToken).Token #ARM audience
                                        $authHeader = @{
                                            'Content-Type'='application/json'
                                            'Authorization'='Bearer ' + $accessToken
                                        }

                                        #Submit the REST call
                                        $resp = Invoke-WebRequest -Uri "https://management.azure.com/subscriptions/$($actionObject.SubID)/resourceGroups/$($resourceObjInfo.ResourceGroupName)/providers/Microsoft.ContainerService/managedClusters/$($resourceObjInfo.Name)/stop?api-version=2021-02-01" -Method POST -Headers $authHeader
                                        if($resp.StatusCode -eq 202)
                                        {
                                            write-output "Stop submitted successfully"
                                            $actionObject.ActionStatus = "Success"
                                        }
                                        else
                                        {
                                            write-output "Stop submit failed, $($resp.StatusCode) - $($resp.StatusDescription)"
                                            $actionObject.ActionStatus = "ErrorDuringStopAction"
                                        }
                                        #>
                                        write-output "Skipping AKS currently"
                                        $actionObject.ActionStatus = "Skipped"
                                        $actionObject.Information = "AKSException"
                                        #az aks stop --name $clusterName --resource-group $clusterRG
                                    }
                                    else
                                    {
                                        Write-Output "Resource AKS Cluster $clusterName is NOT VMSS-based and cannot be stopped.`nUser mode pools could be set to 0 and the system pool to 1 to minimize cost."
                                        $actionObject.ActionStatus = "CannotBeStopped"
                                        <#$nodePools = $cluster.AgentPoolProfiles
                                        foreach($nodePool in $nodePools)
                                        {
                                            if($nodePool.Mode -eq 'System')
                                            {
                                                #Scale to 1 as cannot shut down

                                            }
                                            else
                                            {
                                                #Scale to 0

                                            }
                                            $URLPutContent = "https://management.azure.com/subscriptions/$subID/resourceGroups/$clusterRG/providers/Microsoft.ContainerService/managedClusters/$clusterName?api-version=2020-11-01"
                                            $resp = Invoke-WebRequest -Uri $URLPostContent -Method Put -Headers $authHeader
                                            if($resp.StatusCode -eq 202)
                                            {
                                                write-output "Stop submitted succesfully"
                                            }
                                            else
                                            {
                                                write-output "Stop submit failed, $($resp.StatusCode) - $($resp.StatusDescription)"
                                            }
                                        } #>
                                    } #end of if VMSS based AKS
                                } #end of if not already stopped
                            } #AKS
                            Default {
                                Write-Error " * Resource $($actionObject.ResourceName) $($actionObject.ResourceType) unsupported type"
                                $actionObject.ActionStatus = "UnsupportedObject"
                            }
                        } #end of switch statement for type

                        #Update the tag if this did not error
                        if($actionObject.ActionStatus -eq "Success")
                        {
                            if($configurationSettings.tagWrite)
                            {
                                $tags = $resourceObjInfo.Tags #get current ones
                                if($null -ne $tags)
                                {
                                    if(!$tags.ContainsKey($configurationSettings.tagName)) #not already got the tag
                                    {
                                        Write-Output "  - Adding Tag to resource"
                                        Update-AzTag -ResourceId $actionObject.ResourceID -Tag $tagToStamp -Operation Merge  > $null
                                    }
                                }
                                else #no tags
                                {
                                    Write-Output "  - Setting tag on resource"
                                    New-AzTag -ResourceId $actionObject.ResourceID -Tag $tagToStamp  > $null #just set to the tag quietly
                                }
                            }
                        }
                    }
                    else
                    {
                        Write-Error " * Resource $($actionObject.ResourceName) $($actionObject.ResourceType) was not found"
                        $actionObject.ActionStatus = "ObjectNotFound"
                    } #end of if resource not null
                } #end of what-if
                else
                {
                    Write-Host "What if: Would have deallocated the resource" -ForegroundColor Cyan
                }
            } #for each object

            Write-Output "`nCompleted actions at $(get-date)"

            #write out to file the exception list of resources
            $exemptObjectArray | ConvertTo-Json | Out-File -FilePath '.\exemptresource.json'
            $exemptCount = ($exemptObjectArray | measure-object).Count

            #write out to file the resources that did not succeed
            $resourceObjectArray | Where-Object {$_.ActionStatus -ne 'Success' -and $_.ActionStatus -ne 'Skipped'} | ConvertTo-Json | Out-File -FilePath '.\errorresource.json'
            $failedCount = ($resourceObjectArray | Where-Object {$_.ActionStatus -ne 'Success' -and $_.ActionStatus -ne 'Skipped'} | Measure-Object).Count

            Write-Output "Completed. Files have been created in local folder for the exempt ($exemptCount) and failed ($failedCount) resources."

        } #if typed Yes
        else
        {
           Write-Output "Aborted."
        }
    } #if status good
}