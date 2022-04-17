# Sandboxes

## Why do we need sandboxes?

Experimentation and iteration, it's way faster to experiment on a small program
than on a real project.

I used this in:

- https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner - To prove
  some theories about running powershell commands from the context of the container,
  by isolating the commands and running them in a small go program I could iterate
  way faster than redeploying the local-static-provisioner app.
- My experiments with client-go

## Setup

With skaffold and delve

- add this line to ~/.config/dlv/config.yml (or ~/.dlv/config.yml in macOS)
```
substitute-path:
  # - {from: path, to: path}
  - {from: /go/src/github.com/mauriciopoppe/kubernetes-playground, to: ./}
```

- create the namespace for the app
```
kubectl create namespace sandbox
```

- run skaffold in one terminal
```
skaffold debug -f cmd/hello-world-linux/skaffold.yaml
```

- and delve in the other
```
(dlv) b main.go:46
Breakpoint 1 set at 0x118b754 for main.main() ./cmd/hello-world-linux/main.go:46
(dlv) c
> main.main() ./cmd/hello-world-linux/main.go:46 (hits goroutine(1):1 total:1) (PC: 0x118b754)
    41:                 os.Exit(1)
    42:         }
    43:
    44:         for {
    45:                 ns1, err := kubeClient.CoreV1().Namespaces().Get(context.TODO(), "kube-system", metav1.GetOptions{})
=>  46:                 klog.Infof("Hello world from linux! My name is Mauricio")
    47:                 klog.Infof("ns1=%+v err=%+v\n", ns1, err)
    48:
    49:                 time.Sleep(time.Second * 10)
    50:         }
    51: }
(dlv) p ns1
*k8s.io/api/core/v1.Namespace {
        TypeMeta: k8s.io/apimachinery/pkg/apis/meta/v1.TypeMeta {Kind: "", APIVersion: ""},
        ObjectMeta: k8s.io/apimachinery/pkg/apis/meta/v1.ObjectMeta {
            Name: "kube-system",
...
```

Projects:

- `cmd/hello-world-linux` - Accessing the API server from a pod.
- `cmd/hello-world-windows` - Works only in windows nodes, same as hello-world-linux but with a windows binary.

