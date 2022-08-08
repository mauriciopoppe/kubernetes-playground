# Kubernetes Utils

## Timers & Wait

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
