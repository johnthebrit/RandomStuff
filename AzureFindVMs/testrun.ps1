$URIValue = "https://savtechosexecute.azurewebsites.net/api/VMList?code==="
$BodyObject = [PSCustomObject]@{"ostype"="Linux"}
$BodyJSON = ConvertTo-Json($BodyObject)
$response = Invoke-WebRequest -Uri $URIValue -Method POST -Body $BodyJSON -ContentType 'application/json'
$response.content