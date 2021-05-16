#Lets make an error
Get-Content -Path r:\doesnotexist\nothere.txt

#Look at the last error
Get-Error
#Also default error variable
$Error

#Can error to my own variable
Get-Content -Path r:\doesnotexist\nothere.txt -ErrorVariable BadThings #Note if did +BadThings would add content to existing
$BadThings
#Could do a check
if($BadThings)
{
    Write-Host -ForegroundColor Blue -BackgroundColor White "Had an issue, $($BadThings.Exception.Message)"
}

#Handle the error with try-catch
try {
    Get-Content -Path r:\doesnotexist\nothere.txt
}
catch {
    Write-Output "Something went wrong"
}

#Didn't work, why?

#We have to set an error action for the try-catch to work since the get-content by default is not a terminating error
#Try-catch only catches terminating errors, e.g
try {
    asdf-asdfasd #garbage and is terminating
}
catch {
    write-output "No idea what that was"
}

#Make our normal non-terminating error a terminating with the error action
try {
    Get-Content -Path r:\doesnotexist\nothere.txt -ErrorAction Stop
}
catch {
    Write-Output "Something went wrong"
}

#Note there are other types of ErrorAction
Get-Content -Path r:\doesnotexist\nothere42.txt -ErrorAction SilentlyContinue
Get-Error #still errored, we just didn't see it!

#Can look at the error details
try {
    Get-Content -Path r:\doesnotexist\nothere.txt -ErrorAction Stop
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Output "Something went wrong - $ErrorMessage"
    write-host -ForegroundColor Blue -BackgroundColor White $_.Exception #Entire exception
}

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

#Note we used finally to put the valut back to what it was before we changed it
#Finally always runs if catch is called or not
