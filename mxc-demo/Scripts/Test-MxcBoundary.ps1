#Requires -Version 7.0
#Requires -PSEdition Core
# Run the SAME script normally and through MXC. The policy, not this script,
# decides whether each operation is permitted. Only dummy demo data is changed.
[CmdletBinding()]
param(
    [ValidateSet('All', 'ReadFile', 'WriteFile', 'Processes', 'Web')]
    [string]$Probe = 'All',
    [string]$DataFile,
    [uri]$Website = 'https://savill.ai/'
)

$ErrorActionPreference = 'Stop'
if (-not $DataFile) {
    $DataFile = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, '..\Data\demo.txt'))
}

function Invoke-Probe {
    param([string]$Name, [scriptblock]$Action)
    Write-Host "`n--- $Name ---"
    try {
        & $Action
        Write-Host 'SUCCEEDED' -ForegroundColor Green
    }
    catch {
        # A failure alone is NOT proof of a policy denial. Show the real error.
        Write-Host 'FAILED' -ForegroundColor Yellow
        Write-Host $_.Exception.Message
        Write-Host ("Error ID: " + $_.FullyQualifiedErrorId)
    }
}

Write-Host "PowerShell $($PSVersionTable.PSVersion); PID $PID"
Write-Host "Probe: $Probe"

if ($Probe -in @('All', 'ReadFile')) {
    Invoke-Probe 'Read the local dummy file' {
        Get-Content -LiteralPath $DataFile -ErrorAction Stop | Write-Host
    }
}

if ($Probe -in @('All', 'WriteFile')) {
    Invoke-Probe 'Append a line to the SAME dummy file' {
        Add-Content -LiteralPath $DataFile -Value 'Demo write succeeded.' -ErrorAction Stop
        Write-Host 'Appended one line.'
    }
}

if ($Probe -in @('All', 'Processes')) {
    Invoke-Probe 'Observe which processes are visible' {
        $visible = @(Get-Process -ErrorAction Stop)
        Write-Host "Visible process count: $($visible.Count)"
        $visible | Sort-Object Id | Select-Object -First 8 Id, ProcessName |
            Format-Table -AutoSize | Out-String | Write-Host
        Write-Host 'Observation only: MXC has no documented process-list permission toggle.'
        Write-Host 'Seeing a PID/name does not imply access to its memory or ability to control it.'
    }
}

if ($Probe -in @('All', 'Web')) {
    Invoke-Probe 'Download an HTTPS page into memory' {
        if ($Website.Scheme -ne 'https') { throw 'Use an HTTPS URL for this demo.' }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        # Keep disk-write permissions separate from network permissions.
        # Do not follow redirects or execute any downloaded content.
        $page = Invoke-WebRequest -Uri $Website -UseBasicParsing -TimeoutSec 10 `
            -MaximumRedirection 0 -ErrorAction Stop
        Write-Host "HTTP $($page.StatusCode); received $($page.RawContentLength) bytes."
    }
}

Write-Host "`nFinished. Compare errors with a normal host run and the selected policy."
# Deliberately attempt every probe. This exit code is not an enforcement verdict.
