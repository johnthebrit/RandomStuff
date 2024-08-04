New-AzResourceGroup -Name entraBicepRG -Location eastus

New-AzResourceGroupDeployment -ResourceGroupName entraBicepRG `
    -TemplateFile ./entrademo.bicep