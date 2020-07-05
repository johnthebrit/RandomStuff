az aks get-credentials --resource-group RG-AKS --name aks-ussc-sav
az aks get-credentials --resource-group RG-AKS-Kubenet --name aks-ussc-savkubenet
#View service principal for cluster
az aks show --resource-group RG-AKS --name aks-ussc-sav --query servicePrincipalProfile.clientId
az ad sp show --id (az aks show --resource-group RG-AKS --name aks-ussc-sav --query servicePrincipalProfile.clientId)

#Install kubectl then have to update path to include it
az aks install-cli

#Open a browser to the kubernetes for a cluster
az aks browse --resource-group RG-AKS --name aks-ussc-sav

kubectl cluster-info
kubectl get nodes

kubectl apply -f azure-vote.yaml

kubectl get pods -o wide
kubectl get pods --show-labels
kubectl get service
kubectl describe svc azure-vote-front1
#note the endpoints for the frontend points to the IP of the frontend pod IP
kubectl get endpoints azure-vote-front1


#General other
kubectl get service --all-namespaces
#delete deployment
kubectl delete  -f azure-vote.yaml