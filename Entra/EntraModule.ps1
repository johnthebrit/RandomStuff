#The graph module
install-module microsoft.graph -Scope CurrentUser -Force

#Is it friendly?
get-module -ListAvailable | Where-Object { $_.Name -like 'Microsoft.Graph.*' }
get-command -module microsoft.graph.Users | Select-Object -Unique Noun | Sort-Object Noun

#Install the module Entra PowerShell module
Install-Module Microsoft.Graph.Entra -AllowPrerelease -Repository PSGallery -Force
Update-Module -Name Microsoft.Graph.Entra -AllowPrerelease #You want to keep up-to-date
Get-Module microsoft.graph.entra

#If wanted the Beta version
Install-Module Microsoft.Graph.Entra.Beta -AllowPrerelease -Repository PSGallery -Force

#Connect to your tenant
Connect-MgGraph -TenantId $env:TENANT_ID -Scopes 'User.Read.All'
#There is a helper if you want for Entra
Connect-Entra -TenantId $env:TENANT_ID -Scopes 'User.Read.All'

#Check current consented scopes
(Get-MgContext).Scopes

#View the objects supported by the Entra module
get-command -module microsoft.graph.entra | Select-Object -Unique Noun | Sort-Object Noun

Get-EntraUser -SearchString "John" | format-table DisplayName, Mail

#To see more detail, the REST call etc
Get-EntraUser -SearchString "John" -Debug


#No pipelining :-(
Get-MgGroup -Filter "DisplayName eq 'JL'" | Get-MgGroupMember

#Yay!
Get-EntraGroup -Filter "DisplayName eq 'JL'" | Get-EntraGroupMember | Format-Table DisplayName, city


#Alias
Enable-EntraAzureADAlias
Get-Alias -Name *AzureAD*
Get-Alias -Definition Get-EntraUser

Get-AzureADUser -SearchString "John" | format-table DisplayName, Mail