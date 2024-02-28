# containerd

## containerd setup in kind

From the containerd [getting started page](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)
we need to: install containerd (binary), configure containerd to start through systemd, install runc (binary), install CNI plugins.

The kind base image defines the binaries to build binaries for:

- [containerd](https://github.com/kubernetes-sigs/kind/blob/7c2f6c1dcd332c039ac3e7d3e3dc0dd1ec2e6a6d/images/base/Dockerfile#L122)
- [runc](https://github.com/kubernetes-sigs/kind/blob/7c2f6c1dcd332c039ac3e7d3e3dc0dd1ec2e6a6d/images/base/Dockerfile#L139)
- [crictl](https://github.com/kubernetes-sigs/kind/blob/7c2f6c1dcd332c039ac3e7d3e3dc0dd1ec2e6a6d/images/base/Dockerfile#L152)
- [cni](https://github.com/kubernetes-sigs/kind/blob/7c2f6c1dcd332c039ac3e7d3e3dc0dd1ec2e6a6d/images/base/Dockerfile#L165)

And configuration to start containerd:

- [/etc/containerd/config.toml](https://github.com/kubernetes-sigs/kind/blob/7c2f6c1dcd332c039ac3e7d3e3dc0dd1ec2e6a6d/images/base/files/etc/containerd/config.toml)
- [/etc/systemd/system/containerd.service](https://github.com/kubernetes-sigs/kind/blob/7c2f6c1dcd332c039ac3e7d3e3dc0dd1ec2e6a6d/images/base/files/etc/systemd/system/containerd.service)

## Building containerd from source

Read the [containerd building docs](https://github.com/containerd/containerd/blob/main/BUILDING.md).

Clone the containerd and runc repos under the same folder e.g.

```sh
~/go/src/github.com/containerd
ls -la
total 0
drwxr-xr-x   4 mauriciopoppe  staff   128 Feb 19 15:35 .
drwxr-xr-x   9 mauriciopoppe  staff   288 Feb 19 15:35 ..
drwxr-xr-x  50 mauriciopoppe  staff  1600 Feb 19 15:36 containerd
drwxr-xr-x  64 mauriciopoppe  staff  2048 Feb 19 15:35 runc
```

Create the file `Dockerfile.dev` at this level:

```dockerfile
FROM golang

RUN apt-get update && \
    apt-get install -y libseccomp-dev
```

Build the image:

```sh
docker build -f Dockerfile.dev -t containerd/build .
```

Create a build container based on this image mounting both the containerd and runc codebases:

```sh
docker run -it --privileged \
    -v /var/lib/containerd \
    -v ${PWD}/runc:/go/src/github.com/opencontainers/runc \
    -v ${PWD}/containerd:/go/src/github.com/containerd/containerd \
    -e GOPATH=/go \
    -w /go/src/github.com/containerd/containerd containerd/build sh
```

Build containerd:

```sh
# in the build container:
cd /go/src/github.com/containerd/containerd
make && make install

# in the host:
ls -la bin
total 200008
drwxr-xr-x   6 mauriciopoppe  staff       192 Feb 19 15:43 .
drwxr-xr-x  50 mauriciopoppe  staff      1600 Feb 19 15:43 ..
-rwxr-xr-x   1 mauriciopoppe  staff  49633057 Feb 19 15:43 containerd
-rwxr-xr-x   1 mauriciopoppe  staff  12386456 Feb 19 15:43 containerd-shim-runc-v2
-rwxr-xr-x   1 mauriciopoppe  staff  19923265 Feb 19 15:43 containerd-stress
-rwxr-xr-x   1 mauriciopoppe  staff  20447553 Feb 19 15:43 ctr
```

Build runc:

```sh
# in the build container:
cd /go/src/github.com/opencontainers/runc
make && make install

# in the host the binary is at the root of ./runc
~/go/src/github.com/containerd
ls -la runc | grep runc
-rwxr-xr-x   1 mauriciopoppe  staff  13621536 Feb 19 15:44 runc
```

## Using dev binaries of containerd and runc in kind

The steps are very similar to my kubelet debug guide

- one time env setup
  - Install tools that will allow debugging like delve and grc
  - Install a custom systemd config for containerd that runs it through delve
  - Install a pretty log formatter for grc, this is optional but I like a way to distinguish
    different lines logged by journalctl
  - Configure your editor to connect to the server
- normal workflow
  - make changes in the containerd codebase, recompile containerd and sync it to the kind node
  - restart the containerd service
  - make your editor forward breakpoints to the delve server
  - delve will stop at the breakpoints set 🥳

### Instrument the kind node for debugging through a sidecar (automated one time setup)

- Install cdebug

```
GOOS=darwin
GOARCH=arm64
curl -Ls https://github.com/iximiuz/cdebug/releases/latest/download/cdebug_${GOOS}_${GOARCH}.tar.gz | tar xvz
sudo mv cdebug /usr/local/bin

cdebug --version
cdebug version 0.0.17
```

- Build the containerd-debug:latest sidecar (the Dockerfile is in this repo)

```bash
# PWD is the root of this repo
make -C ./debug containerd-debug
```

- Instrument any `kind-worker` container

```bash
cdebug exec --image containerd-debug:latest -it docker://kind-worker '$CDEBUG_ROOTFS/app/containerd-debug-entrypoint.sh'
```

### Regular workflow

In the containerd codebase, recompile containerd with the instructions above and run it in the worker:

```bash
# in the build container:
cd /go/src/github.com/containerd/containerd
make && make install

# sync dev version of containerd
docker cp containerd/bin/containerd kind-worker:/usr/local/bin/containerd-debug
docker exec -i kind-worker bash -c "systemctl daemon-reload; systemctl restart containerd-debug"
```

In another terminal, exec into the kind-worker container and see the containerd output

```bash
docker exec -it kind-worker bash
journalctl --since "$(systemctl show -p ActiveEnterTimestamp containerd-debug | awk '{print $2 $3}')" -u containerd-debug
```

