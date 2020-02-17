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

kubectl get svc nodeapp -n=dapr-calc -w

export NODE_APP=$(kubectl get svc nodeapp -n=dapr-calc --output 'jsonpath={.status.loadBalancer.ingress[0].ip}')

kubectl apply -f ./deploy/python.yaml -n=dapr-calc
kubectl get pods --selector=app=python -n=dapr-calc -w

kubectl logs --selector=app=node -c node -n=dapr-calc

curl $NODE_APP/order

### STOP HERE ###
### Now remove everything!

cd deploy
kubectl delete -f . -n=dapr-calc
helm delete redis -n=dapr-calc