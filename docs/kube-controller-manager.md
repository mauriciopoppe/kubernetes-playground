# Kube Controller Manager

The kube controller manager (kcm) is a component bundled with Kubernetes that runs in the
control plane and embeds the core control loops.

## Summary

The starting point is the [`Run`](https://github.com/kubernetes/kubernetes/blob/master/cmd/kube-controller-manager/app/controllermanager.go#L176)
function which in addition to initializing health endpoints it starts the bundled set of controllers,
the first controller that initializes is the `ServiceAccountTokenController` which must be
initialized before the others, the comment for the struct `serviceAccountTokenControllerStarter` summarizes it well

```
// serviceAccountTokenControllerStarter is special because it must run first to set up permissions for other controllers.
// It cannot use the "normal" client builder, so it tracks its own. It must also avoid being included in the "normal"
// init map so that it can always run first.
```

Before all the controllers including the `ServiceAccountTokenController` start there's the creation of a [`ControllerContext`](https://github.com/kubernetes/kubernetes/blob/132f29769dfecfc808adc58f756be43171054094/cmd/kube-controller-manager/app/controllermanager.go#L498:6)
object which is a shared context object for all the controllers, we need a single object because there are some
objects that shouldn't be initialized many times (e.g. a sharedInformer with its versioned client,
metadata sharedInformer with its versioned client).

With the `ControllerContext` initialized, we can start the controller initialization, as mentioned, first the
serviceAccountTokenControllerStarter is initialized and then other controllers located at
[cmd/kube-controller-manager/app/controllermanager.go](https://github.com/kubernetes/kubernetes/blob/master/cmd/kube-controller-manager/app/controllermanager.go#L416).

## Development

In the kubernetes codebase, compile the kube-controller-manager binary:

```bash
make WHAT=cmd/kube-controller-manager DBG=1
```

Print all the flags available with `./_output/bin/kube-controller-manager --help`.

Assuming that you have a working k8s cluster (e.g. the kind cluster setup in
`kind-sandbox/`) you'll see that the kube-controller-manager is already running
as a static Pod. To disable it login into the Node and move the file from the
location where the kubelet watches for manifests to run.

```bash
docker exec -it kind-control-plane /bin/bash

# verify that the kube-controller-manager pod is running
crictl ps

# move the static Pod so that it's no longer watched
cd /etc/kubernetes
mkdir manifests-tmp
mv manifests/kube-controller-manager.yaml manifests-tmp

# verify that the kube-controller-manager pod is no longer running
crictl ps
```

To run the binary locally connected to a running kube-apiserver:

```bash
./_output/bin/kube-controller-manager --kubeconfig=${HOME}/.kube/config
```

To run a subset of the controllers use the flag `--controllers` e.g.
`--controllers persistentvolume-binder` (search for `func NewControllerInitializers(loopMode ControllerLoopMode)` in the file cmd/kube-controller-manager/app/controllermanager.go

To run the binary in debug mode:

```bash
# debugging the PV controller, resync never happens
dlv --listen :38697 --accept-multiclient --api-version=2 --headless \
  exec ./_output/bin/kube-controller-manager -- \
  --kubeconfig=${HOME}/.kube/config --leader-elect=false --v=4 --controllers="persistentvolume-binder,pvc-protection,pv-protection" --pvclaimbinder-sync-period=10000h
```

Next connect to this instance through your editor, my [nvim-dap lua config](https://github.com/mauriciopoppe/dotfiles/blob/main/neovim/config/plugins/nvim-dap.vim)
to connect to it:

```lua
  {
    type = "go",
    name = "Attach kube-controller-manager (remote)",
    debugAdapter = "dlv-dap",
    request = "attach",
    mode = "remote",
    host = "127.0.0.1",
    port = "38697",
    stopOnEntry = false,
    substitutePath = {
      {
          from = "${workspaceFolder}",
          to = "/Users/mauriciopoppe/go/src/k8s.io/kubernetes/_output/local/go/src/k8s.io/kubernetes",
      },
    },
  },
```

To undo the kube-controller-manager setup and run the static Pod again:

```bash
docker exec -it kind-control-plane /bin/bash

# move the static Pod so that it's watched again
cd /etc/kubernetes
mv manifests-tmp/kube-controller-manager.yaml manifests

# verify that the kube-controller-manager pod is running
crictl ps
```
