#!/bin/bash
cd 2.hello-kubernetes/

# Set kube context to use
kubectl config use-context rgc-demo-dapr-k8s

# Install Redis
helm install redis stable/redis -n=dapr-hello
helm list -n=dapr-hello

kubectl get pods -n=dapr-hello -w

kubectl get secret -n=dapr-hello redis -o jsonpath="{.data.redis-password}" > deploy/encoded.b64
certutil -decode deploy/encoded.b64 deploy/password.txt
rm deploy/encoded.b64

code -r deploy/password.txt

### STOP HERE ###
# ...and paste the password into the redis.yaml file
rm deploy/password.txt

kubectl apply -f ./deploy/redis.yaml -n=dapr-hello

kubectl apply -f ./deploy/node.yaml -n=dapr-hello
kubectl get pods --selector=app=node -n=dapr-hello -w

kubectl get svc nodeapp -n=dapr-hello -w

export NODE_APP=$(kubectl get svc nodeapp -n=dapr-hello --output 'jsonpath={.status.loadBalancer.ingress[0].ip}')

kubectl apply -f ./deploy/python.yaml -n=dapr-hello
kubectl get pods --selector=app=python -n=dapr-hello -w

kubectl logs --selector=app=node -c node -n=dapr-hello

curl $NODE_APP/order

### STOP HERE ###
### Now remove everything!

cd deploy
kubectl delete -f . -n=dapr-hello
helm delete redis -n=dapr-hello