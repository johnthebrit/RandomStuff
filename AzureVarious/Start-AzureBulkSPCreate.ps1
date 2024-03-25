<#
Bulk Service Principal and role assignment
v0.3
John Savill

Need Azure and Microsoft Graph PowerShell modules

*** Need to auth for PowerShell Azure module (Connect-AzAccount) and Microsoft Graph (Connect-MgGraph -TenantID)

Permissions required:
    Entra:
        Application.ReadWrite.All - Create the service principal and set the owner
        User.Read.All

    Management group:
        Microsoft.Authorization/roleAssignments/write (to grant an identity a role)
            Could use Role Based Access Control Administrator

Change Notes:

.02 3/5/2024 - Checks if SP already exists and also creates the SPs in one phase, then does the rest of actions as next phase
.03 3/5/2024 - Tweaks to error checking
#>

[CmdletBinding(SupportsShouldProcess)]
Param (
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$false)]
    [String]
    $InputCSV
)

Import-Module Microsoft.Graph.Applications

#Get a token
$accessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token #MS Graph audience
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $accessToken
}

$statusGood = $true

#Silence warnings about changing cmdlets
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true" > $null

#read in configuration for the custom role GUID
try {
    $configurationSettingsFile = Get-Content -Path '.\bulkAzureSPCreate.json' -ErrorAction Stop
    $configurationSettings = $configurationSettingsFile | convertfrom-json -AsHashTable
}
catch {
    Write-Error "Error reading configuration file: `n $_ "
    $statusGood = $false
}

#read in resources
try {
    $subscriptionList = Import-Csv -Path $InputCSV
}
catch {
    Write-Error "Error reading resource file: `n $_ "
    $statusGood = $false
    $subscriptionList = $null
}

if($statusGood)
{
    #Check have the required columns in resource file
    if((Get-Member -inputobject $subscriptionList[0] -name "principleDisplayName" -membertype Properties) -and
    (Get-Member -inputobject $subscriptionList[0] -name "principleEmail" -membertype Properties) -and
    (Get-Member -inputobject $subscriptionList[0] -name "subscriptionId" -membertype Properties) -and
    (Get-Member -inputobject $subscriptionList[0] -name "principalId" -membertype Properties) -and
    (Get-Member -inputobject $subscriptionList[0] -name "subscriptionName" -membertype Properties) -and
    (Get-Member -inputobject $subscriptionList[0] -name "env" -membertype Properties) -and
    (Get-Member -inputobject $subscriptionList[0] -name "principle_name" -membertype Properties))
    {
        write-output "Input subscription file format check good"
    }
    else
    {
        write-error "Input subscription file format failed"
        $statusGood = $false
    }
}

if($statusGood)
{

    Write-Output "*** Creating service principals."
    # Loop through each row in the CSV
    foreach ($subscriptionEntry in $subscriptionList)
    {
        $sp = $null

        # Create the service principal
        try {
            $sp = Get-AzADServicePrincipal -DisplayName $subscriptionEntry.principle_name
            if($null -eq $sp)
            {
                $sp = New-AzADServicePrincipal -DisplayName $subscriptionEntry.principle_name
            }
            else
            {
                Write-Output "The service principal $($subscriptionEntry.principle_name) already exists"
            }
        }
        catch {
            Write-Error "Error creating service principal $($subscriptionEntry.principle_name) : `n $_ "
        }
    } #for each entry in list

    Write-Output "*** Creating service principals complete."

    Write-Output "*** Sleeping for Entra convergence."
    #Just to ensure Entra converged fully
    Start-Sleep -Seconds 30

    Write-Output "*** Assigning service principal permissions and roles."
    foreach ($subscriptionEntry in $subscriptionList)
    {
        $sp = $null
        $user = $null
        $statusGood = $true #need to reset for each pass

        # Get the SP
        try {
            $sp = Get-AzADServicePrincipal -DisplayName $subscriptionEntry.principle_name
            if($null -eq $sp)
            {
                Write-Error "Could not find service principal $($subscriptionEntry.principle_name)"
                $statusGood = $false
            }
        }
        catch {
            Write-Error "Could not find service principal $($subscriptionEntry.principle_name) : `n $_ "
            $statusGood = $false
        }

        # Get the user
        try {
            $user = Get-AzADUser -UserPrincipalName $subscriptionEntry.principleEmail
            #or $user = Get-AzADUser -ObjectId $subscriptionEntry.principalId
            if($null -eq $user)
            {
                Write-Error "Could not get user $($subscriptionEntry.principleEmail)"
                $statusGood = $false
            }
        }
        catch {
            Write-Error "Could not get user $($subscriptionEntry.principleEmail) : `n $_ "
            $statusGood = $false
        }

        # Assign the user as the owner of the service principal
        if($statusGood)
        {
            try {
                $params = @{
                    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)"
                }

                #Set on the Enterprise App
                New-MgServicePrincipalOwnerByRef -ServicePrincipalId $sp.Id -BodyParameter $params
                #Set on the App Registration
                $AppRegObjID = Get-MgApplicationByAppId -AppId $sp.appid
                New-MgApplicationOwnerByRef -ApplicationId $AppRegObjID.Id -BodyParameter $params
            }
            catch {
                Write-Error "Unable to set owner $($subscriptionEntry.principleEmail) for $($subscriptionEntry.principle_name): `n $_ "
                $statusGood = $false
            }
        }

        #Grant the service principal the custom role on the corresponding subscription
        if($statusGood)
        {
            try {
                New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionId $configurationSettings.roleID -Scope "/subscriptions/$($subscriptionEntry.subscriptionId)"
            }
            catch {
                Write-Error "Unable to grant $($subscriptionEntry.principle_name) custom role on target sub: `n $_ "
                $statusGood = $false
            }
        }
    } #for each entry in list
    Write-Output "*** Assigning service principal permissions and roles complete."
} #if status good
