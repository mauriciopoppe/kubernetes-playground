package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"time"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"

	"k8s.io/klog/v2"
)

// Command line flags
var (
	// version is filled by an ldflag (see the Dockerfile)
	version    string
	kubeconfig = flag.String("kubeconfig", "", "Absolute path to the kubeconfig file. Required only when running out of cluster.")
)

func main() {
	klog.InitFlags(flag.CommandLine)
	flag.Set("logtostderr", "true")
	flag.Parse()
	klog.Infof("Version %+v", version)

	// Create the client config. Use kubeconfig if given, otherwise assume in-cluster.
	config, err := buildConfig(*kubeconfig)
	if err != nil {
		klog.Error(err.Error())
		os.Exit(1)
	}

	kubeClient, err := kubernetes.NewForConfig(config)
	if err != nil {
		klog.Error(err.Error())
		os.Exit(1)
	}

	for {
		ns1, err := kubeClient.CoreV1().Namespaces().Get(context.TODO(), "kube-system", metav1.GetOptions{})
		klog.Infof("Hello world from a windows node!")
		klog.Infof("ns1=%+v err=%+v\n", ns1, err)

		cmd := fmt.Sprintf(`Invoke-RestMethod  -Headers @{"Metadata-Flavor"="Google"} -Uri  http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email  -UseBasicParsing`)
		output, err := exec.Command("powershell", "/c", cmd).CombinedOutput()
		klog.Infof("output=%q", string(output))

		cmd1 := fmt.Sprintf(`Invoke-RestMethod  -Headers @{"Metadata-Flavor"="Google"} -Uri  http://169.254.169.254/computeMetadata/v1/instance/id  -UseBasicParsing`)
		output1, err := exec.Command("powershell", "/c", cmd1).CombinedOutput()
		klog.Infof("output1=%q", string(output1))

		time.Sleep(time.Second * 5)
	}
}

func buildConfig(kubeconfig string) (*rest.Config, error) {
	if kubeconfig != "" {
		return clientcmd.BuildConfigFromFlags("", kubeconfig)
	}
	return rest.InClusterConfig()
}
