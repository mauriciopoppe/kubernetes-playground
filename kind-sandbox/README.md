# Sandbox kind cluster

## Creating the cluster

```
kind create cluster --config=./config.yaml

# Using a dev build using the k8s source in $GOPATH/k8s.io/kubernetes
kind build node-image
kind create cluster --config=./config.yaml --image=kindest/node:latest
```

## Deleting the cluster

```
kind delete cluster
```
