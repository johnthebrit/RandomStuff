extension microsoftGraph

// param location string = resourceGroup().location

resource testgroup1 'Microsoft.Graph/groups@v1.0' = {
  displayName: 'Test Group 1'
  mailEnabled: false
  mailNickname: 'test-group-1'
  securityEnabled: true
  uniqueName: 'testgroup1'
  members: [
    '730c65b5-18ac-4cbf-a922-2469d4366110'
    '0a27b6b7-2327-4ce6-94c8-78008693bbd9'
  ]
}

// resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
//  name: 'testUAMI007'
//  location: location
// }
