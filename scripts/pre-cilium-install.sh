#!/usr/bin/env bash

set -uo pipefail

while ! kubectl get namespace > /dev/null 2>&1;
do
  echo "Waiting for Kubernetes API..."
  sleep 10
done

echo "Kubernetes API is ready"
