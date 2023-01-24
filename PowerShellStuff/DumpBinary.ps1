$string = "https://onboardtoazure.com"
$binary = [system.Text.Encoding]::Default.GetBytes($String) | %{[System.Convert]::ToString($_,2).PadLeft(8,'0') }
$longBinaryString = $binary -join " "