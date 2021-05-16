function Get-RandomMessageSad
{
    $number=Get-Random -Maximum 10

    switch ($number)
    {
        {$_ -lt 4} { write-output "Howdy Y'all"}
        {$_ -ge 4 -and $_ -lt 7} { write-output "Good morning to thee"}
        Default { write-output "Top of the morning"}
    }
}

function Get-RandomMessage
{
    #Need cmdlet binding for the standard verbose, debug etc options
    [CmdletBinding()]
    Param([parameter(ValueFromRemainingArguments=$true)][String[]] $args)

    Write-Verbose "Generating a random number"
    $number=Get-Random -Maximum 10
    Write-Verbose "Number is $number"

    Write-Debug "Start of switch statement"
    switch ($number)
    {
        {$_ -lt 4} { write-output "Howdy Y'all"; Write-Debug "Less than 4" }
        {$_ -ge 4 -and $_ -lt 7} { write-output "Good morning to thee"; Write-Debug "4-6"}
        Default { write-output "Top of the morning"; Write-Debug "Default"}
    }
}