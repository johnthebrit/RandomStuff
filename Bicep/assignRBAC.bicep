param principalId string
param roleDefinitionId string

var roleAssignGUID = guid(principalId,roleDefinitionId)

resource RBACAssign 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: roleAssignGUID
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
  }
}
