New-AzResourceGroup -Location southcentralus -Name 'RG-SCUSPSStorage'
New-AzResourceGroup -Location southcentralus -Name 'RG-SCUSARMStorage'
New-AzResourceGroup -Location southcentralus -Name 'RG-SCUSTFStorage'

#Define base
$GitBasePath = 'C:\Users\john\OneDrive\projects\GIT\RandomStuff\DeclarativevsImperative'

#ARM Template Demo

#Show the whatif functionality
New-AzResourceGroupDeployment -WhatIf `
    -ResourceGroupName RG-SCUSARMStorage `
    -TemplateFile "$GitBasePath\ARM\CreateStorage.json" `
    -TemplateParameterFile "$GitBasePath\ARM\CreateStorage.parameters.json"

#Deploy simple template creating a storage account
New-AzResourceGroupDeployment -ResourceGroupName RG-SCUSARMStorage `
    -TemplateFile "$GitBasePath\ARM\CreateStorage.json" `
    -TemplateParameterFile "$GitBasePath\ARM\CreateStorage.parameters.json"

#Run same template again but override the type of the storage account
New-AzResourceGroupDeployment -WhatIf -ResourceGroupName RG-SCUSARMStorage `
    -TemplateFile "$GitBasePath\ARM\CreateStorage.json" `
    -TemplateParameterFile "$GitBasePath\ARM\CreateStorage.parameters.json" `
    -StorageAccountType 'Standard_GRS'

#Run same template again but override the name of account
New-AzResourceGroupDeployment -ResourceGroupName RG-SCUSARMStorage `
    -TemplateFile "$GitBasePath\ARM\CreateStorage.json" `
    -TemplateParameterFile "$GitBasePath\ARM\CreateStorage.parameters.json" `
    -storageAccountName 'savtecharmstoragev22020'
#Note since I didn't override the account type its back to LRS again!
#Old account still there since it's not definied in the template so ignored

New-AzResourceGroupDeployment -ResourceGroupName RG-SCUSARMStorage `
    -TemplateFile "$GitBasePath\ARM\CreateStorage.json" `
    -TemplateParameterFile "$GitBasePath\ARM\CreateStorage.parameters.json" `
    -storageAccountName 'savtecharmstoragev22020' `
    -mode complete
#now its gone since complete and RG must match the template


#Terraform Demo
#Install from https://www.terraform.io/downloads.html and added to user path
#Azure CLI installed and logged in via az login

Set-Location $GitBasePath\Terraform

terraform init
terraform plan
terraform apply -auto-approve

terraform plan -var 'replicationType=GRS'
terraform apply -var 'replicationType=GRS' -auto-approve

#To visually see
terraform graph > base.dot
# could sent directly with graphviz installed https://graphviz.gitlab.io/download/
terraform graph | dot -Tsvg > graph.svg