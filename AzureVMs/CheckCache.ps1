$location = "southcentralus"

$VMCacheInfo = @()

$VMSKUs = Get-AzComputeResourceSku -Location $location | Where-Object { $_.ResourceType -eq "virtualMachines" } | Where-Object { $null -eq $_.Restrictions.ReasonCode }

foreach ($SKU in $VMSKUs)
{
    if (($Sku.Capabilities | Where-Object { $_.Name -eq "EphemeralOSDiskSupported" }).Value -eq $true -and ($Sku.Capabilities | Where-Object { $_.Name -eq "PremiumIO" }).Value -eq $true -and $null -ne ($Sku.Capabilities | Where-Object { $_.Name -eq "CachedDiskBytes" }).Value)
    {
        $VMSKU = New-Object PSObject -Property @{
            Name = $Sku.Name
            Family = $Sku.Family -replace "standard", ""
            CachedDiskBytes = (($Sku.Capabilities | Where-Object { $_.Name -eq "CachedDiskBytes" }).Value / 1GB)
            EphemeralOsDiskSupported = [bool]($Sku.Capabilities | Where-Object { $_.Name -eq "EphemeralOSDiskSupported" }).Value
            }
        $VMCacheInfo += $VMSKU
    }
}


$vmSizes=Get-AzComputeResourceSku | where{$_.ResourceType -eq 'virtualMachines' -and $_.Locations.Contains($location)}

foreach($vmSize in $vmSizes)
{
   foreach($capability in $vmSize.capabilities)
   {
       if($capability.Name -eq 'EphemeralOSDiskSupported' -and $capability.Value -eq 'true')
       {
           $vmSize
       }
   }
}