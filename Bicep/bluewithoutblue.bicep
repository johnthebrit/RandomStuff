//get-azadgroup -displayname "JL"  #will want the ID
//Get-AzRoleDefinition -Name Contributor | ft name, Id

//New-AzSubscriptionDeployment -Name TestDeployment -Location 'south central us' -TemplateFile bluewithoutblue.bicep

//normally default scope is resource group but we will target subscription
targetScope = 'subscription'

//create a resource group
resource bwbRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'BWB-RG'
  location: 'South Central US'
}

//create a storage account in the resource group via a module
module storageAccount 'storageaccount.bicep' = {
  name: 'storageModule'
  scope: bwbRG
  params: {
    name: 'savtechscussabebsa'
  }
}

//apply an RBAC permission on the RG
var contributor = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

module RBACApply 'assignRBAC.bicep' = {
  name: 'RBACModule'
  scope: bwbRG
  params: {
    roleDefinitionGUID: contributor
    principalId: '63600c24-ba49-4881-9ed2-6699d28df84b' //JL
  }
}

//apply a policy on the RG
module policyApply 'assignPolicy.bicep' = {
  name: 'PolicyModule'
  scope: bwbRG
  params: {
    policyID: tenantResourceId('microsoft.authorization/policydefinitions', 'e56962a6-4747-49cd-b67b-bf8b01975c4c')
    policyName: 'Allowed locations'
  }
}

//add a lock on the RG via a module
module resourceLock 'resourcelockRG.bicep' = {
  name: 'RGLockModule'
  scope: bwbRG
}

output subID string = subscription().id

//bicep build ./bluewithoutblue.bicep
