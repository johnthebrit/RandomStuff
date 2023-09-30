targetScope = 'managementGroup'

param subscriptionID string

param deployLocation string = deployment().location

module subDeployModule 'tosubmultiRGstorage.bicep' = {
  name: 'deployToSub'
  params: { resourceGroupLocation: deployLocation }
  scope: subscription(subscriptionID)
}
