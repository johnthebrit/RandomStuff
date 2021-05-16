#Docs are great! https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-exceptions?view=powershell-7.1

#Region Regular Error
#Lets make an error
Get-Content -Path r:\doesnotexist\nothere.txt
Throw("Johns Error") #Can always just throw my own!
#Look at the last error
Get-Error
#Also default error variable that errors added to
$Error
#Endregion

#Region Custom variable
#Can error to my own variable
Get-Content -Path r:\doesnotexist\nothere.txt -ErrorVariable BadThings #Note if did +BadThings would add content to existing
$BadThings
#Could do a check
if($BadThings)
{
    Write-Host -ForegroundColor Blue -BackgroundColor White "Had an issue, $($BadThings.Exception.Message)"
}
#Endregion

#Region Using Try-Catch
#Handle the error with try-catch
try {
    Get-Content -Path r:\doesnotexist\nothere.txt
}
catch {
    Write-Output "Something went wrong"
}

#Didn't work, why?
#Endregion

#Region Try-Catch terminating
#We have to set an error action for the try-catch to work since the get-content by default is not a terminating error
#Try-catch only catches terminating errors, e.g
try {
    asdf-asdfasd #garbage and is terminating
}
catch {
    write-output "No idea what that was"
}
#Endregion

#Region Make terminating with ErrorAction
#Make our normal non-terminating error a terminating with the error action
try {
    Get-Content -Path r:\doesnotexist\nothere.txt -ErrorAction Stop
}
catch {
    Write-Output "Something went wrong"
}
#Endregion

#Region Types of error action
#Note there are other types of ErrorAction
Get-Content -Path r:\doesnotexist\nothere42.txt -ErrorAction SilentlyContinue
Get-Error #still errored, we just didn't see it!
#Endregion

#Region Looking at details
#Can look at the error details
try {
    Get-Content -Path r:\doesnotexist\nothere.txt -ErrorAction Stop
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Output "Something went wrong - $ErrorMessage"
    write-host -ForegroundColor Blue -BackgroundColor White $_.Exception #Entire exception
    #Information about where exception was thrown
    $PSItem.InvocationInfo | Format-List * #can also use $PSItem instead of $_
}
#Endregion

#Region Types of catch
#Catch can be used with specific types of exception but needs to be terminating type
try {
    asdf-asdfasd #garbage and is terminating
}
catch [System.Management.Automation.CommandNotFoundException] {
    write-output "no idea what this command is"
}
catch {
    $_.Exception
}
#Endregion

#Region Using ErrorActionPreference
#There is a default error action that is overriden by the -ErrorAction
$ErrorActionPreference

#This can be useful when we cannot set ErrorAction, e.g. a non-PowerShell call
try {
    $CurrentErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop"
    Get-Content -Path r:\doesnotexist\nothere.txt #any command here, e.g. cmd /c
}
catch {
    Write-Output "Something went wrong"
    write-host -ForegroundColor Blue -BackgroundColor White $_.Exception.Message
}
Finally {
    $ErrorActionPreference = $CurrentErrorActionPreference
}

#Note we used finally to put the value back to what it was before we changed it
#Finally always runs if catch is called or not
#Endregion

#Region Errors from cmd.exe
#For cmd execution it writes to its own error stream we can capture
$executionoutput = Invoke-Expression "cmd.exe /c dir r:\nofolder\nofile.file"
$executionoutput #Nope

#Need STDERR (2) to go to STDOUT (1)
$executionoutput = Invoke-Expression "cmd.exe /c dir r:\nofolder\nofile.file 2>&1"
$executionoutput
#Endregion
