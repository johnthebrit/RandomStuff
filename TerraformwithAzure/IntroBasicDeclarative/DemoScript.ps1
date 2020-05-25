New-AzResourceGroup -Location southcentralus -Name 'RG-SCUSARMStorage'
New-AzResourceGroup -Location southcentralus -Name 'RG-SCUSTFStorage'

#Define base
$GitBasePath = 'C:\Users\john\OneDrive\projects\GIT\RandomStuff\TerraformwithAzure'

#Terraform Demo
#Install from https://www.terraform.io/downloads.html and added to user path
#Azure CLI installed and logged in via az login

Set-Location $GitBasePath\IntroBasicDeclarative

terraform init
terraform plan
terraform apply -auto-approve

#Human readable view of the state file
terraform show

#Show specific resource from state file
terraform state list
terraform state show azurerm_storage_account.StorAccount1
terraform state show azurerm_storage_container.Container1

terraform plan -var 'replicationType=GRS'
terraform apply -var 'replicationType=GRS' -auto-approve

#To visually see
terraform graph > base.dot
# could sent directly with graphviz installed https://graphviz.gitlab.io/download/
terraform graph | dot -Tsvg > graph.svg

#To delete the resources
terraform plan -destroy -out='planout'   #Is there a file type to use? .tfplan??
terraform apply 'planout'
