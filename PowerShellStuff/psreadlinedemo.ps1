<#References
https://github.com/PowerShell/PSReadLine
For version support
https://devblogs.microsoft.com/powershell/announcing-psreadline-2-1-with-predictive-intellisense/
I'm using 7.2 PowerShell to show the latest Azure prediction
#>

code $profile #to edit profile

#https://raw.githubusercontent.com/PowerShell/PSReadLine/master/PSReadLine/SamplePSReadLineProfile.ps1

Get-Module PSReadLine #2.1 comes with 7.1+
Find-Module PSReadLine -AllVersions -AllowPrerelease
Install-Module PSReadLine -RequiredVersion 2.1.0 #need to be elevated for install/update
Update-Module PSReadLine -AllowPrerelease

#Commands
Get-PSReadLineKeyHandler
#right arrow to accept moving to end of line
#up and down arrow to move through history
#f8 and shift-f8 scroll down through history based on current characters
#end to move end of line
#ctrl + right arrow to move to next word and ctrl + left to move to previous word

Get-PSReadLineOption

#To enable
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionSource History
#To disable
Set-PSReadLineOption -PredictionSource None


#Style
set-psreadlineoption -PredictionViewStyle ListView
set-psreadlineoption -PredictionViewStyle InlineView
#Can also switch by pressing F2!

#change up and down to now base on what have typed in your history!
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward


#Remember that HistoryAndPlugin?
Find-Module Az.Tools.Predictor -AllowPrerelease

#2.2 has dynamic help
#f1 on a cmdlet to get help then q to quit
#Alt-h on a parameter