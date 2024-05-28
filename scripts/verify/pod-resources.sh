#!/bin/bash

set -e

KUBECTL="kubectl -n apigee"
pods=$($KUBECTL get pods --no-headers -o custom-columns=NAME:.metadata.name)

function usage() {

  for pod in $pods; do
    printf "\n\n$pod:-\n"
    kubectl get pod "$pod" -n apigee -o jsonpath='{.spec.containers[*].resources.requests}'
  done
}

usage;