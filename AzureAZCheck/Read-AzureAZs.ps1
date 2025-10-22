function Read-AzureAZs {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "One or more regions (e.g., eastus, westus2, or 'East US')")]
        [string[]]$Region,
        [switch]$Raw
    )

    # Ensure logged in to Azure
    if (-not (Get-AzContext -ErrorAction SilentlyContinue)) {
        Connect-AzAccount -ErrorAction Stop | Out-Null
    }

    # Normalize input: allow arrays or comma/semicolon-separated strings; keep spaces in display names
    $regionKeys = $Region `
        | ForEach-Object { $_ -split '[,;]+' } `
        | Where-Object { $_ -and $_.Trim() -ne '' } `
        | ForEach-Object { $_.Trim().ToLowerInvariant() } `
        | Select-Object -Unique

    $subscriptions = Get-AzSubscription -ErrorAction Stop -WarningAction SilentlyContinue

    $results = foreach ($sub in $subscriptions) {
        try {
            # Set context for this subscription
            Set-AzContext -SubscriptionId $sub.Id -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null

            # Query locations for this subscription
            $response = Invoke-AzRestMethod -Method GET -Path "/subscriptions/$($sub.Id)/locations?api-version=2022-12-01" -ErrorAction Stop
            $locations = ($response.Content | ConvertFrom-Json).value

            # Match any requested region by name or display name (case-insensitive)
            $matched = $locations | Where-Object {
                $n = $_.name.ToLowerInvariant()
                $d = $_.displayName.ToLowerInvariant()
                ($regionKeys -contains $n) -or ($regionKeys -contains $d)
            }

            foreach ($loc in $matched) {
                if ($null -ne $loc.availabilityZoneMappings) {
                    $azMappings = $loc.availabilityZoneMappings

                    # Find physical zones by suffix (case-insensitive)
                    $az1Physical = ($azMappings | Where-Object { $_.physicalZone -match 'AZ1$' } | Select-Object -ExpandProperty logicalZone -First 1)
                    $az2Physical = ($azMappings | Where-Object { $_.physicalZone -match 'AZ2$' } | Select-Object -ExpandProperty logicalZone -First 1)
                    $az3Physical = ($azMappings | Where-Object { $_.physicalZone -match 'AZ3$' } | Select-Object -ExpandProperty logicalZone -First 1)

                    [PSCustomObject]@{
                        SubscriptionName         = $sub.Name
                        SubscriptionId           = $sub.Id
                        RegionName               = $loc.name
                        RegionDisplayName        = $loc.displayName
                        AZ1_Physical             = $az1Physical
                        AZ2_Physical             = $az2Physical
                        AZ3_Physical             = $az3Physical
                    }
                }
            }
        }
        catch {
            Write-Warning "Failed in subscription $($sub.Name) ($($sub.Id)): $($_.Exception.Message)"
        }
    }

    if ($results) {
        if ($Raw) {
            return $results
        } else {
            $results |
            Sort-Object RegionName, SubscriptionName |
            Format-Table SubscriptionName, SubscriptionId, RegionName, AZ1_Physical, AZ2_Physical, AZ3_Physical -AutoSize
        }
    } else {
        Write-Host "No availabilityZoneMappings found for region '$Region' across accessible subscriptions."
    }

}