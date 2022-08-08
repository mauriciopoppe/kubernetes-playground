# controller-runtime

## Client

The kubernetes e2e tests use the [client-go/kubernetes/clientset.go](https://github.com/kubernetes/client-go/blob/a890e7bc14d5062a2a7eb96a5286239383d5cac8/kubernetes/clientset.go#L421)
client to talk with the API server, in addition there's the [dynamic client](https://github.com/iximiuz/client-go-examples/blob/main/crud-dynamic-simple/main.go) that uses the `unstructured.Unstructured` data
structure to perform the API requests, a nice utility in controller-runtime is
its client which can create requests for any registered schema i.e. with it we can
make CRUD request for core objects, extensions provided through a CRD, arbitrary requests with the `unstructured.Unstructured`
data structure.

Read this file for more info: https://github.com/kubernetes-sigs/controller-runtime/blob/master/pkg/client/example_test.go

Under the hood the [CRUD calls](https://github.com/kubernetes-sigs/controller-runtime/blob/master/pkg/client/client.go#L181)
detect the type of object sent in the arguments and decide the client to use (the typed client or the unstructured client)

This example adds the schema used for new CRDs:

```go
// The file where the CRD types are defined
package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime/schema"
	cfg "sigs.k8s.io/controller-runtime/pkg/config/v1alpha1"
	"sigs.k8s.io/controller-runtime/pkg/scheme"
)

var (
	// GroupVersion is group version used to register these objects
	GroupVersion = schema.GroupVersion{Group: "examples.x-k8s.io", Version: "v1alpha1"}

	// SchemeBuilder is used to add go types to the GroupVersionKind scheme
	SchemeBuilder = &scheme.Builder{GroupVersion: GroupVersion}

	// AddToScheme adds the types in this group-version to the given scheme.
	AddToScheme = SchemeBuilder.AddToScheme
)
```

```go
// Setup of main
var scheme = runtime.NewScheme()

func init() {
	// add https://github.com/kubernetes/client-go/blob/master/kubernetes/clientset.go#L421.
	clientgoscheme.AddToScheme(scheme)
	// add our CRDs.
	v1alpha1.AddToScheme(scheme)
}

cl, err := client.New(config.GetConfigOrDie(), client.Options{
	Scheme: scheme
})
if err != nil {
	fmt.Println("failed to create client")
	os.Exit(1)
}
```

[We can use the client](https://github.com/kubernetes-sigs/controller-runtime/blob/master/examples/configfile/custom/controller.go) as follows:

```go
rs := &appsv1.ReplicaSet{}
err := r.client.Get(context.TODO(), request.NamespacedName, rs)
```
