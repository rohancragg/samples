#!/bin/bash
cd 3.distributed-calculator

# Set kube context to use
kubectl config use-context aks-sec-cluster-dev-weu

kubectl create ns dapr-calc

# Install Redis
helm install redis stable/redis -n=dapr-calc
helm list -n=dapr-calc

kubectl get pods -n=dapr-calc -w

kubectl get secret -n=dapr-calc redis -o jsonpath="{.data.redis-password}" > deploy/encoded.b64
certutil -decode deploy/encoded.b64 deploy/password.txt
rm deploy/encoded.b64

code -r deploy/password.txt

### STOP HERE ###
# ...and paste the password into the redis.yaml file
rm deploy/password.txt

kubectl apply -f ./deploy/redis.yaml -n=dapr-calc

kubectl apply -f ./deploy/dotnet-subtractor.yaml -n=dapr-calc
kubectl apply -f ./deploy/go-adder.yaml -n=dapr-calc
kubectl apply -f ./deploy/node-divider.yaml -n=dapr-calc
kubectl apply -f ./deploy/python-multiplier.yaml -n=dapr-calc
kubectl apply -f ./deploy/react-calculator.yaml -n=dapr-calc

kubectl get pods -n=dapr-calc -w

kubectl get svc -n=dapr-calc -w

export REACT_APP=$(kubectl get svc calculator-front-end -n=dapr-calc --output 'jsonpath={.status.loadBalancer.ingress[0].ip}')

start "http://$REACT_APP"

kubectl logs --selector=app=calculator-front-end -c calculator-front-end -n=dapr-calc

### STOP HERE ###

kubectl logs --selector=app=divide -c divide -n=dapr-calc
kubectl logs --selector=app=add -c add -n=dapr-calc
kubectl logs --selector=app=subtract -c subtract -n=dapr-calc
kubectl logs --selector=app=multiply -c multiply -n=dapr-calc


### STOP HERE ###
### Now remove everything!

cd deploy
kubectl delete -f . -n=dapr-calc
helm delete redis -n=dapr-calc
cd ..