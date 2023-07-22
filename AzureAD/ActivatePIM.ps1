[CmdletBinding(PositionalBinding=$false)]
Param(
    [Parameter(Mandatory, ValueFromRemainingArguments)]
    [string]$Message
)


#Install-Module Microsoft.Graph.Beta.Identity.Governance -Scope AllUsers -Force
Import-Module Microsoft.Graph.Beta.Identity.Governance

#Connect-MgGraph -Scopes User.Read.All,RoleEligibilitySchedule.Read.Directory,RoleEligibilitySchedule.ReadWrite.Directory,RoleManagement.ReadWrite.Directory,RoleManagement.Read.Directory,RoleManagement.Read.All,PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup,PrivilegedAccess.ReadWrite.AzureADGroup
$context = Get-MgContext
$currentUser = (Get-MgUser -UserId $context.Account).Id #needs User.Read.All

#to view groups available
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
	justification = $Message
}

New-MgBetaIdentityGovernancePrivilegedAccessGroupAssignmentScheduleRequest -BodyParameter $params
