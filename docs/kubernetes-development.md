# Kubernetes development

## Compiling binaries in debug mode

**Main doc: [contributors/devel/development.md](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#building-kubernetes)**

Run `make WHAT=cmd/<target>`, the binaries are at `_output/bin/<target>`, for example to build the kube-controller-manager:

```bash
# DBG=1 sets the gcflags 'all=-N -l'
make WHAT=cmd/kube-controller-manager DBG=1
```

I use [delve](https://github.com/go-delve/delve) to run the binaries in debug mode

```bash
# download delve
go install github.com/go-delve/delve/cmd/dlv@v1.9.1
```

**Headless debugging**

The idea is to connect to run delve in server mode (with it running a binary and connecting to the server)
and to connect to the server through an editor.

See `/docs/sandbox-with-debugger.yaml` for more info about my neovim setup.

```bash
# run the program in server headless mode through delve
dlv --listen :38697 --continue --accept-multiclient --api-version=2 --headless \
  exec ./_output/bin/kube-controller-manager -- \
  --kubeconfig=${HOME}/.kube/config --leader-elect=false --controllers="*"

# Use your editor's dap integration to attach your editor to the running program
```

## Using kind

Read:

- https://kind.sigs.k8s.io/docs/user/quick-start/#building-images
- https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#building-kubernetes-with-docker

Steps:

- Clone the kubernetes codebase to `$GOPATH/src/k8s.io/kubernetes`
- Read the steps in https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#building-kubernetes-on-a-local-osshell-environment, install dependencies if needed
- Run `kind build node-image`
- Create a configuration file like the one in `/kind-sandbox` e.g.

```
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        enable-admission-plugins: NodeRestriction,MutatingAdmissionWebhook,ValidatingAdmissionWebhook
    controllerManager:
      extraArgs:
        v: "5"
- role: worker
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    kubelet:
      extraArgs:
        v: "5"
```

- Start kind with `kind create cluster --config=./config.yaml --image=kindest/node:latest`
