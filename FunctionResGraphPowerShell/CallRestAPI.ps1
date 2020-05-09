#Simple Test Harness to call a rest API
$URIValue = ""
$BodyObject = [PSCustomObject]@{"ComputerName"="savazuusscwin10"}
$BodyJSON = ConvertTo-Json($BodyObject)
$response = Invoke-RestMethod -Uri $URIValue -Method POST -Body $BodyJSON -ContentType 'application/json'
    # or use Invoke-WebRequest (RestMethod automatically parses returned JSON in content but less overall info)
$content = $response.Status
