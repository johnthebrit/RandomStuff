function ping {

    param (
        $target
    )

    $ipaddr = '20.187.79.245'

    if($QuantumEnabled)
    {
        $times=1,2,1,1
    }
    else
    {
        $times=185,182,187,183
    }

    Write-Output "`nPinging $($target) [$($ipaddr)] with 32 bytes of data:"
    Start-Sleep -Milliseconds 100
    $count=0
    foreach ($time in $times)
    {
        Write-Output "Reply from $($ipaddr): bytes=32 time=$($time)ms TTL=128"
        $count++
        if($count -lt ($times.count))
        {
            Start-Sleep -Seconds 1
        }
    }
    Start-Sleep -Milliseconds 100
    Write-Output "`nPing statistics for $($ipaddr):`n    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),`nApproximate round trip times in milli-seconds:`n    Minimum = $([int]($times | measure -Minimum).Minimum)ms, Maximum = $([int]($times | measure -Maximum).Maximum)ms, Average = $([int]($times | measure -Average).Average)ms"
}

function enable-quantumleap {
    Set-Variable -Name "QuantumEnabled" -Value $true -Scope global
    write-output "Establishing Quantum connection"
    Start-Sleep -Seconds 5
    write-output "Connection established"
}

function disable-quantumleap {
    Set-Variable -Name "QuantumEnabled" -Value $false -Scope global
}