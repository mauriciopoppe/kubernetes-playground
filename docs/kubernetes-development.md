# Kubernetes development

## Compiling binaries in debug mode

**Main doc: [contributors/devel/development.md](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#building-kubernetes)**

Run `make WHAT=cmd/<target>`, the binaries are at `_output/bin/<target>`, for example to build the kube-controller-manager:

```bash
# DBG=1 sets the gcflags 'all=-N -l'
make all WHAT=cmd/kube-controller-manager DBG=1
```

## Compiling binaries in debug mode within the kubernetes builder container

In the kubernetes codebase, create the file `build/make-in-container.sh` with the following contents

```bash
#!/usr/bin/env bash

# Copyright 2014 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Runs a command inside the builder image, it could be used to build a binary.

set -o errexit
set -o nounset
set -o pipefail

KUBE_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
source "${KUBE_ROOT}/build/common.sh"
source "${KUBE_ROOT}/build/lib/release.sh"

KUBE_RELEASE_RUN_TESTS=${KUBE_RELEASE_RUN_TESTS-y}

kube::build::verify_prereqs
kube::build::build_image
kube::build::run_build_command $@
kube::build::copy_output
```

Then call it like this:

```bash
KUBE_VERBOSE=0 KUBE_FASTBUILD=true KUBE_RELEASE_RUN_TESTS=n \
  ./build/make-in-container.sh make all WHAT=cmd/kubelet DBG=1
```

This is useful for some components like the kubelet that kind runs inside an Ubuntu container, with the above
we can cross compile it with the linux/arm64 arch and replace it in a running kind cluster.

## Debug a binary with delve

I use [delve](https://github.com/go-delve/delve) to run the binaries in debug mode

```bash
# download delve
go install github.com/go-delve/delve/cmd/dlv@v1.9.1
```

**Headless debugging**

Run delve in server mode with a debug binary (it creates a delve server, it connects to the server and starts the target binary), it waits for a client to connect to the server through an editor.

See `/docs/sandbox-with-debugger.yaml` for more info about my neovim setup.

```bash
# run the program in server headless mode through delve
dlv --listen :38697 --continue --accept-multiclient --api-version=2 --headless \
  exec ./_output/bin/kube-controller-manager -- \
  --kubeconfig=${HOME}/.kube/config --leader-elect=false --controllers="*"

# Use your editor's dap integration to attach your editor to the running program
```

## Using kind

Read:

- https://kind.sigs.k8s.io/docs/user/quick-start/#building-images
- https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#building-kubernetes-with-docker

Steps:

- Clone the kubernetes codebase to `$GOPATH/src/k8s.io/kubernetes`
- Read the steps in https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#building-kubernetes-on-a-local-osshell-environment, install dependencies if needed
- Run `kind build node-image`
- Create a configuration file like the one in `/kind-sandbox` e.g.
- Start kind with `kind create cluster --config=./config.yaml --image=kindest/node:main`

### How does `kind build node-image` work?

Public docs: https://kind.sigs.k8s.io/docs/design/node-image/

This is my analysis of what's going on under the hood in https://github.com/kubernetes-sigs/kind/blob/main/pkg/build/nodeimage/

- chdir to the kubernetes project root, it's assumed to be at $GOPATH/src/k8s.io/kubernetes
- run the following command to build the binaries:

```bash
make quick-release-images \
  KUBE_VERBOSE=0 KUBE_BUILD_HYPERKUBE=n KUBE_BUILD_CONFORMANCE=n KUBE_BUILD_PLATFORMS=linux/arm64 \
  KUBE_EXTRA_WHAT="cmd/kubeadm cmd/kubectl cmd/kubelet"

+++ [0115 12:24:33] Verifying Prerequisites....
+++ [0115 12:24:33] Using docker on macOS
+++ [0115 12:24:34] Building Docker image kube-build:build-976d986f6a-5-v1.25.0-go1.19-bullseye.0
+++ [0115 12:24:42] Syncing sources to container
+++ [0115 12:24:44] Running build command...
+++ [0115 12:24:46] Building go targets for linux/arm64
    k8s.io/kubernetes/hack/make-rules/helpers/go2make (non-static)
+++ [0115 12:24:50] Generating prerelease lifecycle code for 27 targets
+++ [0115 12:24:53] Generating deepcopy code for 242 targets
+++ [0115 12:24:58] Generating defaulter code for 95 targets
+++ [0115 12:25:04] Generating conversion code for 132 targets
+++ [0115 12:25:15] Generating openapi code for KUBE
+++ [0115 12:25:30] Generating openapi code for AGGREGATOR
+++ [0115 12:25:31] Generating openapi code for APIEXTENSIONS
+++ [0115 12:25:32] Generating openapi code for CODEGEN
+++ [0115 12:25:33] Generating openapi code for SAMPLEAPISERVER
+++ [0115 12:25:34] Building go targets for linux/arm64
    k8s.io/kubernetes/cmd/kube-apiserver (static)
    k8s.io/kubernetes/cmd/kube-controller-manager (static)
    k8s.io/kubernetes/cmd/kube-scheduler (static)
    k8s.io/kubernetes/cmd/kube-proxy (static)
    k8s.io/kubernetes/cmd/kubeadm (static)
    k8s.io/kubernetes/cmd/kubectl (static)
    k8s.io/kubernetes/cmd/kubelet (non-static)
+++ [0115 12:26:48] Syncing out of container
+++ [0115 12:26:52] Building images: linux-arm64
+++ [0115 12:26:52] Starting docker build for image: kube-apiserver-arm64
+++ [0115 12:26:52] Starting docker build for image: kube-controller-manager-arm64
+++ [0115 12:26:52] Starting docker build for image: kube-scheduler-arm64
+++ [0115 12:26:52] Starting docker build for image: kube-proxy-arm64
+++ [0115 12:27:00] Deleting docker image registry.k8s.io/kube-scheduler-arm64:v1.25.0-dirty
+++ [0115 12:27:01] Deleting docker image registry.k8s.io/kube-proxy-arm64:v1.25.0-dirty
+++ [0115 12:27:03] Deleting docker image registry.k8s.io/kube-controller-manager-arm64:v1.25.0-dirty
+++ [0115 12:27:06] Deleting docker image registry.k8s.io/kube-apiserver-arm64:v1.25.0-dirty
+++ [0115 12:27:06] Docker builds done
```

- Output will be at [these locations](https://github.com/kubernetes-sigs/kind/blob/aa147e7bd41f4aa868a374ce91688714c40c1ca3/pkg/build/nodeimage/internal/kube/builder_docker.go#L137-L142):

```
kubernetes/_output/dockerized/bin/linux/arm64/{kubeadm,kubelet,kubectl}
kubernetes/_output/release-images/arm64/kube-{apiserver,controller-manager,proxy,scheduler}.tar
```

- It then runs a prebuilt kind base image [docker.io/kindest/base](https://github.com/kubernetes-sigs/kind/blob/main/images/base/Dockerfile)

```bash
# it actually runs it in detached mode
docker run --privileged --entrypoint=sleep --name=kind-build-manual --platform=linux/arm64 --security-opt=seccomp=unconfined docker.io/kindest/base:v20221220-6c392628 infinity

# copy binaries to node e.g. kubeadm, set chmod +x and chown root:root
binaries=( kubeadm kubectl kubelet )
for binary in "${binaries[@]}"; do
  docker cp $PWD/_output/dockerized/bin/linux/arm64/$binary kind-build-manual:/usr/bin/$binary
  docker exec -i kind-build-manual chmod +x /usr/bin/$binary
  docker exec -i kind-build-manual chown root:root /usr/bin/$binary
done

# write kubernetes version to /kind/version
# inside the image:
root@2b82bed39fe5:/kind# mkdir /kind; echo "v1.25.0-dirty" > /kind/version

# list images required by kubeadm
root@6f7a5781ab5c:/# kubeadm config images list --kubernetes-version v1.25.0-dirty
registry.k8s.io/kube-apiserver:v1.25.0-dirty
registry.k8s.io/kube-controller-manager:v1.25.0-dirty
registry.k8s.io/kube-scheduler:v1.25.0-dirty
registry.k8s.io/kube-proxy:v1.25.0-dirty
registry.k8s.io/pause:3.8
registry.k8s.io/etcd:3.5.4-0
registry.k8s.io/coredns/coredns:v1.9.3

# replace the pause image with kind's pause image
# add CNI images, create default manifests (https://github.com/kubernetes-sigs/kind/blob/main/pkg/build/nodeimage/const_cni.go)
root@2b82bed39fe5:/kind# cat /kind/manifests/default-cni.yaml

# add storage images, create default manifests (https://github.com/kubernetes-sigs/kind/blob/main/pkg/build/nodeimage/const_storage.go)
root@2b82bed39fe5:/kind# cat /kind/manifests/default-storage.yaml

# prepare containerd
root@3c6a0ef234f2:/usr/bin# nohup containerd > /dev/null 2>&1 &
# pull all other images that aren't in kube-{apiserver,controller-manager,proxy,scheduler}.tar
# e.g. etcd, coredns, CNI, storage images

root@3c6a0ef234f2:/usr/bin# ctr --namespace=k8s.io images pull --platform=linux/arm64 registry.k8s.io/etcd:3.5.4-0
registry.k8s.io/etcd:3.5.4-0:                                                     resolved       |++++++++++++++++++++++++++++++++++++++|
index-sha256:6f72b851544986cb0921b53ea655ec04c36131248f16d4ad110cb3ca0c369dc1:    done           |++++++++++++++++++++++++++++++++++++++|
manifest-sha256:789b385ccf97973273adf46778fe13993c143b217406d97d63b6da405e757950: done           |++++++++++++++++++++++++++++++++++++++|
layer-sha256:8fe6b49c57cd2bce2f1af362f358640470d5131c407c12e10631b30964ad59af:    done           |++++++++++++++++++++++++++++++++++++++|
config-sha256:8e041a3b0ba8b5f930b1732f7e2ddb654b1739c89b068ff433008d633a51cd03:   done           |++++++++++++++++++++++++++++++++++++++|
layer-sha256:b0b160e41cf35d4a469a1209cfd553534b248053060de060cbbc4a5d912ad5f0:    done           |++++++++++++++++++++++++++++++++++++++|
layer-sha256:5234205a96191526218ff32a9f34ddaa1382152f0f4d4250734fd9eb3fa29b8a:    done           |++++++++++++++++++++++++++++++++++++++|
layer-sha256:6e653fb4572b38c44535186ff007c88f43f00a1cbf1e73d402bfde32c5ed47cb:    done           |++++++++++++++++++++++++++++++++++++++|
layer-sha256:53e4b5eb44b3ba10af4adf9f6f118262bfbbdca54fad127e92648a0b2be0961c:    done           |++++++++++++++++++++++++++++++++++++++|
elapsed: 7.3 s                                                                    total:  76.4 M (10.5 MiB/s)
unpacking linux/arm64 sha256:6f72b851544986cb0921b53ea655ec04c36131248f16d4ad110cb3ca0c369dc1...
done: 947.555625ms
```

- Updates the docker image manifests so that don't have the arch suffix
- Final list of images imported into the builder image

```
root@6f7a5781ab5c:/# ctr --namespace=k8s.io images ls -q
docker.io/kindest/kindnetd:v20211122-a2c10462
docker.io/rancher/local-path-provisioner:v0.0.14
k8s.gcr.io/build-image/debian-base:buster-v1.7.2
k8s.gcr.io/pause:3.6
registry.k8s.io/coredns/coredns:v1.9.3
registry.k8s.io/etcd:3.5.4-0
registry.k8s.io/kube-apiserver:v1.25.0-dirty
registry.k8s.io/kube-controller-manager:v1.25.0-dirty
registry.k8s.io/kube-proxy:v1.25.0-dirty
registry.k8s.io/kube-scheduler:v1.25.0-dirty
sha256:2a2fd040c30da1fa7d5f115701fdd98180b585ed5fb40f126a3ba9f73e7588e7
sha256:2b703ea309660ea944a48f41bb7a55716d84427cf5e04b8078bcdc44fa4ab2eb
sha256:31c800ce66b59baf852bf24f41cda75b65b65cae19ee224432d2f555b83d658c
sha256:7d46a07936af93fcce097459055f93ab07331509aa55f4a2a90d95a3ace1850e
sha256:7ee5a0f818e59c7e242414ddfa4f2aff3193b4f01046905a2b222d1ebc870927
sha256:8e041a3b0ba8b5f930b1732f7e2ddb654b1739c89b068ff433008d633a51cd03
sha256:ae1c622332ee60e894e68977e4b007577678b193cba45fb49203225bb3ef8b05
sha256:b19406328e70dd2f6a36d6dbe4e867b0684ced2fdeb2f02ecb54ead39ec0bac0
sha256:d0a7325ee7ba50b31fb10dd5d4233ed9bbbc1dedd1166e754f634f94a214869a
sha256:e767a71db6387bd20f674911160ae2fd3aa454d850d3fb1c0fa8bcb44f942537
```

- Commit these changes to a new image with `docker commit`

```
docker image
REPOSITORY     TAG      IMAGE ID       CREATED          SIZE
kindest/node   latest   261731b26d54   11 minutes ago   1.37GB
```

- This is the base image used in the kind nodes :)
