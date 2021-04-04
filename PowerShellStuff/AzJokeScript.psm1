function TurnItOffAndOnAgain-AzLocation
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Location,
        [Parameter(Mandatory=$false)]
        [Switch] $PowerCycle
    )
    $locations = Get-AzLocation
    $locationfull = $locations | Where-Object{$_.Location -eq $Location} | ForEach-Object{$_.DisplayName}
    if($null -eq $locationfull)
    {
        write-output "Error, location $Location not found. Use Get-AzLocation for valid locations"
    }
    else
    {
        if($PSCmdlet.ShouldProcess($Location))
        {
            Write-Output "Will restart all services in $locationfull"
            if($PowerCycle)
            {
                Write-Host "Power cycle selected. Running ML and AI check." -ForegroundColor Magenta
                Start-Sleep -Seconds 1
                Write-Host "3 datacenter technicians will stub toes and 1 will bang their elbow and go `"owwwwwww`"" -ForegroundColor Yellow
                Write-Host "1 security guard will drop a donut" -ForegroundColor Yellow
                Write-Host "Bob will only get half a cup of coffee" -ForegroundColor Yellow
                Write-Host "and..."
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            Write-Output "This will ruin $(Get-Random -Minimum 800000 -Maximum 1000000) peoples day"
            Write-Host -NoNewline "`nPlease type region name to confirm action: "
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            Write-Host -NoNewline "$Location" #tab autocomplete :-)
            Start-Sleep -Seconds 1
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            Write-Host "`nRestarting now" -ForegroundColor Red
            Start-Sleep 5
            Write-Host "`nPlease note all affected customers will be notified and your email shared for the ensuing hate mail" -ForegroundColor DarkGreen
            Write-Progress "Regional restart in progress" -PercentComplete 1 -SecondsRemaining 60
            Start-Sleep 30
            Write-Progress "Regional restart in progress" -PercentComplete 1.5 -SecondsRemaining 7200
            Start-Sleep 30
            Write-Progress "Regional restart in progress" -PercentComplete 2 -SecondsRemaining 7170
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
        else
        {
            Write-Host "What if: Will restart all services in $locationfull" -ForegroundColor Cyan
            Write-Host "What if: This would have ruined $(Get-Random -Minimum 800000 -Maximum 1000000) peoples day" -ForegroundColor Cyan
            if($PowerCycle)
            {
                Write-Host "What if: This also would have caused some degree of injury to those in the buildings" -ForegroundColor Cyan
            }
        }


    }

    <#
        .SYNOPSIS
        Restarts an Azure location in a desperate attempt to resolve your terrible code

        .DESCRIPTION
        Restarts all services in a specified region.
        This is the etch-a-sketch restart of Azure

        .PARAMETER Location
        Specifies the location to ruin everyone's day at.

        .PARAMETER PowerCycle
        Specifies to turn off all power then on again to also upset people in the buildings.

        .INPUTS
        Location. This enables you to pipe arrays of locations in for even greater misery.
        Please do not pass in output from Get-AzLocation. Please.

        .OUTPUTS
        System.String. Returns the full scope of the evil doing.

        .EXAMPLE
        PS> TurnIfOffAndOnAgain-AzLocation -Location southcentralus
        You've ruined the day for <number> people.
        Location <location> has been restarted.

        .LINK
        Online version: https://youtube.com/ntfaqguy
    #>
}