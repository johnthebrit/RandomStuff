param location string = resourceGroup().location
param storageAccountName1 string = 'stackstore1${uniqueString(resourceGroup().id)}'
param storageAccountName2 string = 'stackstore2${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName1
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource storageS1 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName2
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}
