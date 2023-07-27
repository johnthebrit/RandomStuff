<#To execute would require the following permissions:
Microsoft.Insights/ActivityLogAlerts/Write
Microsoft.Insights/ActionGroups/Write
Microsoft.Resources/subscriptions/resourcegroups/write

NOTE - If you only need standard ARM roles like Owner and Contributor you could instead simply target the ARM role for email via policy
#>
$subs = Get-Content -Path sublist.txt #this file should have one subscription ID per line
$roles = @('Owner','Contributor') #These roles at the sub level if have email will be added to an action group to receive service health alerts

$nameOfAlertRule = "Core-ServiceHealth-AR-DONOTRENAMEORDELETE"
$nameOfAlertRuleDesc = "Core ServiceHealth Alert Rule DO NOT DELETE OR RENAME"
$nameOfActionGroup = "Core-ServiceHealth-AG-DONOTRENAMEORDELETE"
$nameOfActionGroupShort = "Core-SH-AG" #12 characters or less
$nameOfCoreResourceGroup = "Core-ServiceHealth-RG-DONOTRENAMEORDELETE"
$nameOfLocation = "eastus2"


Write-Output "Input $($subs.count) subscriptions."
$confirmation = Read-Host "Are you Sure You Want To Proceed:"
if ($confirmation -ne 'y')
{
    Write-Output "exiting"
    exit
}

foreach ($sub in $subs)
{
    $errorFound = $false

    #Set context to target subscription
    Write-Output "Subscription $sub"
    try {
        Set-AzContext -Subscription $sub -ErrorAction Stop
    }
    catch {
        Write-Output "Subscription error:"
        Write-Output $_
        $errorFound = $true
    }

    if(!$errorFound) #if no error
    {
        $subScope = "/subscriptions/$sub"
        $emailsToAdd = @()

        #check the core RG exists
        $coreRG = Get-AzResourceGroup -Name $nameOfCoreResourceGroup -ErrorAction SilentlyContinue
        if($null -eq $coreRG)
        {
            write-output "Creating core resource group $nameOfCoreResourceGroup"
            New-AzResourceGroup -Name $nameOfCoreResourceGroup -Location $nameOfLocation
        }

        foreach($role in $roles)
        {
            #write-output "Role $role"
            $members = Get-AzRoleAssignment -Scope $subScope -RoleDefinitionName $role
            foreach ($member in $members) {
                if($member.scope -eq $subScope) #need to check specific to this sub and not inherited from MG
                {
                    #Write-Output "$sub,$($member.DisplayName),$($member.SignInName),$($contrib.ObjectType)"
                    if($null -ne $member.SignInName) #can only add if has email
                    {
                        $emailsToAdd += $member.SignInName
                    }
                }
            }
        }
        $emailsToAdd = $emailsToAdd | Select-Object -Unique #Remove duplicated, i.e. if multiple of the roles
        #$emailsToAdd

        #Look for the Action Group
        $AGObj = Get-AzActionGroup | Where-Object { $_.Name -eq $nameOfActionGroup }
        if($null -eq $AGObj) #not found
        {
            Write-Output "Action Group not found, creating."
            #Note there is also the ability to link directly to an ARM role which per the documentation only is if assigned AT THE SUB and NOT inherited
            $emailReceivers = @()
            foreach ($email in $emailsToAdd) {
                $emailReceiver = New-AzActionGroupReceiver -EmailReceiver -EmailAddress $email -Name $email
                $emailReceivers += $emailReceiver
            }
            Set-AzActionGroup -ResourceGroupName $nameOfCoreResourceGroup -Name $nameOfActionGroup -ShortName $nameOfActionGroupShort -Receiver $emailReceivers
            $AGObj = Get-AzActionGroup | Where-Object { $_.Name -eq $nameOfActionGroup }
        }
        else
        {
            #Is the list matching the current emails
            $currentEmails = $AGObj.EmailReceivers | Select-Object -ExpandProperty EmailAddress

            #need to check it is new ones added so side indicator would be => as would be in the emails to add
            $differences = Compare-Object -ReferenceObject $currentEmails -DifferenceObject $emailsToAdd | Where-Object { $_.SideIndicator -eq "=>"}
            if($null -ne $differences) #if there are differences
            {
                #add them together then find just the unique (we add the existing as could be manually added emails we want to keep)
                $emailstoAdd += $currentEmails
                $emailsToAdd = $emailsToAdd | Select-Object -Unique

                #Now update the action group
                $emailReceivers = @()
                foreach ($email in $emailsToAdd) {
                    $emailReceiver = New-AzActionGroupReceiver -EmailReceiver -EmailAddress $email -Name $email
                    $emailReceivers += $emailReceiver
                }
                Set-AzActionGroup -ResourceGroupName $nameOfCoreResourceGroup -Name $nameOfActionGroup -ShortName $nameOfActionGroupShort -Receiver $emailReceivers
            }
        }

        #Look for the Alert Rule
        $ARObj = Get-AzActivityLogAlert | Where-Object { $_.Name -eq $nameOfAlertRule }
        if($null -eq $ARObj) #not found
        {
            Write-Output "Alert Rule not found, creating."
            $location = 'Global'
            #$condition1 = New-AzActivityLogAlertCondition -Field 'category' -Equal 'ServiceHealth'
            $condition1 = New-AzActivityLogAlertAlertRuleAnyOfOrLeafConditionObject -Field 'category' -Equal 'ServiceHealth'
            $actionGroupsHashTable = @{ Id = $AGObj.Id; WebhookProperty = ""}
            New-AzActivityLogAlert -Location $location -Name $nameOfAlertRule -ResourceGroupName $nameOfCoreResourceGroup -Scope $subScope -Action $actionGroupsHashTable -Condition $condition1 `
                -Description $nameOfAlertRuleDesc -Enabled $true
        }
    }
    Write-Output ""
}