Function HasSupportEphemeralOSDisk([object[]] $capability)
{
     return $capability | where { $_.Name -eq "EphemeralOSDiskSupported" -and $_.Value -eq "True"}
}

$location = "southcentralus"

$VMCacheInfo = @()

$VMSKUs = Get-AzComputeResourceSku -Location $location | Where-Object { $_.ResourceType -eq "virtualMachines" -and (HasSupportEphemeralOSDisk $_.Capabilities) -ne $null }

foreach ($SKU in $VMSKUs)
{
    $VMSKU = New-Object PSObject -Property @{
        Name = $SKU.Name
        Family = $SKU.Family -replace "standard", ""
        SupportedEphemeralOSDiskPlacements = (($SKU.capabilities | Where-Object { $_.Name -eq "SupportedEphemeralOSDiskPlacements" }).Value)
        CachedDiskGB = (($SKU.capabilities | Where-Object { $_.Name -eq "CachedDiskBytes" }).Value / 1GB)
        MaxResourceVolumeGB = (($SKU.capabilities | Where-Object { $_.Name -eq "MaxResourceVolumeMB" }).Value / 1KB)
        }
    $VMCacheInfo += $VMSKU
}

$VMCacheInfo | Format-Table Name, SupportedEphemeralOSDiskPlacements, MaxResourceVolumeGB, CachedDiskGB -AutoSize


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