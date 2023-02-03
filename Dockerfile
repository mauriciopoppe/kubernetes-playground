# skaffold debug only works with go<=1.19 because of the delve version used
# in https://github.com/GoogleContainerTools/container-debug-support/blob/duct-tape/go/helper-image/Dockerfile
FROM golang:1.19 as builder

WORKDIR /go/src/github.com/mauriciopoppe/kubernetes-playground/
ADD go.mod .
ADD go.sum .

ADD . .
RUN go mod download

ARG APP
ARG TAG
RUN make build-linux

# runner
FROM scratch

# Define GOTRACEBACK to mark this container as using the Go language runtime
# for `skaffold debug` (https://skaffold.dev/docs/workflows/debug/).
ENV GOTRACEBACK=all

WORKDIR /go/src/github.com/mauriciopoppe/kubernetes-playground/
ADD . .
COPY --from=builder /go/src/github.com/mauriciopoppe/kubernetes-playground/bin/app bin/app

ENTRYPOINT ["/go/src/github.com/mauriciopoppe/kubernetes-playground/bin/app"]

