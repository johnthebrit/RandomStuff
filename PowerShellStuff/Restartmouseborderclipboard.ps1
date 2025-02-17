Write-Host "Killing PowerToys.MouseWithoutBordersHelper processes..."
Stop-Process -Name "PowerToys.MouseWithoutBordersHelper*" -Force
Write-Host "Starting PowerToys.MouseWithoutBordersHelper.exe..."
Start-Process -FilePath "$env:USERPROFILE\AppData\Local\PowerToys\PowerToys.MouseWithoutBordersHelper.exe"
https://www.linkedin.com/pulse/14th-february-2025-update-john-savill-zlyhc