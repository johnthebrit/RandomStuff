$pics = [environment]::getfolderpath("mypictures")
$docs = [environment]::getfolderpath("mydocuments")



#Show system assigned identity for VM and function DemoVM, savtechazurebingo
#From within an Azure resource can use managed identity
Connect-AzAccount -Identity
Get-AzContext
#Test access as the system-assigned managed identity (show the IAM)
#Note the -UseConnectedAccount to connect to storage using AAD data plane instead of account keys
New-AzStorageContext -UseConnectedAccount -StorageAccountName sascussavilltech `
    | Get-AzStorageBlobContent -Container 'images' -Blob 'OllieandEddieCerealEating.jpg' -Destination $pics

#View the service principal for the resource
Get-AzADServicePrincipal -DisplayNameBeginsWith DemoVM #VM
Get-AzADServicePrincipal -DisplayNameBeginsWith savtechazurebingo #Function

#View the system-assigned identity
$VM = Get-AzVM -ResourceGroupName RG-DemoVM -Name DemoVM
$VM.Identity.PrincipalId


#Use a user-assigned managed identity that has been allocated to the VM
install-module az.managedserviceidentity -scope allusers
$identity = Get-AzUserAssignedIdentity -ResourceGroupName 'rg-scusa' -Name 'mi-savilltech1'
Connect-AzAccount -Identity -AccountId $identity.ClientId # Run on the virtual machine
Get-AzContext
#Try getting blob as this identity
New-AzStorageContext -UseConnectedAccount -StorageAccountName sascussavilltech `
    | Get-AzStorageBlobContent -Container 'images' -Blob 'OllieandEddieCerealEating.jpg' -Destination $pics



Select-AzContext "SavillTech Dev"

#Using a service principal instead
#Can be a secret and/or certificate for the authentication
#View as AAD - App registrations - Owned applications
Get-AzADServicePrincipal | Sort-Object DisplayName | ft DisplayName, ServicePrincipalNames -AutoSize

#With a password (if no parameters passed)
$SPPass = New-AzADServicePrincipal -DisplayName SavSPwithPasswordAuth #will have contrib over subscription by default
#Get the auto generated password
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SPPass.Secret)
$UnsecureSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
#HOW WILL YOU STORE THIS SECRET?!

#View now under app registrations, all applications and search. can see certs&secrets. This links to the enterprise app
#Now under enterprise apps change to app type All and search to see the service principal
#Show subscription to see the RBAC contrib

#With a custom password
#Import-Module -Name Az.Resources # Imports the PSADPasswordCredential object
$credentials = New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential -Property @{StartDate=Get-Date; EndDate=Get-Date -Year 2023; Password='R3allyStr0ngPa55!'}
$SPCustomPass = New-AzAdServicePrincipal -DisplayName SavSPwithCustomPasswordAuth -PasswordCredential $credentials #no default permissions

#if wanted to file and back
$securePass = ConvertTo-SecureString -AsPlainText -Force -String 'R3allyStr0ngPa55!'
$securePass | ConvertFrom-SecureString | Out-File -FilePath $docs\securepass.txt
(Get-Content -Path $docs\securepass.txt | ConvertTo-SecureString)
Remove-Item $docs\securepass.txt

#Check roles assigned
Get-AzRoleAssignment -ObjectId $SPPass.Id
Get-AzRoleAssignment -ObjectId $SPCustomPass.Id

New-AzRoleAssignment -ApplicationId $SPCustomPass.ServicePrincipalNames[0] -RoleDefinitionName 'Reader'
Get-AzRoleAssignment -ObjectId $SPCustomPass.Id -RoleDefinitionName 'Reader' | Remove-AzRoleAssignment

#Need the AAD tenant
$tenantID = (get-azcontext).Tenant.Id

#Authenticate with secret
[pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($SPPass.ApplicationId, (ConvertTo-SecureString $UnsecureSecret -AsPlainText -Force))
Connect-AzAccount -Credential $Credential -Tenant $tenantID -ServicePrincipal
Get-AzContext
$SPPass
#Am authenticated with the service principal
Get-AzResourceGroup #etc

#Authenticate with custom secret
[pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($SPCustomPass.ApplicationId, (ConvertTo-SecureString 'R3allyStr0ngPa55!' -AsPlainText -Force))
Connect-AzAccount -Credential $Credential -Tenant $tenantID -ServicePrincipal
Get-AzContext
$SPCustomPass
#Am authenticated with the service principal


#auth back as me via context switch
Select-AzContext "SavillTech Dev"


#Now for a certificate
#Will create a self-signed cert
#Could be from enterprise CA etc, need private key and protect!
$cert = New-SelfSignedCertificate -CertStoreLocation "cert:\CurrentUser\My" `
  -Subject "CN=selfsignCert" -KeySpec KeyExchange
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
#cert visible now under your certificates
Get-ChildItem Cert:\CurrentUser\My | ft
#if look in MMC will see have the private key

$SPCert = New-AzADServicePrincipal -DisplayName SavSPwithCertAuth `
  -CertValue $keyValue -EndDate $cert.NotAfter -StartDate $cert.NotBefore

Get-AzRoleAssignment -ObjectId $SPCert.Id #No defaults
#Grant roles if required
New-AzRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $SPCert.ApplicationId

#If need thumbprint
$Thumbprint = (Get-ChildItem cert:\CurrentUser\My\ | Where-Object {$_.Subject -eq "CN=selfsignCert" }).Thumbprint

#authenticate as the service principal
Connect-AzAccount -CertificateThumbprint $cert.Thumbprint `
    -ApplicationId $SPCert.ApplicationId -Tenant $tenantID -ServicePrincipal
Get-AzContext
$SPCert

#Example with CA. Same idea just different source of the cert
#https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-authenticate-service-principal-powershell#create-service-principal-with-certificate-from-certificate-authority


#auth back as me via context switch
Select-AzContext "SavillTech Dev"


#You do need to roll secrets and certificates!!

#Can use New-AzADAppCredential to roll secrets and certificates for existing service principals
$SecureStringPassword = ConvertTo-SecureString -String "Extra5ecur3Pa55!#" -AsPlainText -Force
New-AzADAppCredential -ApplicationId $SPCert.ApplicationId -Password $SecureStringPassword `
    -EndDate (get-date).AddYears(1) #need a valid end date, e.g. 1 year
#if wanted to use the app object ID to add
#$appID = Get-AzADApplication -ApplicationId $SPCert.ApplicationId
#New-AzADAppCredential -ObjectId $appID.ObjectId -Password $SecureStringPassword




#Cleaning up
Remove-AzADServicePrincipal -ApplicationId $SPPass.ApplicationId -Force
Remove-AzADServicePrincipal -ApplicationId $SPCustomPass.ApplicationId -Force
Remove-AzADServicePrincipal -ApplicationId $SPCert.ApplicationId -Force
#Remove-AzADAppCredential -ApplicationId $SPPass.ApplicationId -Force
#Remove-AzADAppCredential -ApplicationId $SPCustomPass.ApplicationId -Force
#Remove-AzADAppCredential -ApplicationId $SPCert.ApplicationId -Force
Remove-AzADApplication -ApplicationId $SPPass.ApplicationId -Force
Remove-AzADApplication -ApplicationId $SPCustomPass.ApplicationId -Force
Remove-AzADApplication -ApplicationId $SPCert.ApplicationId -Force

Get-ChildItem cert:\CurrentUser\My\ | Where-Object {$_.Subject -eq "CN=selfsignCert" } | Remove-Item

#IF using az
<#az ad sp create-for-rbac --name "{sp-name}" --sdk-auth --role contributor \
    --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group}#>
