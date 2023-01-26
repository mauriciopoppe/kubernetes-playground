FROM golang:bullseye AS go
RUN apt update && apt install git -y
RUN go install github.com/go-delve/delve/cmd/dlv@latest
RUN git clone https://github.com/garabik/grc.git /go/src/github.com/garabik/grc

FROM debian:bullseye
RUN apt update && apt install --only-upgrade bash -y
RUN mkdir -p /app/bin
COPY --from=go /go/bin/dlv /app/bin/dlv
COPY --from=go /go/src/github.com/garabik/grc /app/grc

WORKDIR /app
ADD . .
RUN (cd ./grc && ./install.sh)

ENTRYPOINT ["sleep", "infinity"]
