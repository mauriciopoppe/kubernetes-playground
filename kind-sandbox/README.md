# Sandbox kind cluster

NOTE: it's important to have the latest version of kind

## Creating the cluster

Using an existing release https://github.com/kubernetes-sigs/kind/releases

```bash
kind create cluster --config=./config.yaml --image=kindest/node:v1.27.3
```

If there are changes to HEAD, build an image from a kubernetes version first and then create
the cluster based on that image.

```bash
# Using a dev build using the k8s source in $GOPATH/k8s.io/kubernetes
kind build node-image --image kindest/node:main $GOPATH/src/k8s.io/kubernetes
kind create cluster --config=./kind-sandbox/config.yaml --image=kindest/node:main
```

## Deleting the cluster

```bash
kind delete cluster
```
