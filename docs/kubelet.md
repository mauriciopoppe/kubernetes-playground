# Kubelet

## kubelet debugging in kind

Requirements:

- Tools, k8s tag

```bash
kind --version && dlv version && docker version && (cd $GOPATH/src/k8s.io/kubernetes && git log -1)

kind version 0.22.0
Delve Debugger
Version: 1.22.0
Build: $Id: 61ecdbbe1b574f0dd7d7bad8b6a5d564cce981e9 $
Client:
 Cloud integration: v1.0.31
 Version:           20.10.24
 API version:       1.41
 Go version:        go1.19.7
 Git commit:        297e128
 Built:             Tue Apr  4 18:21:21 2023
 OS/Arch:           darwin/arm64
 Context:           default
 Experimental:      true

Server: Docker Desktop 4.18.0 (104112)
 Engine:
  Version:          20.10.24
  API version:      1.41 (minimum version 1.12)
  Go version:       go1.19.7
  Git commit:       5d6db84
  Built:            Tue Apr  4 18:17:07 2023
  OS/Arch:          linux/arm64
  Experimental:     false
 containerd:
  Version:          1.6.18
  GitCommit:        2456e983eb9e37e47538f59ea18f2043c9a73640
 runc:
  Version:          1.1.4
  GitCommit:        v1.1.4-0-g5fd4c4d
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
commit 4b8e819355d791d96b7e9d9efe4cbafae2311c88 (HEAD, tag: v1.29.2)
Author: Kubernetes Release Robot <k8s-release-robot@users.noreply.github.com>
Date:   Wed Feb 14 10:32:39 2024 +0000

    Release commit for Kubernetes v1.29.2
```

- The kind worker node exposes a port used for debugging, this could be done through
  the config sent to kind (see [/kind-sandbox/config-worker-dlv.yaml](/kind-sandbox/config-worker-dlv.yaml)) or through [cdebug](https://github.com/iximiuz/cdebug)
  which can forward requests to a running container.

```
# NOTE: check that the port 56268 is forwarded from the host to the kind-worker
docker ps
CONTAINER ID   IMAGE                           COMMAND                  CREATED          STATUS                  PORTS                       NAMES
3ce7114e45c1   kindest/node:v1.27.3            "/usr/local/bin/entr…"   24 seconds ago   Up Less than a second   127.0.0.1:43551->6443/tcp   kind-control-plane
336b28d05659   kindest/node:v1.27.3            "/usr/local/bin/entr…"   24 seconds ago   Up Less than a second   0.0.0.0:56268->56268/tcp    kind-worker
```

The steps are:

- one time env setup
  - Install tools that will allow debugging like delve and grc
  - Install a custom systemd config for the kubelet that runs it through delve
  - Install a pretty log formatter for grc, this is optional but I like a way to distinguish
    different lines logged by journalctl
  - Configure your editor to connect to the server
- normal workflow
  - make changes in the k8s codebase, recompile the kubelet and sync it to the kind node
  - restart the kubelet service
  - make your editor forward breakpoints to the delve server
  - delve will stop at the breakpoints set 🥳

### Editor (one time setup)

In my editor [Neovim](https://neovim.io/) I set the following [nvim-dap](https://github.com/mfussenegger/nvim-dap) config:

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
    -- back in my workstation I connected to it through `dlv connect :56268`
    -- Inside it I run `sources` and it printed the list of files in the kubelet (showing the full path)
    -- Based on that I added the following substitutePath rule
    substitutePath = {
      {
          from = "${workspaceFolder}",
          to = "/go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes",
      },
    },
  },
```

For more info about this setup please [check my dotfiles](https://github.com/mauriciopoppe/dotfiles/blob/10ca972e5bdeccf374dc4a75bc3236a07b051dcf/neovim/lua/plugins/debugger.lua#L205).

### Instrument the kubelet for debugging through a sidecar (automated one time setup)

An alternative is to install the tooling needed for debugging through a sidecar
container, this can be done through [cdebug](https://github.com/iximiuz/cdebug).

- Install cdebug

```
GOOS=darwin
GOARCH=arm64
curl -Ls https://github.com/iximiuz/cdebug/releases/latest/download/cdebug_${GOOS}_${GOARCH}.tar.gz | tar xvz
sudo mv cdebug /usr/local/bin

cdebug --version
cdebug version 0.0.17
```

- Build the kubelet-debug:latest sidecar (the Dockerfile is in this repo)

```bash
# PWD is the root of this repo
make -C ./debug kubelet-debug
```

- Instrument any `kind-worker` container

```bash
cdebug exec --image kubelet-debug:latest -it docker://kind-worker '$CDEBUG_ROOTFS/app/kubelet-debug-entrypoint.sh'
```

### Instrument the kubelet for debugging (alternative one time manual setup)

```bash
# install tooling for better logging on the worker node
# (this is for a kind cluster but a similar script should work in a VM)
docker exec -i kind-worker bash -c "
set -x; \
sed -i -re 's/ports.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list; \
sed -i -re 's/ubuntu-ports/ubuntu/g' /etc/apt/sources.list; \
apt-get update && apt-get install grc golang-go python3 -y; \
GOPATH=/root/go go install github.com/go-delve/delve/cmd/dlv@latest; \
cp /root/go/bin/dlv /usr/local/bin; \
mkdir -p /etc/systemd/system/kubelet-debug.service.d/
"
# setup kubelet-debug service and pretty log format
docker cp debug/kubelet/kubelet-debug.service kind-worker:/etc/systemd/system/kubelet-debug.service
docker cp debug/kubelet/10-kubeadm.conf kind-worker:/etc/systemd/system/kubelet-debug.service.d/10-kubeadm.conf
docker cp debug/kubelet/conf.kubernetes kind-worker:/etc/systemd/system/kubelet-debug.service.d/conf.kubernetes
```

### Regular workflow

In the kubernetes codebase, recompile the kubelet and run it in the worker:

```bash
# cross compile the kubelet to run in the kind-worker arch
# see /docs/kubernetes-development.md for the script to compile the kubelet inside a container
KUBE_VERBOSE=0 KUBE_FASTBUILD=true KUBE_RELEASE_RUN_TESTS=n \
  ./build/make-in-container.sh make all WHAT=cmd/kubelet DBG=1

# restart kubelet
# NOTE: the path might need to be updated depending on the platform (amd64, arm64)
docker cp _output/dockerized/bin/linux/arm64/kubelet kind-worker:/usr/bin/kubelet-debug
docker exec -i kind-worker bash -c "systemctl daemon-reload; systemctl restart kubelet-debug"
```

In another terminal, exec into the kind-worker container and see the kubelet output

```bash
docker exec -it kind-worker bash
journalctl --since "$(systemctl show -p ActiveEnterTimestamp kubelet-debug | awk '{print $2 $3}')" -u kubelet-debug -f | grcat /etc/systemd/system/kubelet-debug.service.d/conf.kubernetes
```

![kubelet journalctl logs](https://user-images.githubusercontent.com/1616682/213890085-20e22c5c-7cc5-4daa-bc5c-4e64a3dcf71b.png)

In my nvim editor set breakpoints and connect nvim-dap to the kubelet server, for more info about this
setup read: [kubernetes development](./kubernetes-development.md)

![breakpoints in nvim](https://user-images.githubusercontent.com/1616682/213890345-2be28772-c488-4b46-9569-1cdf2c5c6905.png)
