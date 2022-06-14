$VMNames = "'DemoVM','DemoVMSrv'"

foreach($VMName in $VMNames)
{
    Get-AzVM -Name $VMName | Start-AzVM -NoWait
}