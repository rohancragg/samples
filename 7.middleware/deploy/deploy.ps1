$setupFolder = "./utils/base-templates"
$deployFolder = "./deploy"
$appName = 'middleware-echoapp'
$tag = "edge"

az login
az account set -s $sub

# Prompts
$resourceBase = 'rgcdemodapr' #Read-Host -Prompt "Enter resource name base"
$location = 'westeurope' #Read-Host -Prompt "Enter location"

$groupName= $("rg-$resourceBase")
$clusterName= "$resourceBase" + "-cluster"
$registryName="${resourceBase}reg"
$storageName = "${resourceBase}sa"


kubectl create namespace ingress
helm install my-release stable/nginx-ingress --namespace ingress

docker build -t "$registryName.azurecr.io/$appName`:$tag" echoapp/
docker push "$registryName.azurecr.io/$appName`:$tag"  
  
(Get-Content $setupFolder/echoapp.yaml) `
| Foreach-Object {$_ -replace "IMAGE_NAME", "$registryName.azurecr.io/$appName`:$tag"}  `
| Set-Content $deployFolder/echoapp.yaml

kubectl create namespace dapr-middleware

kubectl apply -f deploy/oauth2.yaml -n=dapr-middleware
kubectl apply -f deploy/pipeline.yaml -n=dapr-middleware
kubectl apply -f deploy/echoapp.yaml -n=dapr-middleware
kubectl apply -f deploy/ingress.yaml -n=dapr-middleware

kubectl get po -n=dapr-middleware

$INGRESS_IP=$(kubectl get svc my-release-nginx-ingress-controller -n=ingress --output 'jsonpath={.status.loadBalancer.ingress[0].ip}')

# scoop install sudo
$filePath='c:\windows\system32\drivers\etc\hosts'
sudo Add-Content $filePath $("$INGRESS_IP dummy.com")

start "http://dummy.com/v1.0/invoke/echoapp/method/echo?text=hello"

## Clean up

kubectl delete -f deploy/oauth2.yaml -n=dapr-middleware
kubectl delete -f deploy/pipeline.yaml -n=dapr-middleware
kubectl delete -f deploy/echoapp.yaml -n=dapr-middleware
kubectl delete -f deploy/ingress.yaml -n=dapr-middleware

helm delete my-release --namespace ingress

kubectl delete namespace dapr-middleware
kubectl delete namespace ingress