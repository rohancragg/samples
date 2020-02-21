# based on https://github.com/dapr/docs/blob/master/getting-started/cluster/setup-aks.md
sub='044b1a5d-735a-4fac-91a2-677d3e1ad96b'
resourceBase='rgcdaprdemo' #Read-Host -Prompt "Enter resource name base"
rg=rg-$resourceBase
cl=$resourceBase-cluster
region='westeurope'

USERNAME=rohanc

echo "
************************************************************************************************************
AKS cluster '$cl' will be created in resource group '$rg'
************************************************************************************************************"

az login
az account set -s $sub
az group create --name $rg --location $region --tags Owner="Rohan Cragg" Environment="Demo"
az aks create --resource-group $rg --name $cl --node-count 2 --kubernetes-version 1.15.7 --enable-addons http_application_routing --enable-rbac --generate-ssh-keys
az aks get-credentials -n $cl -g $rg

curl -fsSL -o ~/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 ~/get_helm.sh
~/get_helm.sh
rm ~/get_helm.sh

helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client

# Copy Kubernetes Config from Windows to WSL
# https://devkimchi.com/2018/06/05/running-kubernetes-on-wsl/
mkdir ~/.kube && cp /mnt/c/Users/$USERNAME/.kube/config ~/.kube

kubectl cluster-info

# install Dapr using Helm
#https://github.com/dapr/docs/blob/master/getting-started/environment-setup.md#using-helm-advanced

helm repo add dapr https://daprio.azurecr.io/helm/v1/repo
helm repo update
kubectl create namespace dapr-system
helm install dapr dapr/dapr --namespace dapr-system

kubectl get pods -n dapr-system -w

kubectl create clusterrolebinding kubernetes-dashboard -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard


####
# cleanup
#az group delete --name $rg
