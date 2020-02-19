#!/bin/bash
cd 4.pub-sub

# Set kube context to use
kubectl config use-context rgc-demo-dapr-k8s

kubectl create ns dapr-pubsub

# Install Redis
helm install redis stable/redis -n=dapr-pubsub
helm list -n=dapr-pubsub

kubectl get pods -n=dapr-pubsub -w

kubectl get secret -n=dapr-pubsub redis -o jsonpath="{.data.redis-password}" | base64 --decode
#kubectl get secret -n=dapr-pubsub redis -o jsonpath="{.data.redis-password}" > deploy/encoded.b64
#certutil -decode deploy/encoded.b64 deploy/password.txt
#rm deploy/encoded.b64
#code -r deploy/password.txt

### STOP HERE ###
# ...and paste the password into the redis.yaml file
#rm deploy/password.txt

kubectl apply -f ./deploy/redis.yaml -n=dapr-pubsub
kubectl apply -f ./deploy/react-form.yaml -n=dapr-pubsub
kubectl apply -f ./deploy/node-subscriber.yaml -n=dapr-pubsub
kubectl apply -f ./deploy/python-subscriber.yaml -n=dapr-pubsub

kubectl get pods -n=dapr-pubsub -w

kubectl get svc -n=dapr-pubsub

export REACT_APP=$(kubectl get svc react-form -n=dapr-pubsub --output 'jsonpath={.status.loadBalancer.ingress[0].ip}')
echo $REACT_APP
cmd.exe /C start "http://$REACT_APP"

### STOP HERE ###

kubectl logs -n=dapr-pubsub -l=app=node-subscriber -c=node-subscriber -f
kubectl logs -n=dapr-pubsub -l=app=python-subscriber -c=python-subscriber -f

### STOP HERE ###
### Now remove everything!

kubectl delete -f ./deploy/react-form.yaml -n=dapr-pubsub
kubectl delete -f ./deploy/node-subscriber.yaml -n=dapr-pubsub
kubectl delete -f ./deploy/python-subscriber.yaml -n=dapr-pubsub
kubectl delete -f ./deploy/redis.yaml -n=dapr-pubsub
helm delete redis -n=dapr-pubsub
