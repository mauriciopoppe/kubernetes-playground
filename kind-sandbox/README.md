# Sandbox kind cluster

It's very important to have the latest version of kind if you want to keep
with the kubernetes releases.

```sh
# check the latest version at https://kind.sigs.k8s.io/docs/user/quick-start/#installing-with-go-install
go install sigs.k8s.io/kind@v0.22.0
```

## Creating the cluster

Using an existing release https://github.com/kubernetes-sigs/kind/releases

```bash
kind create cluster --config=./kind-sandbox/config-worker-dlv.yaml --image=kindest/node:v1.27.3
```

If there are changes to HEAD, build an image from a kubernetes version first and then create
the cluster based on that image.

```bash
# Using a dev build using the k8s source in $GOPATH/k8s.io/kubernetes
kind build node-image --image kindest/node:main $GOPATH/src/k8s.io/kubernetes
kind create cluster --config=./kind-sandbox/config-worker-dlv.yaml --image=kindest/node:main
```

## Deleting the cluster

```bash
kind delete cluster
```
