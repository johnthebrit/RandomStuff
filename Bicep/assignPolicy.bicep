param policyID string
param policyName string

var policyAssignname = '${policyName}-${resourceGroup().name}'

resource PolicyAssign 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: policyAssignname
  properties: {
    policyDefinitionId: policyID
    displayName: 'Applied policy ${policyName}'
    parameters: {
      listOfAllowedLocations:{
        value: [
          'south central us'
          'east us'
        ]
      }
    }
  }
}
