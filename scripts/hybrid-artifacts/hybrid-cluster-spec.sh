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

function createOverrides4Hybrid() {
  cat <<EOF > "$HYBRID_FILES/overrides/overrides.yaml"
gcp:
  region: $AX_REGION
  projectID: $PROJECT_ID

org: $ORG_NAME

k8sCluster:
  name: $CLUSTER_NAME
  region: $CLUSTER_LOCATION # Must be the closest Google Cloud region to your cluster.

instanceID: "$UNIQUE_INSTANCE_IDENTIFIER"

virtualhosts:
- name: $ENV_GROUP
  selector:
    app: apigee-ingressgateway
    ingress_name: $ENV_GROUP-ingrs
  sslCertPath: $HYBRID_FILES/certs/keystore_$ENV_GROUP.pem
  sslKeyPath: $HYBRID_FILES/certs/keystore_$ENV_GROUP.key

ao:
  resources:
    limits:
      cpu: 150m
      memory: 128Mi
    requests:
      cpu: 100m
      memory: 128Mi
  args:
  # This configuration is introduced in hybrid v1.8
    disableIstioConfigInAPIServer: true

# This configuration is introduced in hybrid v1.8
ingressGateways:
- name: $ENV_GROUP-ingrs # maximum 17 characters. See Known issue 243167389.
  replicaCountMin: 1
  replicaCountMax: 1
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 75m
      memory: 128Mi
manager:
  replicaCountMin: 1
  replicaCountMax: 1
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 75m
      memory: 128Mi

envs:
- name: $ENV_NAME
  serviceAccountPaths:
    synchronizer: $HYBRID_FILES/service-accounts/$PROJECT_ID-apigee-non-prod.json
    udca: $HYBRID_FILES/service-accounts/$PROJECT_ID-apigee-non-prod.json
    runtime: $HYBRID_FILES/service-accounts/$PROJECT_ID-apigee-non-prod.json

cassandra:
  hostNetwork: false
  resources:
    requests:
      cpu: 100m
      memory: 512Mi

mart:
  replicaCountMin: 1
  replicaCountMax: 1
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
  serviceAccountPath: $HYBRID_FILES/service-accounts/$PROJECT_ID-apigee-non-prod.json

synchronizer:
  replicaCountMin: 1
  replicaCountMax: 1
  resources:
    requests:
      cpu: 100m
      memory: 256Mi

runtime:
  replicaCountMin: 1
  replicaCountMax: 1
  resources:
    requests:
      cpu: 100m
      memory: 256Mi

redis:
  replicaCount: 1
  resources:
    requests:
      cpu: 50m
  envoy:
    resources:
      limits:
        cpu: 200m
      requests:
        cpu: 50m

fluentd:
  resources:
    limits:
      memory: 128Mi
    requests:
      cpu: 100m
      memory: 128Mi

connectAgent:
  replicaCount: 1
  resources:
    limits:
      cpu: 150m
      memory: 128Mi
    requests:
      cpu: 100m
      memory: 128Mi
  serviceAccountPath: $HYBRID_FILES/service-accounts/$PROJECT_ID-apigee-non-prod.json

metrics:
  serviceAccountPath: $HYBRID_FILES/service-accounts/$PROJECT_ID-apigee-non-prod.json
  aggregator:
    resources:
      limits:
        cpu: 200m
        memory: 128Mi
      requests:
        cpu: 50m
        memory: 128Mi
  app:
    resources:
      limits:
        cpu: 200m
        memory: 128Mi
      requests:
        cpu: 50m
        memory: 128Mi
  appStackdriverExporter:
    resources:
      limits:
        cpu: 200m
        memory: 128Mi
      requests:
        cpu: 50m
        memory: 128Mi
  proxy:
    resources:
      limits:
        cpu: 200m
        memory: 128Mi
      requests:
        cpu: 50m
        memory: 128Mi
  proxyStackdriverExporter:
    resources:
      limits:
        cpu: 200m
        memory: 128Mi
      requests:
        cpu: 50m
        memory: 128Mi


udca:
  resources:
    limits:
      cpu: 150m
      memory: 128Mi
    requests:
      cpu: 100m
      memory: 128Mi
  replicaCountMin: 1
  replicaCountMax: 1
  fluentd:
    resources:
      limits:
        cpu: 100m
        memory: 128Mi
      requests:
        cpu: 50m
        memory: 128Mi
  serviceAccountPath: $HYBRID_FILES/service-accounts/$PROJECT_ID-apigee-non-prod.json

watcher:
  serviceAccountPath: $HYBRID_FILES/service-accounts/$PROJECT_ID-apigee-non-prod.json

logger:
  enabled: false
  serviceAccountPath: $HYBRID_FILES/service-accounts/$PROJECT_ID-apigee-non-prod.json

EOF

}