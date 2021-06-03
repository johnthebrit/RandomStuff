param principalId string
param roleDefinitionGUID string

resource roleDef 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleDefinitionGUID
}

var roleAssignGUID = guid(principalId,roleDef.id)

resource RBACAssign 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: roleAssignGUID
  properties: {
    roleDefinitionId: roleDef.id
    principalId: principalId
  }
}
