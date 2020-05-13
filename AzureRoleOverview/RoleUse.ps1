Get-AzRoleDefinition | FT Name, IsCustom
Get-AzRoleDefinition 'Network Peering Target Role' | convertto-json  # then write to file to change ID to null, change scope and details
New-AzRoleDefinition -InputFile "networkpeerrole.json"
New-AzRoleDefinition -InputFile "VMReadandRunExtrole.json"

<#
https://docs.microsoft.com/en-us/azure/role-based-access-control/custom-roles
"AssignableScopes": [
    "/subscriptions/{subscriptionId1}",
    "/subscriptions/{subscriptionId2}",
    "/providers/Microsoft.Management/managementGroups/{groupId1}"
#>