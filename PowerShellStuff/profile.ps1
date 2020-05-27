function prompt {
    #put this in $profile, e.g. code $profile
    $location = Get-Location
    $pathparts = $location.path.split("\")
    if($pathparts.Count -gt 2)
    {
        "PS $($pathparts[0])\..\$($pathparts[$pathparts.Count-1])> "
    }
    else
    {
        "PS $location> "
    }
  }