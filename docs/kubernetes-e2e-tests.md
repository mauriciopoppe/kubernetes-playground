# Kubernetes E2E tests

**Running a test in a user defined namespace**

- Create the namespace e.g. `mauricio-stress`
- Set `f.SkipNamespaceCreation = true` and on init assign the namepace to `f.Namespace`

```go
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

