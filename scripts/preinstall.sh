#!/bin/bash

# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

# shellcheck source=/dev/null
source ./fill-resource-values.sh
# shellcheck source=/dev/null
source ./add-resources-components.sh

function validate() {
    if [[ -z $HYBRID_INSTALL_DIR ]]; then
        echo "Environment variable HYBRID_INSTALL_DIR is not set, please checkout README.md"
        exit 1
    fi

    if [[ -z $WORK_DIR ]]; then
        echo "Environment variable WORK_DIR is not set, please checkout README.md"
        exit 1
    fi
}

validate;
fillResourceValues;
moveResourcesSpecsToHybridInstall;

echo "Updating datastore kustomization"
datastoreKustomizationFile="$HYBRID_INSTALL_DIR/overlays/instances/instance1/datastore/kustomization.yaml";
datastoreComponentEntries=("./components/cassandra-resources")
addComponents "$datastoreKustomizationFile" "${datastoreComponentEntries[@]}"

echo "Updating organization kustomization"
organizationKustomizationFile="$HYBRID_INSTALL_DIR/overlays/instances/instance1/organization/kustomization.yaml";
componentEntries=("./components/connect-resources" "./components/ingressgateway-resources" "./components/mart-resources" "./components/watcher-resources")
addComponents "$organizationKustomizationFile" "${componentEntries[@]}"

echo "Updating environment kustomization"
environmentKustomizationFile="$HYBRID_INSTALL_DIR/overlays/instances/instance1/environments/test/kustomization.yaml";
componentEntries=("./components/runtime-resources" "./components/synchronizer-resources" "./components/udca-resources")
addComponents "$environmentKustomizationFile" "${componentEntries[@]}"

echo "Updating redis kustomization"
redisKustomizationFile="$HYBRID_INSTALL_DIR/overlays/instances/instance1/redis/kustomization.yaml";
componentEntries=("./components/redis-resources" "./components/redisenvoy-resources")
addComponents "$redisKustomizationFile" "${componentEntries[@]}"

echo "Updating telemetry kustomization"
telemetryKustomizationFile="$HYBRID_INSTALL_DIR/overlays/instances/instance1/telemetry/kustomization.yaml";
componentEntries=("./components/telemetry-resources")
addComponents "$telemetryKustomizationFile" "${componentEntries[@]}"