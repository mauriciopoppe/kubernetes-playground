FROM golang:bullseye AS go
RUN apt update && apt install git -y
RUN go install github.com/go-delve/delve/cmd/dlv@v1.23.1
RUN git clone https://github.com/garabik/grc.git /go/src/github.com/garabik/grc

FROM debian:bullseye
RUN apt update && apt install --only-upgrade bash -y
RUN mkdir -p /app/bin
COPY --from=go /go/bin/dlv /app/bin/dlv
COPY --from=go /go/src/github.com/garabik/grc /app/grc

WORKDIR /app
ADD . .

# I read https://github.com/garabik/grc/blob/master/install.sh
# to find out that $1 is the prefix where the binaries (grcat, grc)
# will be installed into.
RUN (cd ./grc && ./install.sh /app/)

ENTRYPOINT ["sleep", "infinity"]
