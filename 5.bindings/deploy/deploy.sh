#!/bin/bash
cd 5.bindings

# Set kube context to use
kubectl config use-context rgc-demo-dapr-k8s

kubectl create ns dapr-bindings
kubectl create ns kafka

# Install Kafka
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm repo update
helm install dapr-kafka incubator/kafka --namespace kafka --set replicas=1

# Wait until kafka pods are running
kubectl -n kafka get pods -w

# Create sample topic
# Deploy kafka test client
kubectl -n kafka apply -f ./k8s_kafka_testclient.yaml
# Create sample topic
kubectl -n kafka exec testclient -- kafka-topics --zookeeper dapr-kafka-zookeeper:2181 --topic sample --create --partitions 1 --replication-factor 1


# Install Redis
helm install redis stable/redis -n=dapr-bindings
helm list -n=dapr-bindings

kubectl get pods -n=dapr-bindings -w

kubectl get secret -n=dapr-bindings redis -o jsonpath="{.data.redis-password}" | base64 --decode
#kubectl get secret -n=dapr-bindings redis -o jsonpath="{.data.redis-password}" > deploy/encoded.b64
#certutil -decode deploy/encoded.b64 deploy/password.txt
#rm deploy/encoded.b64
#code -r deploy/password.txt

### STOP HERE ###
# ...and paste the password into the redis.yaml file
#rm deploy/password.txt

kubectl apply -f ./deploy/node.yaml -n=dapr-bindings
kubectl apply -f ./deploy/python.yaml -n=dapr-bindings
kubectl apply -f ./deploy/kafka_bindings.yaml -n=dapr-bindings

kubectl get pods -n=dapr-bindings -w

kubectl get svc -n=dapr-bindings

# Observe the Node app logs
kubectl logs -n=dapr-bindings -l=app=bindingsnodeapp -c=node -f

# Observe the Python app logs
kubectl logs -n=dapr-bindings -l=app=bindingspythonapp -c=python -f


### STOP HERE ###
### Now remove everything!

kubectl delete -f ./deploy/node.yaml -n=dapr-bindings
kubectl delete -f ./deploy/python.yaml -n=dapr-bindings
kubectl delete -f ./deploy/kafka_bindings.yaml -n=dapr-bindings

kubectl -n kafka delete -f ./k8s_kafka_testclient.yaml

helm delete dapr-kafka -n=kafka

kubectl delete ns dapr-bindings
kubectl delete ns kafka