Install-Module -Name Az.ConnectedMachine -Scope allusers -Force

Get-AzConnectedMachine

Get-AzConnectedMachine -ResourceGroupName RG-Arc -Name winsrv2022

get-help New-AzConnectedMachineRunCommand -Examples

New-AzConnectedMachineRunCommand -ResourceGroupName RG-Arc -SourceScript 'Write-Host "Hostname: $env:COMPUTERNAME, Username: $env:USERNAME"' `
    -RunCommandName "runGetInfo10" -MachineName winsrv2022 -Location WestUS2

get-AzConnectedMachineRunCommand -MachineName winsrv2022 -ResourceGroupName RG-Arc -RunCommandName "runGetInfo10"

New-AzConnectedMachineRunCommand -ResourceGroupName RG-Arc -SourceScript 'Write-Host "Hostname: $env:COMPUTERNAME, Username: $env:USERNAME"' `
    -RunCommandName "runGetInfo11" -MachineName winsrv2022 -Location WestUS2 `
    -AsyncExecution

#Can use -ScriptURI etc
