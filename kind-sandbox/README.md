# Sandbox kind cluster

## Creating the cluster

```bash
kind create cluster --config=./config.yaml
```

Or by buidling an image from a kubernetes version.

```bash
# Using a dev build using the k8s source in $GOPATH/k8s.io/kubernetes
kind build node-image --image kindest/node:main $GOPATH/src/k8s.io/kubernetes
kind create cluster --config=./config.yaml --image=kindest/node:main
```

## Deleting the cluster

```bash
kind delete cluster
```
