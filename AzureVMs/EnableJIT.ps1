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

# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "Running the JIT enable: $currentUTCtime"

$VMIDs = @('ID1','ID2')
$CIDRRange = '10.0.12.0/24' #Azure Firewall
$CIDRRange2 = '10.0.4.0/24' #Azure Bastion

#end time in 20 hours
$EndTime = (Get-Date).addhours(20) | Get-Date -format o

foreach($VMID in $VMIDs)
{

    $JitPolicyVm = (@{
        id=$VMID;
        ports=(@{
            number=3389;
            endTimeUtc=$EndTime;
            allowedSourceAddressPrefix=@($CIDRRange,$CIDRRange2)})})

    $JitPolicyArr=@($JitPolicyVm)

    $VMInfo = Get-AzResource -Id $VMID

    Start-AzJitNetworkAccessPolicy -ResourceGroupName $($VMInfo.ResourceGroupName) -Location $VMInfo.Location -Name "default" -VirtualMachine $JitPolicyArr
}
