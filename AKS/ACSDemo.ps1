#Have the AZ CLI and kubectl installed
winget install -e --id Microsoft.AzureCLI
winget install -e --id Kubernetes.kubectl

#Done the login and subscription set
az login
az account set --subscription "xyz"

#Note if using bash remove the $ when defining variables and line continuation would be \ instead of `

#View the cluster
#$clusterName="acstorcluster"
$clusterName="diskcluster"
$resourceGroup="acstordemo"
#$location="eastus"

az aks get-credentials --resource-group $resourceGroup --name $clusterName
kubectl get nodes
kubectl describe node aks-nodepool1-10499529-vmss000000
#Note the label. For ACS to use and be available
az aks nodepool update --resource-group $resourceGroup --cluster-name $clusterName `
    --name nodepool1 --labels acstor.azure.com/io-engine=acstor

#View the pods
kubectl get pods -A

#just the acstor namespace
kubectl get pods -n acstor

#show storage classes
kubectl get sc

#show me the storage pools I have (in the acstor namespace)
kubectl get sp -n acstor

kubectl describe sp azuredisk -n acstor
#in the elastic SAN cluster
#kubectl describe sp elasticsan -n acstor

#I have a persistent volume that is being used by the ACS pods as part of a storage pool!
kubectl get pv

code acstor-pvc.yaml
kubectl apply -f acstor-pvc.yaml

#Show the PVC
kubectl get pvc
kubectl describe pvc
kubectl get pv #no extra PV yet as the PVC is waiting

code acstor-pod.yaml
kubectl apply -f acstor-pod.yaml

kubectl describe pod fiopod #note the node its on as well which is likely not same node as the disk
kubectl describe pvc azurediskpvc
#looking for waiting for a volume to be created, either by external provisioner "containerstorage.csi.azure.com" or manually created by system administrator
#this shows its using the storage pool abstraction

kubectl get pv #Now we have a new persistent volume

#clean up
kubectl delete pods fiopod
kubectl get pv
kubectl delete pvc azurediskpvc
kubectl get pv