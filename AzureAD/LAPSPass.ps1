#you need to have installed the Microsoft.graph module
Install-Module microsoft.graph -Scope AllUsers

#Authenticate with the two permissions required
Connect-MgGraph -Scope "Device.Read.All","DeviceLocalCredential.Read.All"

#OR you could create an app with the permissions then connect with that clientID of the app
#https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-scenarios-azure-active-directory
#Show LAPSRetrieve sample app
$TenantID = (Get-MgContext).TenantId #assumed already done a basic Connect-McGraph
$LAPSAppID = "1bfbfb4b-9388-4514-92a1-4d34b5effd22" #change this to yours!
Connect-MgGraph -TenantID $TenantID -ClientID $LAPSAppID

#Get the device ID for the machine whose passwords you wish to fetch
$devName = "savworkvm"
Get-LapsAADPassword -DeviceIds $devName -IncludePasswords -AsPlainText -IncludeHistory

#What about Get request directly
$devDetails = Get-MgDevice -Search "displayName:$devName" -ConsistencyLevel eventual
$response = invoke-MgGraphRequest -Method Get https://graph.microsoft.com/beta/deviceLocalCredentials/$($devDetails.DeviceId)?`$select=credentials
$response.credentials[0]
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($response.credentials[0].passwordBase64))