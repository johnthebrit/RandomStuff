<#References
https://devblogs.microsoft.com/powershell/secretmanagement-and-secretstore-are-generally-available/
#>

#Install elevated
Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore -Scope AllUsers

#Common set of commands can use across vaults (where secrets are stored)
Get-Command -Module Microsoft.PowerShell.SecretManagement

#Commands to manage the Secret Store vault
Get-Command -Module Microsoft.PowerShell.SecretStore

#What vaults are registered
Get-SecretVault

#Can use the SecretStore as a vault
Register-SecretVault -Name SecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

#Store a secret in it
Set-Secret -Name Password1 -Secret "Pa55word"
#WILL HAVE TO ENTER A PASSWORD FIRST TIME SET SECRET for the secret store, this is to unlock the vault. Will be prompted if timed out
Get-SecretStoreConfiguration
$secureString = ConvertTo-SecureString "Password to the vault" -AsPlainText -Force
Unlock-SecretStore -Password $secureString
Set-SecretStoreConfiguration -Authentication None #don't require password to unlock. different from prompt

#Store for the files
#localstore is actual data
#secretvaultregistry has json file of configuration
Get-ChildItem $env:LOCALAPPDATA\Microsoft\PowerShell\secretmanagement
#Non windows under $HOME/.secretmanagement

Get-Secret -Name Password1 -AsPlainText
Set-Secret -Name Password1 -Secret "N3wPa55word"

#Useful later!!!
Set-Secret -Name DevSubID -Secret "YourSubID"
$AzSubID = Get-Secret -Name DevSubID -AsPlainText

#secrets can also be hash tables
Set-Secret -Name Password2 -Secret @{ username1 = "Pa55word1"; username2 = "N3verGue55"}
$creds = Get-Secret -Name Password2 -AsPlainText
$creds.username1

#Can set meta data for the SecretStore vault (note, other vaults may not support like Key Vault)
Set-SecretInfo Password1 -Metadata @{Environment = "Dev"}
Get-SecretInfo | Select-Object name, metadata


#Azure Key Vault
#Must be authenticated already with context set
$KVParams = @{ AZKVaultName = "SavillVaultRBAC"; SubscriptionId = $AzSubID}
Register-SecretVault -Module Az.KeyVault -Name KeyVaultStore -VaultParameters $KVParams

Get-SecretInfo -Vault KeyVaultStore
Get-Secret -Name Secret1 -AsPlainText #-vault if have same name over vaults


#Credential Manager (Windows Only) for current user
Install-Module -Name SecretManagement.JustinGrote.CredMan -Scope AllUsers -Force
Register-SecretVault -Module SecretManagement.JustinGrote.CredMan -Name CredManStore
Set-Secret -Name CredTest1 -Secret "WontShare" -Vault CredManStore #shows under credential manager as ps:<name>
Get-Secret -Name CredTest1 -AsPlainText

#See across all
Get-SecretInfo