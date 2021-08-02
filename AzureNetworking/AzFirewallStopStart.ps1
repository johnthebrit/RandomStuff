# Stop an existing firewall

$azfw = Get-AzFirewall -Name "FW-SCUS" -ResourceGroupName "RG-Infra-SCUS"
$azfw.Deallocate()
Set-AzFirewall -AzureFirewall $azfw

Stop-AzVM -Name "savazuuswcweb01" -ResourceGroupName RG-Infra-WCUS

# Start a firewall

$azfw = Get-AzFirewall -Name "FW-SCUS" -ResourceGroupName "RG-Infra-SCUS"
$vnet = Get-AzVirtualNetwork -ResourceGroupName "RG-Infra-SCUS" -Name "VNet-Infra-SCUS"
$publicip1 = Get-AzPublicIpAddress -Name "PubIP-SCUS-FW" -ResourceGroupName "RG-Infra-SCUS"
$azfw.Allocate($vnet,@($publicip1))

Set-AzFirewall -AzureFirewall $azfw

Start-AzVM -Name "savazuuswcweb01" -ResourceGroupName RG-Infra-WCUS