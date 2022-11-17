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

function fillResourceValues() {
  kpt fn eval "${WORK_DIR}/overlays/" \
      --image gcr.io/kpt-fn/apply-setters:v0.2.0 -- \
      CASSANDRA_CPU="250m" \
      CASSANDRA_MEM="256Mi" \
      RUNTIME_CPU="200m" \
      RUNTIME_MEM="256Mi" \
      SYNCHRONIZER_CPU="100m" \
      SYNCHRONIZER_MEM="128Mi" \
      FLUENTD_CPU="100m" \
      FLUENTD_MEM="64Mi" \
      UDCA_CPU="100m" \
      UDCA_MEM="128Mi" \
      CONNECT_CPU="50m" \
      CONNECT_MEM="32Mi" \
      INGRESS_GTWY_CPU="150m" \
      INGRESS_GTWY_MEM="64Mi" \
      MART_CPU="100m" \
      MART_MEM="64Mi" \
      WATCHER_CPU="100m" \
      WATCHER_MEM="32Mi" \
      METRICSAPP_STACKDRIVER_CPU="150m" \
      METRICSAPP_STACKDRIVER_MEM="64Mi" \
      METRICSAPP_PROMETHEUS_CPU="150m" \
      METRICSAPP_PROMETHEUS_MEM="64Mi" \
      METRICSPROXY_PROMETHEUS_CPU="125m" \
      METRICSPROXY_PROMETHEUS_MEM="64Mi" \
      METRICSPROXY_STACKDRIVER_CPU="125m" \
      METRICSPROXY_STACKDRIVER_MEM="64Mi" \
      METRICSPROXY_PROMETHEUS_AGG_CPU="125m" \
      METRICSPROXY_PROMETHEUS_AGG_MEM="64Mi" \
      METRICSADPTR_PROMETHEUS_AGG_CPU="50m" \
      METRICSADPTR_PROMETHEUS_AGG_MEM="64Mi"
}

function moveResourcesSpecsToHybridInstall() {
  
  if [[ -z $VM_HOST ]]; then # For non-gcp instance
      cp -R "${WORK_DIR}/overlays/apigee-controller/googleDefaultCreds" \
        "$HYBRID_INSTALL_DIR/overlays/controllers/apigee-controller/components"    
  fi

  cp -R "${WORK_DIR}/overlays/datastore/cassandra-resources" \
        "$HYBRID_INSTALL_DIR/overlays/instances/instance1/datastore/components"

  cp -R "${WORK_DIR}/overlays/environments/runtime-resources" \
        "$HYBRID_INSTALL_DIR/overlays/instances/instance1/environments/test/components"

  cp -R "${WORK_DIR}/overlays/environments/synchronizer-resources" \
        "$HYBRID_INSTALL_DIR/overlays/instances/instance1/environments/test/components"

  cp -R "${WORK_DIR}/overlays/environments/udca-resources" \
        "$HYBRID_INSTALL_DIR/overlays/instances/instance1/environments/test/components"

  cp -R "${WORK_DIR}/overlays/organization/connect-resources" \
        "$HYBRID_INSTALL_DIR/overlays/instances/instance1/organization/components"

  cp -R "${WORK_DIR}/overlays/organization/ingressgateway-resources" \
        "$HYBRID_INSTALL_DIR/overlays/instances/instance1/organization/components"

  cp -R "${WORK_DIR}/overlays/organization/mart-resources" \
        "$HYBRID_INSTALL_DIR/overlays/instances/instance1/organization/components"

  cp -R "${WORK_DIR}/overlays/organization/watcher-resources" \
        "$HYBRID_INSTALL_DIR/overlays/instances/instance1/organization/components"

  cp -R "${WORK_DIR}/overlays/redis/redis-resources" \
        "$HYBRID_INSTALL_DIR/overlays/instances/instance1/redis/components"

  cp -R "${WORK_DIR}/overlays/redis/redisenvoy-resources" \
        "$HYBRID_INSTALL_DIR/overlays/instances/instance1/redis/components"

  cp -R "${WORK_DIR}/overlays/telemetry/telemetry-resources" \
        "$HYBRID_INSTALL_DIR/overlays/instances/instance1/telemetry/components"
        
}
