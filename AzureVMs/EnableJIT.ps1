#Connect as native identity
Connect-AzAccount -Identity

<#The identity needs JIT permissions. Can create custom role and assign at subscription level
{
    "properties": {
        "roleName": "RequestJIT",
        "description": "",
        "assignableScopes": [
            "/subscriptions/YOURSUBID"
        ],
        "permissions": [
            {
                "actions": [
                    "Microsoft.Security/locations/jitNetworkAccessPolicies/initiate/action",
                    "Microsoft.Security/locations/jitNetworkAccessPolicies/*/read",
                    "Microsoft.Compute/virtualMachines/read",
                    "Microsoft.Network/networkInterfaces/*/read"
                ],
                "notActions": [],
                "dataActions": [],
                "notDataActions": []
            }
        ]
    }
}
#>

$VMID = 'VMRESOURCEIDHERE'
$CIDRRange = '10.0.12.0/24'

#end time in 20 hours
$EndTime = (Get-Date -asutc).addhours(20) | Get-Date -format o

$JitPolicyVm1 = (@{
    id=$VMID;
    ports=(@{
       number=3389;
       endTimeUtc=$EndTime;
       allowedSourceAddressPrefix=@($CIDRRange)})})

$JitPolicyArr=@($JitPolicyVm1)

$VMInfo = Get-AzResource -Id $VMID

Start-AzJitNetworkAccessPolicy -ResourceGroupName $($VMInfo.ResourceGroupName) -Location $VMInfo.Location -Name "default" -VirtualMachine $JitPolicyArr