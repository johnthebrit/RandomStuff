$subs = Get-Content -Path sublist.txt
$roles = @('Owner','Contributor')

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

foreach ($sub in $subs) {
    $errorFound = $false
    Write-Output "Subscription $sub"
    try {
        Set-AzContext -Subscription $sub -ErrorAction Stop
    }
    catch {
        Write-Output "Subscription error:"
        Write-Output $_
        $errorFound = $true
    }

    if(!$errorFound)
    {
        $subScope = "/subscriptions/$sub"
        $emailsToAdd = @()

        #check the RG exists, $nameOfCoreResourceGroup
        $coreRG = Get-AzResourceGroup -Name $nameOfCoreResourceGroup -ErrorAction SilentlyContinue
        if($null -eq $coreRG)
        {
            write-output "Creating core resource group $nameOfCoreResourceGroup"
            New-AzResourceGroup -Name $nameOfCoreResourceGroup -Location $nameOfLocation
        }

        foreach($role in $roles)
        {
            write-output "Role $role"
            $members = Get-AzRoleAssignment -Scope $subScope -RoleDefinitionName $role
            foreach ($member in $members) {
                if($member.scope -eq $subScope) #need to check specific to this sub and not inherited from MG
                {
                    Write-Output "$sub,$($member.DisplayName),$($member.SignInName),$($contrib.ObjectType)"
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
            #Note there is also the ability to link directly to an ARM role however would not be those ONLY at the sub scope
            $emailReceivers = @()
            foreach ($email in $emailsToAdd) {
                $emailReceiver = New-AzActionGroupReceiver -EmailReceiver -EmailAddress $email -Name $email
                $emailReceivers += $emailReceiver
            }
            Set-AzActionGroup -ResourceGroupName $nameOfCoreResourceGroup -Name $nameOfActionGroup -ShortName $nameOfActionGroupShort -Receiver $emailReceivers
            $AGObj = Get-AzActionGroup | Where-Object { $_.Name -eq $nameOfActionGroup }
        }

        #Look for the Alert Rule
        $ARObj = Get-AzActivityLogAlert | Where-Object { $_.Name -eq $nameOfAlertRule }
        if($null -eq $ARObj) #not found
        {
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