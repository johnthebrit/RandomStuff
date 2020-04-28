$subs=Get-AzSubscription

$commandsToDelete = @()

foreach($sub in $subs)
{
    Select-AzSubscription -Subscription $sub | Out-Null
    Write-Output "`nChecking subscription : $($sub.Name) ($($sub.id))"

    #Check for unconnected managed disks
    $disks = Get-AzDisk
    foreach($disk in $disks)
    {
        if($disk.ManagedBy -eq $null)
        {
            Write-Output "  Disk $($disk.name) not connected to VM"
            $commandsToDelete += "Remove-AzDisk -ResourceGroupName '$($disk.ResourceGroupName)' -DiskName '$($disk.name)'"
        }
    }
    $pubIPs = Get-AzPublicIpAddress
    $NATGWs = Get-AzNatGateway
    foreach($pubIP in $pubIPs)
    {
        if($pubIP.IpConfiguration -eq $null)
        {
            Write-Output "  Public IP $($pubIP.name) not connected to VM/LB, but could be used by different resource such as NAT Gateway"
            $foundWithResource = $false
            foreach($NATGW in $NATGWs)
            {
                foreach($GWPubIP in $NATGW.PublicIpAddresses)
                {
                    if($GWPubIP.Id -eq $PubIP.id)
                    {
                        Write-Output "    IP $($pubIP.name) used by NAT Gateway $($NATGW.Name)"
                        $foundWithResource = $true
                    }
                }
            }
            if(!$foundWithResource)
            {
                $commandsToDelete += "Remove-AzPublicIPAddress -ResourceGroupName '$($pubIP.ResourceGroupName)' -Name '$($pubIP.name)'"

            }
        }
    }
}

Write-Output "`n`nAnaysis Complete. To remove identified resources execute the commands below:`n"
Write-Output $commandsToDelete