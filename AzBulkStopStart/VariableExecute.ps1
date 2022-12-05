function executeActionCommand
{
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [string]$commandBlockString,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$name
        )
    $commandBlock = [Scriptblock]::Create($commandBlockString) #Need to make it a script block
    $status = & $commandBlock
    write-output $name
    write-output $status
}

$commandBlock = { write-output "hello" }

& $commandBlock

$nameOfMe = "Ollie"
$commandString = "write-output `"hello $nameOfMe`""
$commandBlock = [Scriptblock]::Create($commandString) #Need to make it a script block
$status = & $commandBlock

executeActionCommand $commandString 'John'

executeActionCommand 'write-output "hello world"' 'John'
