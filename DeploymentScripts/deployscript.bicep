param location string = resourceGroup().location
param subId string = subscription().subscriptionId // current sub
param usmiRG string = 'RG-SCUSA'
param uamiName string = 'mi-savilltech1'
param currentTime string = utcNow()
param storageAccountName string = 'sascussavilltech'

resource mngId 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: 'mi-savilltech1'
  scope: resourceGroup(subId,usmiRG) //if MI in different RG than template deployment target RG
}

resource dScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'scriptTest'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${mngId.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '5.0'
    scriptContent: '''
Param([string] $StorageAccountName)
Connect-AzAccount -Identity
$DeploymentScriptOutputs["output"] = New-AzStorageContext -UseConnectedAccount -StorageAccountName $StorageAccountName `
    | Get-AzStorageBlob -Container 'images' -Blob * | Out-String
'''
    arguments: concat('-StorageAccountName', ' ', storageAccountName)
    cleanupPreference: 'OnSuccess' //when to cleanup the storage account and ACI instance or OnExpiration, Always
    retentionInterval: 'PT4H' //keep the deployment script resource for this duration (ISO 8601 format) and ACI/SA if OnExpiration cleanuppreference
    forceUpdateTag: currentTime // ensures script runs every time
  }
}

// print logs from script after template is finished deploying
output scriptOutput string = dScript.properties.outputs.output
//output scriptLogs string = reference('${dScript.id}/logs/default', dScript.apiVersion, 'Full').properties.log
