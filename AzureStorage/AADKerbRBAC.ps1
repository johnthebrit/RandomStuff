#Steps must be performed EXACTLY IN THIS ORDER!

$resourceGroupName = "RG-EastUS2"
$storageAccountName = "sasaveus2kerb1"

#Azure AD auth
$Subscription =  $(Get-AzContext).Subscription.Id;
$ApiVersion = '2021-04-01'

$Uri = ('https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Storage/storageAccounts/{2}?api-version={3}' -f $Subscription, $ResourceGroupName, $StorageAccountName, $ApiVersion);

$json =
   @{properties=@{azureFilesIdentityBasedAuthentication=@{directoryServiceOptions="AADKERB"}}};
$json = $json | ConvertTo-Json -Depth 99

$token = $(Get-AzAccessToken).Token
$headers = @{ Authorization="Bearer $token" }

try {
    Invoke-RestMethod -Uri $Uri -ContentType 'application/json' -Method PATCH -Headers $Headers -Body $json;
} catch {
    Write-Host $_.Exception.ToString()
    Write-Error -Message "Caught exception setting Storage Account directoryServiceOptions=AADKERB: $_" -ErrorAction Stop
}

#Generate key
New-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName -KeyName kerb1 -ErrorAction Stop

#Get the key
$kerbKey1 = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName -ListKerbKey | Where-Object { $_.KeyName -like "kerb1" }
$aadPasswordBuffer = [System.Linq.Enumerable]::Take([System.Convert]::FromBase64String($kerbKey1.Value), 32);
$password = "kk:" + [System.Convert]::ToBase64String($aadPasswordBuffer);

#Connect to AAD RUN THIS ON Windows PowerShell
Import-Module 'C:\Program Files\PowerShell\Modules\AzureAD'
Connect-AzureAD
$azureAdTenantDetail = Get-AzureADTenantDetail;
$azureAdTenantId = $azureAdTenantDetail.ObjectId
$azureAdPrimaryDomain = ($azureAdTenantDetail.VerifiedDomains | Where-Object {$_._Default -eq $true}).Name

$servicePrincipalNames = New-Object string[] 3
$servicePrincipalNames[0] = 'HTTP/{0}.file.core.windows.net' -f $storageAccountName
$servicePrincipalNames[1] = 'CIFS/{0}.file.core.windows.net' -f $storageAccountName
$servicePrincipalNames[2] = 'HOST/{0}.file.core.windows.net' -f $storageAccountName

$application = New-AzureADApplication -DisplayName $storageAccountName -IdentifierUris $servicePrincipalNames -GroupMembershipClaims "All";

$servicePrincipal = New-AzureADServicePrincipal -AccountEnabled $true -AppId $application.AppId -ServicePrincipalType "Application";

$Token = ([Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::AccessTokens['AccessToken']).AccessToken
$apiVersion = '1.6'
$Uri = ('https://graph.windows.net/{0}/{1}/{2}?api-version={3}' -f $azureAdPrimaryDomain, 'servicePrincipals', $servicePrincipal.ObjectId, $apiVersion)
$json = @'
{
  "passwordCredentials": [
  {
    "customKeyIdentifier": null,
    "endDate": "<STORAGEACCOUNTENDDATE>",
    "value": "<STORAGEACCOUNTPASSWORD>",
    "startDate": "<STORAGEACCOUNTSTARTDATE>"
  }]
}
'@
$now = [DateTime]::UtcNow
$json = $json -replace "<STORAGEACCOUNTSTARTDATE>", $now.AddDays(-1).ToString("s")
  $json = $json -replace "<STORAGEACCOUNTENDDATE>", $now.AddMonths(12).ToString("s")
$json = $json -replace "<STORAGEACCOUNTPASSWORD>", $password
$Headers = @{'authorization' = "Bearer $($Token)"}
try {
  Invoke-RestMethod -Uri $Uri -ContentType 'application/json' -Method Patch -Headers $Headers -Body $json
  Write-Host "Success: Password is set for $storageAccountName"
} catch {
  Write-Host $_.Exception.ToString()
  Write-Host "StatusCode: " $_.Exception.Response.StatusCode.value
  Write-Host "StatusDescription: " $_.Exception.Response.StatusDescription
}


#SET THE API PERMISSIONS
# Storage Account App - + Add a permissions - MIcrosoft Graph - Delegated permissions - openid and profiles under OpenID then User.Read under the User permission group. Add permissions at bottom of page THEN Grant admin constent and click Yes
#If you DON'T DO THIS WHEN YOU TRY AND CONNECT YOU GET A BAD PASSWORD ERROR from client

#CREATE a share called Data
#On storage account ensure user has the Storage File Data SMB Share Elevated Contributor role
#User (or group) MUST be sync'd from AD and not native cloud


#This needs to have line of sight to DC and AD and Azure AD joined
#Needs ActiveDirectory RSAT installed
import-module ActiveDirectory

function Set-StorageAccountAadKerberosADProperties {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true, Position=0)]
      [string]$ResourceGroupName,

      [Parameter(Mandatory=$true, Position=1)]
      [string]$StorageAccountName,

      [Parameter(Mandatory=$false, Position=2)]
      [string]$Domain
  )

  $AzContext = Get-AzContext;
  if ($null -eq $AzContext) {
      Write-Error "No Azure context found.  Please run Connect-AzAccount and then retry." -ErrorAction Stop;
  }

  $AdModule = Get-Module ActiveDirectory;
   if ($null -eq $AdModule) {
      Write-Error "Please install and/or import the ActiveDirectory PowerShell module." -ErrorAction Stop;
  }

  if ([System.String]::IsNullOrEmpty($Domain)) {
      $domainInformation = Get-ADDomain
      $Domain = $domainInformation.DnsRoot
  } else {
      $domainInformation = Get-ADDomain -Server $Domain
  }

  $domainGuid = $domainInformation.ObjectGUID.ToString()
  $domainName = $domainInformation.DnsRoot
  $domainSid = $domainInformation.DomainSID.Value
  $forestName = $domainInformation.Forest
  $netBiosDomainName = $domainInformation.DnsRoot
  $azureStorageSid = $domainSid + "-123454321";

  Write-Verbose "Setting AD properties on $StorageAccountName in $ResourceGroupName : `
      EnableActiveDirectoryDomainServicesForFile=$true, ActiveDirectoryDomainName=$domainName, `
      ActiveDirectoryNetBiosDomainName=$netBiosDomainName, ActiveDirectoryForestName=$($domainInformation.Forest) `
      ActiveDirectoryDomainGuid=$domainGuid, ActiveDirectoryDomainSid=$domainSid, `
      ActiveDirectoryAzureStorageSid=$azureStorageSid"

  $Subscription =  $AzContext.Subscription.Id;
  $ApiVersion = '2021-04-01'

  $Uri = ('https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Storage/storageAccounts/{2}?api-version={3}' `
      -f $Subscription, $ResourceGroupName, $StorageAccountName, $ApiVersion);

  $json=
      @{
          properties=
              @{azureFilesIdentityBasedAuthentication=
                  @{directoryServiceOptions="AADKERB";
                      activeDirectoryProperties=@{domainName="$($domainName)";
                                                  netBiosDomainName="$($netBiosDomainName)";
                                                  forestName="$($forestName)";
                                                  domainGuid="$($domainGuid)";
                                                  domainSid="$($domainSid)";
                                                  azureStorageSid="$($azureStorageSid)"}
                                                  }
                  }
      };

  $json = $json | ConvertTo-Json -Depth 99

  $token = $(Get-AzAccessToken).Token
  $headers = @{ Authorization="Bearer $token" }

  try {
      Invoke-RestMethod -Uri $Uri -ContentType 'application/json' -Method PATCH -Headers $Headers -Body $json
  } catch {
      Write-Host $_.Exception.ToString()
      Write-Host "Error setting Storage Account AD properties.  StatusCode:" $_.Exception.Response.StatusCode.value__
      Write-Host "Error setting Storage Account AD properties.  StatusDescription:" $_.Exception.Response.StatusDescription
      Write-Error -Message "Caught exception setting Storage Account AD properties: $_" -ErrorAction Stop
  }
}

Set-StorageAccountAadKerberosADProperties -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName

#Check the values on the storage account
$Subscription =  $(Get-AzContext).Subscription.Id;
$ApiVersion = '2021-04-01'
$token = $(Get-AzAccessToken).Token
$headers = @{ Authorization="Bearer $token" }
$Uri = ('https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Storage/storageAccounts/{2}?api-version={3}' -f $Subscription, $ResourceGroupName, $StorageAccountName, $ApiVersion);
$result = Invoke-RestMethod -Uri $Uri -ContentType 'application/json' -Method Get -Headers $Headers
$result.properties.azureFilesIdentityBasedAuthentication.activeDirectoryProperties

#Trouble shoot
dsregcmd /status
dsregcmd /RefreshPrt
#remote all tickets
klist purge
#get a kerberos TGT
klist get krbtgt


#To just demo
klist purge
net use * \\sasaveus2kerb1.file.core.windows.net\data
klist