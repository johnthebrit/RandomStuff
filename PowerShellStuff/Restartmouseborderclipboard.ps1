Write-Host "Killing PowerToys.MouseWithoutBordersHelper processes..."
Stop-Process -Name "PowerToys.MouseWithoutBordersHelper*" -Force
Write-Host "Starting PowerToys.MouseWithoutBordersHelper.exe..."
Start-Process -FilePath "$env:USERPROFILE\AppData\Local\PowerToys\PowerToys.MouseWithoutBordersHelper.exe"