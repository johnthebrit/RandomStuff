Get-AzVmssVM -ResourceGroupName "RG-Spot" -VMScaleSetName "spotvmss"
Set-AzVmssVM -ResourceGroupName "RG-Spot" -VMScaleSetName "spotvmss" -InstanceId 0 -SimulateEviction

#inside the VM could look
#curl -H Metadata:true http://169.254.169.254/metadata/scheduledevents?api-version=2019-08-01