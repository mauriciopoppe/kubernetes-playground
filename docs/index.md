# Kubernetes Contributor Notes

Notes that I learned from contributing to kubernetes

## Running experiments with skaffold

See ./sandbox-with-debugger.md

## Libraries that I should be aware of

- `apimachinery`
  - `wait` https://pkg.go.dev/k8s.io/apimachinery/pkg/util/wait

## Fragments

### Kubernetes E2E tests

**Running a test in a user defined namespace**

- Create the namespace e.g. `mauricio-stress`
- Set `f.SkipNamespaceCreation = true` and on init assign the namepace to `f.Namespace`

```golang
f := framework.NewFrameworkWithCustomTimeouts("volume", storageframework.GetDriverTimeouts(driver))
f.SkipNamespaceCreation = true

init := func() {
  l = local{}

  ns, err := f.ClientSet.CoreV1().Namespaces().Get(context.TODO(), "mauricio-stress", metav1.GetOptions{})
  if err != nil {
          panic(err)
  }
  f.Namespace = ns
```

### Timers & Wait

---

Exponential backoff (source https://github.com/kubernetes-csi/external-snapshotter/pull/504/files)

Given a struct with the form:

```go
backoff := wait.Backoff{
    Duration: 100 * time.Millisecond,
    Factor:   1.5,
    Steps:    10,
}
```

`wait.ExponentialBackoff(backoff, condition)` will execute `condition` at these times until we reach `Steps` which is when it returns a timeout error, a calculator that's useful is https://exponentialbackoffcalculator.com/

|Run|Seconds|
|---|---|
|0|0.000|
|1|0.100|
|2|0.250|
|3|0.475|
|4|0.813|
|5|1.319|
|6|2.078|
|7|3.217|
|8|4.926|
|9|7.489|

There's also `ExponentialBackoffWithJitter`

---

Tick every X until other chan is ready (source https://github.com/kubernetes-csi/csi-lib-utils/blob/f9b3af56d1f16431977b9e3387a52f13687513f8/connection/connection.go#L157-L178)

```go
var conn *grpc.ClientConn
var err error
ready := make(chan bool)
go func() {
    conn, err = grpc.Dial(address, dialOptions...)
    close(ready)
}()

// Log error every connectionLoggingInterval
ticker := time.NewTicker(connectionLoggingInterval)
defer ticker.Stop()

// Wait until Dial() succeeds.
for {
    select {
    case <-ticker.C:
        klog.Warningf("Still connecting to %s", address)

    case <-ready:
        return conn, err
    }
}
```

---