#Using PowerShellGet
Get-Command -Module PowerShellGet

#View registered repos
Get-PSRepository

(Get-Module Az -ListAvailable).version #what do I have
Get-InstalledModule -Name Az -AllVersions
Find-Module -Name Az #what is available

Get-Module Az* -ListAvailable #note the install location and meta module
#Remove the old
Get-Module Az* -ListAvailable | Uninstall-Module -Force #need to be elevated
#Cleaner uninstall script at https://docs.microsoft.com/en-us/powershell/azure/uninstall-az-ps?view=azps-5.3.0

#Look at path for modules
$env:PSModulePath

#Install for all users
install-Module az -Scope AllUsers -Force
install-Module az.resourcegraph -Scope AllUsers -Force
install-Module aztable -Scope AllUsers -Force
install-Module microsoft.graph -Scope AllUsers -Force
Install-Module PSReadline -AllowPrerelease -Scope AllUsers -Force
install-Module azureadpreview -Scope AllUsers -Force
Install-Module Az.Tools.Predictor -Scope AllUsers -Force

#if wanted to update
Update-Module Az

#From AzureRM to Az
Find-Module -Name Az.Tools.Migration
#https://docs.microsoft.com/en-us/powershell/azure/quickstart-migrate-azurerm-to-az-automatically?view=azps-5.3.0
#or
Enable-AzureRmAlias -whatif

#Sign in
Connect-AzAccount    #will launch a browser and populate the token automatically using browser control
Connect-AzAccount -UseDeviceAuthentication  #will show a token and you can type in on any browser, i.e. device authorization grant code flow
Get-Alias add-azaccount | fl
Get-Alias login-azaccount | fl

Connect-AzAccount -Identity #use managed identity

#for an app can use secret or cert per https://docs.microsoft.com/en-us/powershell/azure/authenticate-azureps?view=azps-5.3.0

Connect-AzAccount -Tenant <name.com> #to get context against a different tenant than default for the security principal being used, i.e. a guest in the tenant

#this is a device based authentication and you can close PowerShell session and will stay signed in forever based on refresh token (90 days typically) as long
#as keep using within that refresh token rolling validity window

#Once authenticated will have a default context based on your tenant and subscription
Get-AzContext
Get-AzContext -ListAvailable
Get-AzSubscription

Select-AzSubscription -Name "SavillTech Dev Subscription"

$contexts= Get-AzContext -ListAvailable
$contexts[0]

$contexts[1] | rename-azcontext -TargetName "SavillTech Dev"
$contexts[2] | rename-azcontext -TargetName "SavillTech Lab"
$contexts[0] | rename-azcontext -TargetName "SavillTech Prod"
get-azcontext -ListAvailable

Select-AzContext "savilltech prod"
Get-Alias Select-AzSubscription | fl

Get-AzContextAutosaveSetting
Enable-AzContextAutosave
Clear-AzContext -WhatIf

#Cloud shell
Get-PSDrive

#Commands
Get-Command -Module Az.Resources | Select-Object -Unique noun | Sort-Object Noun
Get-Command -Module Az.Resources -Noun AzResourceGroup

Get-AzResourceGroup | ft ResourceGroupName, Location -AutoSize

#View VMs
Get-AzVM

#View VM status
Get-AzVM -Status | ft Name, ResourceGroupName, Location, PowerState -AutoSize

#Can use regular PowerShell piplining and features like what-if
Get-AzVM -Status | Where PowerState -ne "VM running" | Start-AzVM -WhatIf

#the various Azure clouds. Get-AzContext shows the environment you are using
Get-AzEnvironment

#View regions
Get-AzLocation

#View VM sizes in a region
Get-AzVMSize -Location southcentralus
#Currently using against allowed core counts
Get-AzVMUsage -Location southcentralus | Sort-Object -Property CurrentValue -Descending
#Check for VM SKUs supported in Availability Zones
Get-AzComputeResourceSku | where Locations -EQ "eastus2"

#Looking at images in marketplace
$loc = 'SouthCentralUS'
#View the templates available
Get-AzVMImagePublisher -Location $loc
Get-AzVMImageOffer -Location $loc -PublisherName "MicrosoftWindowsServer"
Get-AzVMImageSku -Location $loc -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer"
Get-AzVMImage -Location $loc -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter-Core"

#View extensions available
Get-AzVmImagePublisher -Location $loc | `
Get-AzVMExtensionImageType | `
Get-AzVMExtensionImage | Select Type, Version

#Resource Graph
Import-Module Az.ResourceGraph

$ComputerName = "savazuusscwin10"
$GraphSearchQuery = "Resources
    | where type =~ 'Microsoft.Compute/virtualMachines'
    | where properties.osProfile.computerName =~ '$ComputerName'
    | join (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
    | project VMName = name, CompName = properties.osProfile.computerName, RGName = resourceGroup, SubName, SubID = subscriptionId"

try {
    $VMresource = Search-AzGraph -Query $GraphSearchQuery
}
catch {
    Write-Error "Failure running Search-AzGraph, $_"
}

#Deploy templates etc all covered in my IaC Master Class
New-AzResourceGroupDeployment -ResourceGroupName RG-0001 `
    -TemplateFile "StorageAccount.json" `
    -TemplateParameterFile "StorageAccount.parameters.json" `
    -WhatIf

#Azure documentation has PowerShell commands for nearly everything
Get-Command -Module Az.Compute -Noun *VM* -Verb New #to find
Get-Help new-azvm -Examples
Get-Help new-azvm -Online