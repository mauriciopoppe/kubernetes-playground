FROM golang as builder

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

