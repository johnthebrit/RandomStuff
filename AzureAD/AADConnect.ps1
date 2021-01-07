#Link from AAD to AD
$immutID = "value"
[system.convert]::FromBase64String($immutID) | %{$a += [System.String]::Format("{0:X}", $_) + " "};$result = $null;$result = $a.trimend();$result

Import-Module ADSync

#viewing sync
Get-ADSyncScheduler
Set-ADSyncScheduler -CustomizedSyncCycleInterval 00:30:00

#forcing sync
Start-ADSyncSyncCycle -PolicyType Delta


#Seamess Sign-On
cd "$Env:ProgramFiles\Microsoft Azure Active Directory Connect"
Import-Module .\AzureADSSO.psd1
New-AzureADSSOAuthenticationContext
Get-AzureADSSOStatus | ConvertFrom-Json

#Update credential used (every 30 days)
$creds = Get-Credential #domain admin in domain\user format
Update-AzureADSSOForest -OnPremCredentials $creds




#Change to v2 endpoint  https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-sync-endpoint-api-v2
Set-ADSyncScheduler -SyncCycleEnabled $false
Import-Module 'C:\Program Files\Microsoft Azure AD Sync\Extensions\AADConnector.psm1'
Set-ADSyncAADConnectorExportApiVersion 2
Set-ADSyncAADConnectorImportApiVersion 2
Set-ADSyncScheduler -SyncCycleEnabled $true
