#Install-Module Microsoft.Graph.Beta.Identity.Governance
Import-Module Microsoft.Graph.Beta.Identity.Governance

Connect-MgGraph -Scopes RoleEligibilitySchedule.Read.Directory,RoleEligibilitySchedule.ReadWrite.Directory,RoleManagement.ReadWrite.Directory,RoleManagement.Read.Directory,RoleManagement.Read.All,PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup,PrivilegedAccess.ReadWrite.AzureADGroup
$context = Get-MgContext
$currentUser = (Get-MgUser -UserId $context.Account).Id

#Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleRequest -All

$params = @{
	accessId = "member"
	principalId = $currentUser
	groupId = "fa7798c1-fd8b-49d9-a555-7a199ef46190"
	action = "SelfActivate"
	scheduleInfo = @{
		startDateTime = Get-Date
		expiration = @{
			type = "afterDateTime"
			endDateTime = (Get-Date).AddHours(2)
		}
	}
	justification = "Gimme the group membership"
}

New-MgBetaIdentityGovernancePrivilegedAccessGroupAssignmentScheduleRequest -BodyParameter $params