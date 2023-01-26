# Kubernetes unit tests

Main doc: https://github.com/kubernetes/community/blob/master/contributors/devel/sig-testing/testing.md#run-unit-tests-using-go-test

## Running tests inside a container

```bash
# Node shutdown manager unit tests
docker run -v $(pwd):/go/src/k8s.io/kubernetes -w /go/src/k8s.io/kubernetes golang \
  go test ./pkg/kubelet/nodeshutdown -v -tags=linux
```
