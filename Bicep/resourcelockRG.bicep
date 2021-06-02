//add a lock on the RG
resource resourceLock 'Microsoft.Authorization/locks@2016-09-01' = {
  name: 'DoNotDelete'
  scope: resourceGroup()
  properties: {
    level: 'CanNotDelete'
  }
}
