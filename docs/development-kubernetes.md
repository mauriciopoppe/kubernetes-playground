# Kubernetes development

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
