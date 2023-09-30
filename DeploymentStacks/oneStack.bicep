param location string = resourceGroup().location
param storageAccountName string = 'store${uniqueString(resourceGroup().id)}'
param vnetName string = 'vnetdemo${uniqueString(resourceGroup().id)}'

// Select all lines and Ctrl + / to multi-comment and uncomment

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${storageAccountName}demo1'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_GRS'
  }
}

resource storageAccount2 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${storageAccountName}demo2'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_GRS'
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Subnet-1'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'Subnet-2'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}
