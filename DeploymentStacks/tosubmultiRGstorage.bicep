targetScope = 'subscription'

param resourceGroupName1 string = 'stackdemo-rg1'
param resourceGroupName2 string = 'stackdemo-rg2'
param resourceGroupLocation string = deployment().location

resource demorg1 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName1
  location: resourceGroupLocation
}

resource demorg2 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName2
  location: resourceGroupLocation

}

module firstStorage 'multistorage.bicep' = if (resourceGroupName1 == 'stackdemo-rg1') {
  name: uniqueString(resourceGroupName1)
  scope: demorg1
  params: {
    location: resourceGroupLocation
  }
}

module secondStorage 'multistorage.bicep' = if (resourceGroupName2 == 'stackdemo-rg2') {
  name: uniqueString(resourceGroupName2)
  scope: demorg2
  params: {
    location: resourceGroupLocation
  }
}
