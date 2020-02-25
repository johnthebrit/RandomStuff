
###################################
#  AzureAD                        #
###################################
Install-Module azuread -Repository PSGallery
Get-Command -Module AzureAD
Connect-AzureAD
Get-AzureADUser

###################################
#  AzureAD.Standard.Preview       #
###################################
#Native to cloud shell
azuread.standard.preview\get-azureaduser


###################################
#  Az                             #
###################################
Get-Command -Module Az.Resources -Noun azad*
Get-AzADUser
Get-Help New-AzADUser -Examples
Get-Command -Noun AzADUser
Get-Command -Module Az.Resources -Noun azad* | Select-Object -Unique Noun | Sort-Object Noun

###################################
#  Microsoft.Graph                #
###################################
Find-Module Microsoft.Graph
Import-Module Microsoft.Graph
Get-Module Microsoft.Graph.* | Select-Object Name, Version, ExportedCommands

#You have to specify which permissions you want
Connect-Graph -Scopes "User.Read","User.ReadWrite.All","Mail.ReadWrite",`
    "Directory.ReadWrite.All","Chat.ReadWrite", "People.Read", `
    "Group.Read.All", "Directory.AccessAsUser.All", "Tasks.ReadWrite", `
    "Sites.Manage.All"

Get-MGUser
Get-MgUserMessage -UserId john@savilltech.net -Filter "contains(subject,'PIM digest')" | select sentDateTime, subject
