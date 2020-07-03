az aks get-credentials --resource-group RG-AKS --name aks-ussc-sav
az aks isntall-cli

kubectl cluster-info
kubectl get nodes

kubectl apply -f azure-vote.yaml

kubectl get pods -o wide
kubectl get service

#note the endpoints for the frontend points to the IP of the frontend pod IP
kubectl get endpoints azure-vote-front1
