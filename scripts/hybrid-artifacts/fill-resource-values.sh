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
  
  export CASSANDRA_CPU="250m"
  export CASSANDRA_MEM="256Mi"
  export RUNTIME_CPU="200m"
  export RUNTIME_MEM="256Mi"
  export SYNCHRONIZER_CPU="100m"
  export SYNCHRONIZER_MEM="128Mi"
  export FLUENTD_CPU="100m"
  export FLUENTD_MEM="64Mi"
  export UDCA_CPU="100m"
  export UDCA_MEM="128Mi"
  export CONNECT_CPU="50m"
  export CONNECT_MEM="32Mi"
  export INGRESS_GTWY_CPU="150m"
  export INGRESS_GTWY_MEM="64Mi"
  export MART_CPU="100m"
  export MART_MEM="64Mi"
  export WATCHER_CPU="100m"
  export WATCHER_MEM="32Mi"
  export METRICSAPP_STACKDRIVER_CPU="150m"
  export METRICSAPP_STACKDRIVER_MEM="64Mi"
  export METRICSAPP_PROMETHEUS_CPU="150m"
  export METRICSAPP_PROMETHEUS_MEM="64Mi"
  export METRICSPROXY_PROMETHEUS_CPU="125m"
  export METRICSPROXY_PROMETHEUS_MEM="64Mi"
  export METRICSPROXY_STACKDRIVER_CPU="125m"
  export METRICSPROXY_STACKDRIVER_MEM="64Mi"
  export METRICSPROXY_PROMETHEUS_AGG_CPU="125m"
  export METRICSPROXY_PROMETHEUS_AGG_MEM="64Mi"
  export METRICSADPTR_PROMETHEUS_AGG_CPU="50m"
  export METRICSADPTR_PROMETHEUS_AGG_MEM="64Mi"

  kpt fn eval "${WORK_DIR}/overlays/" \
      --image gcr.io/kpt-fn/apply-setters:v0.2.0 -- \
      CASSANDRA_CPU=$CASSANDRA_CPU \
      CASSANDRA_MEM=$CASSANDRA_MEM \
      RUNTIME_CPU=$RUNTIME_CPU \
      RUNTIME_MEM=$RUNTIME_MEM \
      SYNCHRONIZER_CPU=$SYNCHRONIZER_CPU \
      SYNCHRONIZER_MEM=$SYNCHRONIZER_MEM \
      FLUENTD_CPU=$FLUENTD_CPU \
      FLUENTD_MEM=$FLUENTD_MEM \
      UDCA_CPU=$UDCA_CPU \
      UDCA_MEM=$UDCA_MEM \
      CONNECT_CPU=$CONNECT_CPU \
      CONNECT_MEM=$CONNECT_MEM \
      INGRESS_GTWY_CPU=$INGRESS_GTWY_CPU \
      INGRESS_GTWY_MEM=$INGRESS_GTWY_MEM \
      MART_CPU=$MART_CPU \
      MART_MEM=$MART_MEM \
      WATCHER_CPU=$WATCHER_CPU \
      WATCHER_MEM=$WATCHER_MEM \
      METRICSAPP_STACKDRIVER_CPU=$METRICSAPP_STACKDRIVER_CPU \
      METRICSAPP_STACKDRIVER_MEM=$METRICSAPP_STACKDRIVER_MEM \
      METRICSAPP_PROMETHEUS_CPU=$METRICSAPP_PROMETHEUS_CPU \
      METRICSAPP_PROMETHEUS_MEM=$METRICSAPP_PROMETHEUS_MEM \
      METRICSPROXY_PROMETHEUS_CPU=$METRICSPROXY_PROMETHEUS_CPU \
      METRICSPROXY_PROMETHEUS_MEM=$METRICSPROXY_PROMETHEUS_MEM \
      METRICSPROXY_STACKDRIVER_CPU=$METRICSPROXY_STACKDRIVER_CPU \
      METRICSPROXY_STACKDRIVER_MEM=$METRICSPROXY_STACKDRIVER_MEM \
      METRICSPROXY_PROMETHEUS_AGG_CPU=$METRICSPROXY_PROMETHEUS_AGG_CPU \
      METRICSPROXY_PROMETHEUS_AGG_MEM=$METRICSPROXY_PROMETHEUS_AGG_MEM \
      METRICSADPTR_PROMETHEUS_AGG_CPU=$METRICSADPTR_PROMETHEUS_AGG_CPU \
      METRICSADPTR_PROMETHEUS_AGG_MEM=$METRICSADPTR_PROMETHEUS_AGG_MEM
}

function moveResourcesSpecsToHybridInstall() {
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
