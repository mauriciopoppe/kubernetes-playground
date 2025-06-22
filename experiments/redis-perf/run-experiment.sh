#!/bin/bash

set -euxo pipefail

kubectl delete namespace benchmark || true
kubectl create namespace benchmark
kubectl apply -f redis.yaml
kubectl apply -f memtier.yaml
