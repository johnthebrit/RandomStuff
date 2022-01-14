# Managed Identity Deep Dive

Notes from the video available at LINKHERE

## Looking at Service Principals

We will use Microsoft Graph to look at the service principals. With MS graph we need a certain permission scope.

These scopes are described at https://docs.microsoft.com/en-us/graph/permissions-reference

We will use Application.Read.All to read the service principals.

``` powershell
Connect-MgGraph -Scopes "Application.Read.All"

#Switch to beta profile to light up features
Select-MgProfile -Name "beta"

#View my scope
Get-MgContext
(Get-MgContext).Scopes

#Environments, i.e. various clouds
Get-MgEnvironment
```
In the above note the TenantId as this will match the AppOwnerOrganizationId for app regitrations we see later.

Service principals are the representation of an application in the Azure AD. An app registration is an app created in our tenant that could be single or multi tenant. It will also have a service principal in our tenant.

``` powershell
Get-MgApplication -Filter  "DisplayName eq 'RBACTestAppReg'"
Get-MgServicePrincipal -Filter "DisplayName eq 'RBACTestAppReg'" |
    Format-Table DisplayName, Id, AppId, SignInAudience, AppOwnerOrganizationId
```

The same applies for an enterprise application that is enabled in our tenant. The service principal is the representation of the global application object in our tenant.

``` powershell
Get-MgServicePrincipal -Filter "DisplayName eq 'Netflix' or DisplayName eq 'Microsoft Teams'" |
    Format-Table DisplayName, Id, AppId, SignInAudience, AppOwnerOrganizationId
```
## Managed Identities

First we can look at all of the ones in our tenant. Note the different types of resource.
```powershell
Get-MgServicePrincipal -Filter "ServicePrincipalType eq 'ManagedIdentity'" |
    Format-Table DisplayName, Id, AlternativeNames -AutoSize
```

Focus on a few key service princpals. One a system assigned and one a user assigned.
```powershell
#View service principals for our managed identities which is name of resource for SA or UA-MI name
$SPs = Get-MgServicePrincipal -Filter "DisplayName eq 'mi-savilltech1' or DisplayName eq 'DemoVM'"
$SPs | format-table DisplayName,ServicePrincipalType,ID, AppID -autosize
#Note there is NO application for this service principal, its just randomly generated
Get-MgApplication -ApplicationId $SPs[0].AppID
#Can look at the detail but remember, we actually don't care about this SP really, its fully managed!
$SPs[0] | format-list
```
Note another way to view them but less efficient
```powershell
#$SPs = Get-MgServicePrincipal -All
#$SPs | where {$_.DisplayName -eq "mi-savilltech1" -or $_.DisplayName -eq "DemoVM"}
```

## Managed Identity Demonstration
Connect using the default managed identity. This would be the system assigned or if no system assigned then the user assigned (assuming there was only one).
```powershell
#Using Az module
Connect-AzAccount -Identity #Connect as the managed identity
Get-AzContext #note the account
```
Viewing the identity
```powershell
#The system assigned MI has read role on the VM object
$VMRG = "RG-DEMOVM"
$VMName = "DemoVM"
$vmInfo = Get-AzVM -ResourceGroupName $VMRG -Name $VMName
$spID = $vmInfo.Identity.PrincipalId
write-output "The managed identity for Azure resources service principal ID is $spID"
```
Lets use it to look at resources
```powershell
#Look at storage
$storcontext = New-AzStorageContext -StorageAccountName 'sascussavilltech' -UseConnectedAccount
Get-AzStorageBlobContent -Container 'images' -Blob 'OllieandEddieCerealEating.jpg' `
    -Destination "C:\temp\" -Context $storcontext

#Look at a secret
$secretText = Get-AzKeyVaultSecret -VaultName "SavillVaultRBAC" -Name "Secret1" -AsPlainText
Write-Output $secretText

#We can use the REST API as well getting a token from the IMDS then using it to get the secrets
#Remember for VMs we use the Instance MetaData Service (IMDS), other resources access other endpoints applicable to their type
$response = Invoke-WebRequest -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -Method GET -Headers @{Metadata="true"}
$content = $response.Content | ConvertFrom-Json
$Token = $content.access_token
(Invoke-WebRequest -Uri https://SavillVaultRBAC.vault.azure.net/secrets/Secret1?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $Token"}).content


#Lets try another secret
$secretText2 = Get-AzKeyVaultSecret -VaultName "SavillVaultRBAC" -Name "Secret2" -AsPlainText
```
At this point we will use a different, user-assigned identity
```powershell
#User assigned managed identity examine
#Install the managed service identity module as not part of Az default
Install-Module az.ManagedServiceIdentity -Scope allusers -Force

$resourceGroupName = "RG-SCUSA"
$userAssignedIdentityName = "mi-savilltech1"
#Note I gave the SA-MI reader on the object so it could get the information on the resource
$usmi = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $userAssignedIdentityName
$usmi

#Connect as the user assigned managed identity instead of the default system assigned
Connect-AzAccount -Identity -AccountId $usmi.ClientId
Get-AzContext

#Lets try to access that secret again
$secretText2 = Get-AzKeyVaultSecret -VaultName "SavillVaultRBAC" -Name "Secret2" -AsPlainText
$secretText2
```
Note can easily assign managed identities with PowerShell, CLI etc
```powershell
Get-AzVM -ResourceGroupName $RG -Name $VM | Update-AzVM -IdentityType UserAssigned -IdentityId $usmi.Id
```
The same works with AZ CLI
```bash
az login --identity
az resource list -n DemoVM --query [*].identity.principalId --out tsv
#Look at the secret 1 (that the system assigned had data RBAC on)
az keyvault secret show --vault-name SavillVaultRBAC --name Secret1 --query value -o tsv
```
