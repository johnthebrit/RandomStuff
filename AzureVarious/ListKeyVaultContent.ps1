#There are limits on metadata operations
#To avoid risk to normal operations this will sleep for 10 seconds every 300
function IncrementAndSleep {
    param (
        [ref]$NumberAttributesViewed,
        [ref]$counter
    )

    # Increment the counters
    $NumberAttributesViewed.Value++
    $counter.Value++

    # Check if the counter reaches 300
    if ($counter.Value -eq 300) {
        Write-Host "Counter reached 300. Sleeping for 10 seconds..."
        Start-Sleep -Seconds 10
        Write-Host "Sleep complete."
        $counter.Value = 0  # Reset the counter
    }
}

#SET THESE VALUES
#This date is when the current version must have been created after
$OldestDate = Get-Date -Year 2024 -Month 3 -Day 13

#This number of days is the longest the expiry can be set to from today
$OldestExpiryDays = 60
$OldestExpiryDate = (Get-Date).AddDays($OldestExpiryDays)

#Get current user ID
$userUpn = (get-azcontext).Account.Id
$userID = (Get-AzADUser -UserPrincipalName $userUpn).Id

# Authenticate to Azure with an account that has Key Vault Reader permission on all vaults
# Also to set the list permission on legacy vaults need Microsoft.KeyVault/vaults/write permission
#Connect-AzAccount

$NumberAttributesViewed = [ref]0
$counter = [ref]0

#Enumerate every subscription have access
$subscriptions = Get-AzSubscription
#or if want from a list
#$subscriptions = Get-Content -Path sublist.txt #this file should have one subscription ID per line

foreach ($subscription in $subscriptions)
{
    $subName = $subscription.Name
    $subID = $subscription.Id

    Write-Host "Subscription Name: $subName ($subID)"
    Set-AzContext -Subscription $subID  > $null #change to the subscription of the object quietly

    # Get all Key Vaults in the subscription
    $keyVaults = Get-AzKeyVault

    foreach ($keyVault in $keyVaults)
    {
        $keyVaultName = $keyVault.VaultName
        Write-Host "  Key Vault Name: $keyVaultName"

        $keyvaultdetail = Get-AzKeyVault -VaultName $keyVault.VaultName

        #need to check if its a legacy vault
        if($keyvaultdetail.EnableRbacAuthorization -eq $false)
        {
            #Need to grant list permission to an access policy
            Set-AzKeyVaultAccessPolicy -VaultName $keyVault.VaultName -ObjectId $userID `
                -PermissionsToSecrets list -PermissionsToKeys list -PermissionsToCertificates list
        }

        # Get certificates
        $certificates = Get-AzKeyVaultCertificate -VaultName $keyVault.VaultName
        foreach ($cert in $certificates)
        {
            IncrementAndSleep -counter $counter -NumberAttributesViewed $NumberAttributesViewed

            Write-Output "$subID,$subName,$keyVaultName,"cert",$($cert.Name),$($cert.Created),$($cert.Expires)"
            <#
            if($cert.Created -le $OldestDate -or $cert.Expires -ge $OldestExpiryDate)
            {
                Write-Host "    Certificate Name: $($cert.Name)"
                if($cert.Created -le $OldestDate)
                {
                    Write-Host "      Created: $($cert.Created) ** CURRENT VERSION CREATED BEFORE REQUIRED DATE"
                }
                else
                {
                    Write-Host "      Created: $($cert.Created)"
                }
                if($cert.Expires -ge $OldestExpiryDate)
                {
                    Write-Host "      Expires: $($cert.Expires) ** EXPIRY TOO LONG **"
                }
                else
                {
                    Write-Host "      Expires: $($cert.Expires)"
                }
            }#>
        }

        # Get keys
        $keys = Get-AzKeyVaultKey -VaultName $keyVault.VaultName
        foreach ($key in $keys)
        {
            IncrementAndSleep -counter $counter -NumberAttributesViewed $NumberAttributesViewed

            Write-Output "$subID,$subName,$keyVaultName,"key",$($key.Name),$($key.Created),$($key.Expires)"
            <#if($key.Created -le $OldestDate)
            {
                Write-Host "    Key Name: $($key.Name)"
                Write-Host "      Created: $($key.Created) ** CURRENT VERSION CREATED BEFORE REQUIRED DATE"
                if($key.expires -eq $null)
                {
                    write-output "      Expires: ** NOT SET **"
                }
                elseif ($key.Expires -ge $OldestExpiryDate)
                {
                    Write-Host "      Expires: $($key.Expires) ** EXPIRY TOO LONG **"
                }
                else
                {
                    Write-Host "      Expires: $($key.Expires)"
                }
            }#>
        }

        # Get secrets
        $secrets = Get-AzKeyVaultSecret -VaultName $keyVault.VaultName
        foreach ($secret in $secrets)
        {
            IncrementAndSleep -counter $counter -NumberAttributesViewed $NumberAttributesViewed

            Write-Output "$subID,$subName,$keyVaultName,"secret",$($secret.Name),$($secret.Created),$($secret.Expires)"
            <#if($secret.Created -le $OldestDate)
            {
                Write-Host "    Secret Name: $($secret.Name)"
                Write-Host "      Created: $($secret.Created) ** CURRENT VERSION CREATED BEFORE REQUIRED DATE"
                if($secret.expires -eq $null)
                {
                    write-output "      Expires: ** NOT SET **"
                }
                elseif ($secret.Expires -ge $OldestExpiryDate)
                {
                    Write-Host "      Expires: $($secret.Expires) ** EXPIRY TOO LONG **"
                }
                else
                {
                    Write-Host "      Expires: $($secret.Expires)"
                }
            }#>
        }
    }
}
