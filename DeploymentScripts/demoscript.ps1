bicep -v

#RG-SCUSA is the RG of the MI am referencing
New-AzResourceGroupDeployment -TemplateFile "deployscript.bicep" -ResourceGroupName RG-BicepDemo

New-AzResourceGroupDeployment -TemplateFile "deployscript.bicep" -ResourceGroupName RG-BicepDemo -storageAccountName "sascussavilltech2"

bicep build "deploymentscript.bicep" #if wanted ARM file :-)