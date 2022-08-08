# Default Storage Class

Intro: https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#defaultstorageclass

## Registration of default admissions plugins

There's a set of default admission plugins enabled
https://cs.github.com/kubernetes/kubernetes/blob/afb0136d6235201a89a426f071b8957a5a1b79ef/pkg/kubeapiserver/options/admission.go#L59

```go
func NewAdmissionOptions() *AdmissionOptions {
	options := genericoptions.NewAdmissionOptions()
	// register all admission plugins
	// including the DefaultStorageClass admission plugin
	RegisterAllAdmissionPlugins(options.Plugins)
	// set RecommendedPluginOrder
	options.RecommendedPluginOrder = AllOrderedPlugins
	// set DefaultOffPlugins
	options.DefaultOffPlugins = DefaultOffAdmissionPlugins()

	return &AdmissionOptions{
		GenericAdmission: options,
	}
}
```

https://cs.github.com/kubernetes/kubernetes/blob/afb0136d6235201a89a426f071b8957a5a1b79ef/pkg/kubeapiserver/options/plugins.go#L109

```go
import (
	"k8s.io/kubernetes/plugin/pkg/admission/storage/storageclass/setdefault"
)
func RegisterAllAdmissionPlugins(plugins *admission.Plugins) {
    // ...
    // NOTE: setdefault is the name of the import for the DefaultStorageClass plugin
	setdefault.Register(plugins)
    // ...
}
```

https://cs.github.com/kubernetes/kubernetes/blob/afb0136d6235201a89a426f071b8957a5a1b79ef/plugin/pkg/admission/storage/storageclass/setdefault/admission.go#L44

```go
// Register registers a plugin
func Register(plugins *admission.Plugins) {
	plugins.Register(PluginName, func(config io.Reader) (admission.Interface, error) {
		plugin := newPlugin()
		return plugin, nil
	})
}
```

