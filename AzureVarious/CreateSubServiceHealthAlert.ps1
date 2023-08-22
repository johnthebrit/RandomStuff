<#To execute would require the following permissions:
Microsoft.Insights/ActivityLogAlerts/Read
Microsoft.Insights/ActivityLogAlerts/Write
Microsoft.Insights/ActionGroups/Read
Microsoft.Insights/ActionGroups/Write
Microsoft.Resources/subscriptions/resourcegroups/Read
Microsoft.Resources/subscriptions/resourcegroups/Write

NOTE - If you only need standard ARM roles like Owner and Contributor you could instead simply target the ARM role for email via policy, e.g. for the action group targets
NOTE - This will NOT work if they are groups. If groups have the roles you will need to use this script approach
For the template to deploy use https://github.com/Azure/azure-quickstart-templates/blob/master/demos/monitor-servicehealth-alert/azuredeploy.json and replace the emailReceivers part with:
"armRoleReceivers": [
    {
        "name": "Email Owner",
        "roleId": "8e3af657-a8ff-443c-a75c-2fe8c4bcb635",
        "useCommonAlertSchema": true
    },
    {
        "name": "Email Contrib",
        "roleId": "b24988ac-6180-42a0-ab88-20f7382dd24c",
        "useCommonAlertSchema": true
    }
]

To output a list of all your subscription IDs using Resource Graph you can use
resourcecontainers
    | where type=='microsoft.resources/subscriptions'
    | project subscriptionId

If debug and want to see verbose
$VerbosePreference = "Continue"

** Note This script is based on a RBAC role assigned. If you use PIM and RBAC assignment is not useful
it would be easy to change the script to look for a subscription level "Owner" or "Contact" tag you set
which could then be read and the values added to the action group!
#>

$subs = Get-Content -Path sublist.txt #this file should have one subscription ID per line
$roles = @('Owner','Contributor') #These roles at the sub level if have email will be added to an action group to receive service health alerts
#Enable one of the following based on if there are specific groups that have roles you DON'T want included in health alerts
#$groupsToSkip = @('Jl','Avengers')
$groupsToSkip = @() #if none

$nameOfAlertRule = "Core-ServiceHealth-AR-DONOTRENAMEORDELETE"
$nameOfAlertRuleDesc = "Core ServiceHealth Alert Rule DO NOT DELETE OR RENAME"
$nameOfActionGroup = "Core-ServiceHealth-AG-DONOTRENAMEORDELETE"
$nameOfActionGroupShort = "Core-SH-AG" #12 characters or less
$nameOfCoreResourceGroup = "Core-ServiceHealth-RG-DONOTRENAMEORDELETE"
$nameOfLocation = "eastus2"


#set this to true if the existing action group members should be replaced completely if the action group already exists instead of having new people appended to existing members
$REPLACENOTADD = $false


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
        Write-Error "!! Subscription error:"
        Write-Error $_
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
            Write-Verbose "Role $role"
            #Note this will get all of this role at this scope and CHILD (e.g. also RGs so we have to continue to filter)
            $members = Get-AzRoleAssignment -Scope $subScope -RoleDefinitionName $role
            #$members | ft objectType, RoleDefinitionName, DisplayName, SignInName

            foreach ($member in $members) {
                if($member.scope -eq $subScope) #need to check specific to this sub and not inherited from MG or a child RG
                {
                    Write-Verbose "$sub,$($member.DisplayName),$($member.SignInName),$($contrib.ObjectType)"

                    #Change to support groups and enumerate for members via Get-AzADGroupMember -GroupDisplayName
                    if($member.ObjectType -eq 'Group')
                    {
                        #check if the group should be excluded ($groupsToSkip)
                        if($groupsToSkip -notcontains $member.DisplayName)
                        {
                            Write-Verbose "Group found $($member.DisplayName) - Expanding"
                            $groupMembers = Get-AzADGroupMember -GroupDisplayName $member.DisplayName
                            $emailsToAdd += $groupmembers | Where-Object {$_.Mail -ne $null} | select-object -ExpandProperty Mail #we only add if has an email attribute
                        }
                    }

                    #Can also check the email for users incase their email is different from UPN via Get-AzADUser -UserPrincipalName
                    if($member.ObjectType -eq 'User')
                    {
                        Write-Verbose "User found $($member.SignInName) - Checking for email attribute"
                        $userDetail = Get-AzADUser -UserPrincipalName $member.SignInName
                        if($null -ne $userDetail.Mail)
                        {
                            $emailsToAdd += $userDetail.Mail
                        }
                    }
                }
            }
        }
        $emailsToAdd = $emailsToAdd | Select-Object -Unique #Remove duplicated, i.e. if multiple of the roles
        Write-Verbose "Emails to add: $emailsToAdd"

        #Look for the Action Group
        $AGObj = Get-AzActionGroup | Where-Object { $_.Name -eq $nameOfActionGroup }
        $AGObjFailure = $false
        if($null -eq $AGObj) #not found
        {
            Write-Output "Action Group not found, creating."
            if($emailsToAdd.Count -gt 0)
            {
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
                Write-Error "!! Could not create action group for subscription $sub as no valid emails found. This will also stop alert rule creation"
                $AGObjFailure = $true
            }
        }
        else
        {
            if(!$REPLACENOTADD)
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
                }
            }

            #Now update the action group
            $emailReceivers = @()
            foreach ($email in $emailsToAdd) {
                $emailReceiver = New-AzActionGroupReceiver -EmailReceiver -EmailAddress $email -Name $email
                $emailReceivers += $emailReceiver
            }

            try
            {
                Set-AzActionGroup -ResourceGroupName $nameOfCoreResourceGroup -Name $nameOfActionGroup -ShortName $nameOfActionGroupShort -Receiver $emailReceivers
            }
            catch
            {
                Write-Error "!! Error updating action group for $sub"
                Write-Error $_
                $emailReceivers
            }
        }

        #Look for the Alert Rule
        $ARObj = Get-AzActivityLogAlert | Where-Object { $_.Name -eq $nameOfAlertRule }
        #If wanted to find if ANY Alert Rule existed for Service Health and then could add an -and (ANYARSHFound -ne $null) to below condition
        #$ANYARSHFound = Get-AzActivityLogAlert | Format-List | out-string | select-string "`"equals`": `"ServiceHealth`""

        if(($null -eq $ARObj) -and (!$AGObjFailure)) #not found and not a failure creating the action group
        {
            Write-Output "Alert Rule not found, creating."
            $location = 'Global'
            $condition1 = New-AzActivityLogAlertAlertRuleAnyOfOrLeafConditionObject -Field 'category' -Equal 'ServiceHealth'
            $actionGroupsHashTable = @{ Id = $AGObj.Id; WebhookProperty = ""}
            New-AzActivityLogAlert -Location $location -Name $nameOfAlertRule -ResourceGroupName $nameOfCoreResourceGroup -Scope $subScope -Action $actionGroupsHashTable -Condition $condition1 `
                -Description $nameOfAlertRuleDesc -Enabled $true
        }
    }
    Write-Output ""
}