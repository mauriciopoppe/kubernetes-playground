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
