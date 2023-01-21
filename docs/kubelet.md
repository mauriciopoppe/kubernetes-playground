# Kubelet

## kubelet debugging in kind

Requirements:

- The kind worker node exposes a port used for debugging, this could be done through
  the config sent to kind (see /kind-sandbox/config-worker-dlv.yaml) or through cdebug
  which can forward requests to a running container

The steps are:

- one time env setup
  - Install tools that will allow debugging like delve and grc
  - Install a custom systemd config for the kubelet that runs it through delve
  - Install a pretty log formatter for grc, this is optional but I like a way to distinguish different lines logged
    by journalctl
  - Configure your editor to connect to the server
- normal workflow
  - make changes in the k8s codebase, recompile the kubelet and sync it to the kind node
  - restart the kubelet service
  - make your editor forward breakpoints to the delve server
  - delve will stop at the breakpoints set 🥳

### One time env setup

```bash
# install tooling for better logging on the worker node
# (this is for kind but a similar script should work in a VM)
docker exec -i kind-worker bash -c "
set -x; \
sed -i -re 's/ports.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list; \
sed -i -re 's/ubuntu-ports/ubuntu/g' /etc/apt/sources.list; \
apt-get update && apt-get install grc curl golang-go -y; \
GOPATH=/root/go/bin go install github.com/go-delve/delve/cmd/dlv@latest; \
cp /root/go/bin/dlv /usr/local/bin; \
"
# start kubelet with dlv
docker cp debug/kubelet/10-kubeadm.conf kind-worker:/etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# pretty logs
docker cp $DOTFILES_DIRECTORY/zsh/lib/grc/conf.kubernetes kind-worker:/kind/grcat-kubelet-conf.log
```

In my nvim editor I set the following nvim lua config to debug it through nvim-dap:

```lua
  {
    type = "go",
    name = "Attach kubelet (remote)",
    debugAdapter = "dlv-dap",
    request = "attach",
    mode = "remote",
    host = "127.0.0.1",
    port = "56268",
    stopOnEntry = false,
    -- I started the kubelet in kind through delve listening on port 56268
    -- next I connected to it through `dlv connect :56268`
    -- inside it I run `sources` and it printed the list of files in the kubelet
    -- together with the right path, later I added this path to the substitutePath
    -- option in the config below
    substitutePath = {
      {
          from = "${workspaceFolder}",
          to = "/go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes",
      },
    },
  },
```

### Normal workflow

In the kubernetes codebase, recompile the kubelet and run it in the worker:

```bash
# cross compile the kubelet to run in the kind-worker arch
# see /docs/kubernetes-development.md for the script to compile the kubelet inside a container
KUBE_VERBOSE=0 KUBE_FASTBUILD=true KUBE_RELEASE_RUN_TESTS=n \
  ./build/make-in-container.sh make all WHAT=cmd/kubelet DBG=1

# restart kubelet
docker cp _output/dockerized/bin/linux/arm64/kubelet kind-worker:/usr/bin/kubelet
docker exec -i kind-worker bash -c "systemctl daemon-reload; systemctl restart kubelet"
```

In another terminal, exec into the kubelet and see the kubelet output

```bash
journalctl -u kubelet -f | grcat /kind/grcat-kubelet-conf.log
```

![kubelet journalctl logs](https://user-images.githubusercontent.com/1616682/213890085-20e22c5c-7cc5-4daa-bc5c-4e64a3dcf71b.png)

In my nvim editor set breakpoints and connect nvim-dap to the kubelet server

![breakpoints in nvim](https://user-images.githubusercontent.com/1616682/213890345-2be28772-c488-4b46-9569-1cdf2c5c6905.png)
