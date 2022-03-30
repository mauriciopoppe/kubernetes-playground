# comes from skaffold
# IMAGE=

# comes from the current project skaffold.yaml file
# APP=

DOCKER=DOCKER_CLI_EXPERIMENTAL=enabled docker

build-linux:
	CGO_ENABLED=0 go build -gcflags="all=-N -l" -ldflags "-X main.version=${TAG}" -o "bin/app" "./cmd/${APP}/"

build-windows:
	GOOS=windows CGO_ENABLED=0 go build -gcflags="all=-N -l" -ldflags "-X main.version=${TAG}" -o "bin/app.exe" "./cmd/${APP}/"

init-buildx:
	# Ensure we use a builder that can leverage it (the default on linux will not)
	-$(DOCKER) buildx rm multiarch-multiplatform-builder
	$(DOCKER) buildx create --use --name=multiarch-multiplatform-builder
	$(DOCKER) run --rm --privileged multiarch/qemu-user-static --reset --credential yes --persistent yes
	# Register gcloud as a Docker credential helper.
	# Required for "docker buildx build --push".
	gcloud auth configure-docker --quiet

build-and-push-container-linux-debug: init-buildx
	$(DOCKER) buildx build --file=Dockerfile --platform=linux \
		-t ${IMAGE}_linux \
		--build-arg BUILDPLATFORM=linux \
		--build-arg APP=${APP} \
		--build-arg TAG=${IMAGE} \
		--load .

build-and-push-container-windows-debug: init-buildx
	$(DOCKER) buildx build --file=Dockerfile.windows --platform=windows \
		-t ${IMAGE}_agnhost \
		--build-arg BASE_IMAGE=k8s.gcr.io/e2e-test-images/agnhost:2.26 \
		--build-arg APP=${APP} \
		--build-arg TAG=${IMAGE} \
		--push .

# build-and-push-multi-arch-debug: build-and-push-container-linux-debug build-and-push-container-windows-debug
	# $(DOCKER) manifest create --amend ${IMAGE} ${IMAGE}_linux ${IMAGE}_ltsc2019
build-and-push-multi-arch-debug: build-and-push-container-windows-debug
	$(DOCKER) manifest create --amend ${IMAGE} ${IMAGE}_agnhost
	$(DOCKER) manifest push -p ${IMAGE}

build-and-push-container-linux:
	$(DOCKER) build --file=Dockerfile --platform=linux \
		-t ${IMAGE} \
		--build-arg BUILDPLATFORM=linux \
		--build-arg APP=${APP} \
		--build-arg TAG=${IMAGE} \
		.

build-and-push-debug: build-and-push-container-linux
