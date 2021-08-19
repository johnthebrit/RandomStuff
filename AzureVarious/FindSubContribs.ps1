$subs = Get-AzSubscription
foreach ($sub in $subs) {
    $contribs = Get-AzRoleAssignment -Scope /subscriptions/$($sub.Id) -RoleDefinitionName Contributor
    foreach ($contrib in $contribs) {
        Write-Output "$($sub.Id),$($sub.Name),$($contrib.DisplayName),$($contrib.SignInName),$($contrib.ObjectType),$($contrib.ObjectId)"
    }
}