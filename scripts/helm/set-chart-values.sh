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

function fixHelmValues() {

    echo "Fixing helm values";

    if [[ -z $APIGEE_HELM_CHARTS_HOME ]]; then
        echo "APIGEE_HELM_CHARTS_HOME value is missing, exiting)"
        exit 1
    fi

    cd $APIGEE_HELM_CHARTS_HOME

    # apigee-datastore/values.yaml

    export CASS_DISK_SIZE="2Gi"     # 10Gi
    export CASS_CPU_REQ="100m"      # 500m      # 250m
    export CASS_MEM_REQ="256Mi"     # 1Gi       # 512Mi

    # apigee-env/values.yaml
    export SYNC_CPU_REQ="50m"       # 100m      # 100m
    export SYNC_MEM_REQ="128Mi"     # 512Mi     # 256Mi
    export SYNC_CPU_LIM="100m"      # 2000m     # 200m
    export SYNC_MEM_LIM="256Mi"     # 5Gi       # 512Mi

    export SYNC_LIVNS_TOU="5"       # 1
    export SYNC_LIVNS_INI="89"      # 15
    export SYNC_RYDNS_TOU="5"       # 1
    export SYNC_RYDNS_INI="89"      # 0

    export RUNT_CPU_REQ="150m"      # 500m
    export RUNT_MEM_REQ="256Mi"     # 512Mi
    export RUNT_CPU_LIM="200m"      # 4000m
    export RUNT_MEM_LIM="512Mi"     # 6Gi

    export RUNT_LIVNS_TOU="5"       # 5
    export RUNT_LIVNS_INI="89"      # 15
    export RUNT_RYDNS_TOU="5"       # 1
    export RUNT_RYDNS_INI="89"      # 15

    export UDCA_CPU_REQ="50m"       # 250m
    export UDCA_MEM_REQ="64Mi"      # 256Mi
    export UDCA_CPU_LIM="100m"      # 1000m
    export UDCA_MEM_LIM="128Mi"     # 2Gi

    export FLND_CPU_REQ="25m"       # 500m
    export FLND_MEM_REQ="32Mi"      # 250Mi
    export FLND_CPU_LIM="50m"       # 1000m
    export FLND_MEM_LIM="64Mi"      # 500Mi

    # apigee-ingress-manager/values.yaml
    export ISTD_CPU_REQ="50m"       # 200m
    export ISTD_MEM_REQ="64Mi"      # 512Mi
    export ISTD_CPU_LIM="100m"      # 1000m
    export ISTD_MEM_LIM="128Mi"     # 1024Mi

    export AO1_CPU_REQ="50m"        # 200m      # 200m
    export AO1_MEM_REQ="64Mi"       # 512Mi     # 128Mi
    export AO1_CPU_LIM="100m"       # 1000m     # 400m
    export AO1_MEM_LIM="128Mi"      # 1024Mi    # 256Mi

    export KRPX1_CPU_REQ="5m"       # 5m
    export KRPX1_MEM_REQ="32Mi"     # 64Mi
    export KRPX1_CPU_LIM="25m"      # 500m      # 100m
    export KRPX1_MEM_LIM="64Mi"     # 128Mi

    # apigee-operator/values.yaml
    export AO2_CPU_REQ="50m"        # 200m      # 100m
    export AO2_MEM_REQ="128Mi"      # 512Mi     # 256Mi
    export AO2_CPU_LIM="100m"       # 1000m     # 200m
    export AO2_MEM_LIM="256Mi"      # 1024Mi    # 512Mi

    export KRPX2_CPU_REQ="5m"       # 5m
    export KRPX2_MEM_REQ="32Mi"     # 64Mi
    export KRPX2_CPU_LIM="100m"     # 500m
    export KRPX2_MEM_LIM="64Mi"     # 128Mi

    # apigee-org/values.yaml
    export TSKS_CPU_REQ="50m"       # 500m
    export TSKS_MEM_REQ="64Mi"      # 512Mi
    export TSKS_CPU_LIM="100m"      # 2000m
    export TSKS_MEM_LIM="128Mi"     # 4Gi

    export INGS_CPU_REQ="50m"       # 300m
    export INGS_MEM_REQ="64Mi"      # 128Mi
    export INGS_CPU_LIM="100m"      # 2000m
    export INGS_MEM_LIM="128Mi"     # 1Gi
    
    export MART_CPU_REQ="100m"      # 500m      # 200m
    export MART_MEM_REQ="128Mi"     # 512Mi     # 256Mi
    export MART_CPU_LIM="150m"      # 2000m     # 300m
    export MART_MEM_LIM="256Mi"     # 5Gi       # 512Mi

    export MART_LIVNS_TOU="3"       # 1
    export MART_LIVNS_INI="89"      # 30
    export MART_RYDNS_TOU="3"       # 1
    export MART_RYDNS_INI="89"      # 15
    
    export CONA_CPU_REQ="50m"       # 200m
    export CONA_MEM_REQ="32Mi"      # 128Mi
    export CONA_CPU_LIM="100m"      # 500m
    export CONA_MEM_LIM="64Mi"      # 512Mi
    
    export WATC_CPU_REQ="50m"       # 200m
    export WATC_MEM_REQ="64Mi"      # 128Mi
    export WATC_CPU_LIM="100m"      # 1000m
    export WATC_MEM_LIM="128Mi"     # 2Gi

    export UDCA1_CPU_REQ="50m"      # 250m
    export UDCA1_MEM_REQ="64Mi"     # 256Mi
    export UDCA1_CPU_LIM="100m"     # 1000m
    export UDCA1_MEM_LIM="128Mi"    # 2Gi

    export FLND1_CPU_REQ="50m"      # 500m
    export FLND1_MEM_REQ="64Mi"     # 250Mi
    #export FLND1_CPU_LIM="100m"    # 
    export FLND1_MEM_LIM="128Mi"    # 500Mi

    # apigee-redis/values.yaml
    export REDS_CPU_REQ="100m"      # 500m
    export ENVY_CPU_REQ="100m"      # 500m

    # apigee-telemetry/values.yaml
    export LOGR_CPU_REQ="25m"       # 100m      # 50m
    export LOGR_MEM_REQ="100Mi"     # 250Mi
    export LOGR_CPU_LIM="50m"       # 200m      # 100m
    export LOGR_MEM_LIM="200Mi"     # 500Mi

    export MTRC_CPU_REQ="50m"       # 128m      # 100m
    export MTRC_MEM_REQ="64Mi"      # 512Mi
    export MTRC_CPU_LIM="75m"       # 500m      # 150m
    export MTRC_MEM_LIM="128Mi"     # 1Gi

    export SDRV_CPU_REQ="50m"       # 128m      # 100m
    export SDRV_MEM_REQ="64Mi"      # 512Mi
    export SDRV_CPU_LIM="75m"       # 500m      # 150m
    export SDRV_MEM_LIM="128Mi"     # 1Gi

    # apigee-datastore/values.yaml
    yq e -i '.nodeSelector.apigeeData.value = "apigee-runtime"' $APIGEE_HELM_CHARTS_HOME/apigee-datastore/values.yaml

    yq e -i '.cassandra.storage.storageSize = env(CASS_DISK_SIZE) | .cassandra.storage.storageSize style=""' $APIGEE_HELM_CHARTS_HOME/apigee-datastore/values.yaml
    yq e -i '.cassandra.resources.requests.cpu = env(CASS_CPU_REQ) | .cassandra.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-datastore/values.yaml
    yq e -i '.cassandra.resources.requests.memory = env(CASS_MEM_REQ) | .cassandra.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-datastore/values.yaml
    
    # apigee-env/values.yaml
    yq e -i '.nodeSelector.apigeeData.value = "apigee-runtime"' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml

    yq e -i '.synchronizer.resources.requests.cpu = env(SYNC_CPU_REQ) | .synchronizer.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.synchronizer.resources.requests.memory = env(SYNC_MEM_REQ) | .synchronizer.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.synchronizer.resources.limits.cpu = env(SYNC_CPU_LIM) | .synchronizer.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.synchronizer.resources.limits.memory = env(SYNC_MEM_LIM) | .synchronizer.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    
    yq e -i '.runtime.resources.requests.cpu = env(RUNT_CPU_REQ) | .runtime.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.runtime.resources.requests.memory = env(RUNT_MEM_REQ) | .runtime.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.runtime.resources.limits.cpu = env(RUNT_CPU_LIM) | .runtime.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.runtime.resources.limits.memory = env(RUNT_MEM_LIM) | .runtime.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    
    yq e -i '.udca.resources.requests.cpu = env(UDCA_CPU_REQ) | .udca.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.udca.resources.requests.memory = env(UDCA_MEM_REQ) | .udca.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.udca.resources.limits.cpu = env(UDCA_CPU_LIM) | .udca.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.udca.resources.limits.memory = env(UDCA_MEM_LIM) | .udca.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    
    yq e -i '.udca.fluentd.resources.requests.cpu = env(FLND_CPU_REQ) | .udca.fluentd.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.udca.fluentd.resources.requests.memory = env(FLND_MEM_REQ) | .udca.fluentd.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.udca.fluentd.resources.limits.cpu = env(FLND_CPU_LIM) | .udca.fluentd.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.udca.fluentd.resources.limits.memory = env(FLND_MEM_LIM) | .udca.fluentd.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    
    yq e -i '.synchronizer.livenessProbe.timeoutSeconds = env(SYNC_LIVNS_TOU) | .synchronizer.livenessProbe.timeoutSeconds style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.synchronizer.livenessProbe.initialDelaySeconds = env(SYNC_LIVNS_INI) | .synchronizer.livenessProbe.initialDelaySeconds style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.synchronizer.readinessProbe.timeoutSeconds = env(SYNC_RYDNS_TOU) | .synchronizer.readinessProbe.timeoutSeconds style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.synchronizer.readinessProbe.initialDelaySeconds = env(SYNC_RYDNS_INI) | .synchronizer.readinessProbe.initialDelaySeconds style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml

    yq e -i '.runtime.livenessProbe.timeoutSeconds = env(RUNT_LIVNS_TOU) | .runtime.livenessProbe.timeoutSeconds style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.runtime.livenessProbe.initialDelaySeconds = env(RUNT_LIVNS_INI) | .runtime.livenessProbe.initialDelaySeconds style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.runtime.readinessProbe.timeoutSeconds = env(RUNT_RYDNS_TOU) | .runtime.readinessProbe.timeoutSeconds style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml
    yq e -i '.runtime.readinessProbe.initialDelaySeconds = env(RUNT_RYDNS_INI) | .runtime.readinessProbe.initialDelaySeconds style=""' $APIGEE_HELM_CHARTS_HOME/apigee-env/values.yaml

    # apigee-ingress-manager/values.yaml
    yq e -i '.nodeSelector.apigeeData.value = "apigee-runtime"' $APIGEE_HELM_CHARTS_HOME/apigee-ingress-manager/values.yaml

    yq e -i '.istiod.resources.requests.cpu = env(ISTD_CPU_REQ) | .istiod.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-ingress-manager/values.yaml
    yq e -i '.istiod.resources.requests.memory = env(ISTD_MEM_REQ) | .istiod.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-ingress-manager/values.yaml
    yq e -i '.istiod.resources.limits.cpu = env(ISTD_CPU_LIM) | .istiod.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-ingress-manager/values.yaml
    yq e -i '.istiod.resources.limits.memory = env(ISTD_MEM_LIM) | .istiod.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-ingress-manager/values.yaml

    yq e -i '.ao.resources.requests.cpu = env(AO1_CPU_REQ) | .ao.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-ingress-manager/values.yaml
    yq e -i '.ao.resources.requests.memory = env(AO1_MEM_REQ) | .ao.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-ingress-manager/values.yaml
    yq e -i '.ao.resources.limits.cpu = env(AO1_CPU_LIM) | .ao.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-ingress-manager/values.yaml
    yq e -i '.ao.resources.limits.memory = env(AO1_MEM_LIM) | .ao.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-ingress-manager/values.yaml

    yq e -i '.kubeRBACProxy.resources.requests.cpu = env(KRPX1_CPU_REQ) | .kubeRBACProxy.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-ingress-manager/values.yaml
    yq e -i '.kubeRBACProxy.resources.requests.memory = env(KRPX1_MEM_REQ) | .kubeRBACProxy.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-ingress-manager/values.yaml
    yq e -i '.kubeRBACProxy.resources.limits.cpu = env(KRPX1_CPU_LIM) | .kubeRBACProxy.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-ingress-manager/values.yaml
    yq e -i '.kubeRBACProxy.resources.limits.memory = env(KRPX1_MEM_LIM) | .kubeRBACProxy.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-ingress-manager/values.yaml

    # apigee-operator/values.yaml
    yq e -i '.nodeSelector.apigeeData.value = "apigee-runtime"' $APIGEE_HELM_CHARTS_HOME/apigee-operator/values.yaml

    yq e -i '.ao.resources.requests.cpu = env(AO2_CPU_REQ) | .ao.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-operator/values.yaml
    yq e -i '.ao.resources.requests.memory = env(AO2_MEM_REQ) | .ao.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-operator/values.yaml
    yq e -i '.ao.resources.limits.cpu = env(AO2_CPU_LIM) | .ao.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-operator/values.yaml
    yq e -i '.ao.resources.limits.memory = env(AO2_MEM_LIM) | .ao.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-operator/values.yaml

    yq e -i '.kubeRBACProxy.resources.requests.cpu = env(KRPX2_CPU_REQ) | .kubeRBACProxy.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-operator/values.yaml
    yq e -i '.kubeRBACProxy.resources.requests.memory = env(KRPX2_MEM_REQ) | .kubeRBACProxy.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-operator/values.yaml
    yq e -i '.kubeRBACProxy.resources.limits.cpu = env(KRPX2_CPU_LIM) | .kubeRBACProxy.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-operator/values.yaml
    yq e -i '.kubeRBACProxy.resources.limits.memory = env(KRPX2_MEM_LIM) | .kubeRBACProxy.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-operator/values.yaml

    # apigee-org/values.yaml
    yq e -i '.nodeSelector.apigeeData.value = "apigee-runtime"' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml

    yq e -i '.mintTaskScheduler.resources.requests.cpu = env(TSKS_CPU_REQ) | .mintTaskScheduler.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.mintTaskScheduler.resources.requests.memory = env(TSKS_MEM_REQ) | .mintTaskScheduler.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.mintTaskScheduler.resources.limits.cpu = env(TSKS_CPU_LIM) | .mintTaskScheduler.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.mintTaskScheduler.resources.limits.memory = env(TSKS_MEM_LIM) | .mintTaskScheduler.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml

    yq e -i '.apigeeIngressGateway.resources.requests.cpu = env(INGS_CPU_REQ) | .apigeeIngressGateway.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.apigeeIngressGateway.resources.requests.memory = env(INGS_MEM_REQ) | .apigeeIngressGateway.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.apigeeIngressGateway.resources.limits.cpu = env(INGS_CPU_LIM) | .apigeeIngressGateway.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.apigeeIngressGateway.resources.limits.memory = env(INGS_MEM_LIM) | .apigeeIngressGateway.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml

    yq e -i '.mart.resources.requests.cpu = env(MART_CPU_REQ) | .mart.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.mart.resources.requests.memory = env(MART_MEM_REQ) | .mart.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.mart.resources.limits.cpu = env(MART_CPU_LIM) | .mart.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.mart.resources.limits.memory = env(MART_MEM_LIM) | .mart.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    
    yq e -i '.mart.livenessProbe.timeoutSeconds = env(MART_LIVNS_TOU) | .mart.livenessProbe.timeoutSeconds style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.mart.livenessProbe.initialDelaySeconds = env(MART_LIVNS_INI) | .mart.livenessProbe.initialDelaySeconds style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.mart.readinessProbe.timeoutSeconds = env(MART_RYDNS_TOU) | .mart.readinessProbe.timeoutSeconds style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.mart.readinessProbe.initialDelaySeconds = env(MART_RYDNS_INI) | .mart.readinessProbe.initialDelaySeconds style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml

    yq e -i '.connectAgent.resources.requests.cpu = env(CONA_CPU_REQ) | .connectAgent.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.connectAgent.resources.requests.memory = env(CONA_MEM_REQ) | .connectAgent.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.connectAgent.resources.limits.cpu = env(CONA_CPU_LIM) | .connectAgent.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.connectAgent.resources.limits.memory = env(CONA_MEM_LIM) | .connectAgent.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml

    yq e -i '.watcher.resources.requests.cpu = env(WATC_CPU_REQ) | .watcher.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.watcher.resources.requests.memory = env(WATC_MEM_REQ) | .watcher.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.watcher.resources.limits.cpu = env(WATC_CPU_LIM) | .watcher.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.watcher.resources.limits.memory = env(WATC_MEM_LIM) | .watcher.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml

    yq e -i '.udca.resources.requests.cpu = env(UDCA1_CPU_REQ) | .udca.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.udca.resources.requests.memory = env(UDCA1_MEM_REQ) | .udca.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.udca.resources.limits.cpu = env(UDCA1_CPU_LIM) | .udca.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.udca.resources.limits.memory = env(UDCA1_MEM_LIM) | .udca.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml

    yq e -i '.udca.fluentd.resources.requests.cpu = env(FLND1_CPU_REQ) | .udca.fluentd.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.udca.fluentd.resources.requests.memory = env(FLND1_MEM_REQ) | .udca.fluentd.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    # yq e -i '.udca.fluentd.resources.limits.cpu = env(FLND1_CPU_LIM) | .udca.fluentd.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml
    yq e -i '.udca.fluentd.resources.limits.memory = env(FLND1_MEM_LIM) | .udca.fluentd.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-org/values.yaml

    # apigee-redis/values.yaml
    yq e -i '.nodeSelector.apigeeData.value = "apigee-runtime"' $APIGEE_HELM_CHARTS_HOME/apigee-datastore/values.yaml
    
    yq e -i '.redis.resources.requests.cpu = env(REDS_CPU_REQ) | .redis.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-redis/values.yaml
    yq e -i '.redis.envoy.resources.requests.cpu = env(ENVY_CPU_REQ) | .redis.envoy.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-redis/values.yaml

    # apigee-telemetry/values.yaml
    yq e -i '.nodeSelector.apigeeData.value = "apigee-runtime"' $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/values.yaml

    yq e -i '.logger.resources.requests.cpu = env(LOGR_CPU_REQ) | .logger.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/values.yaml
    yq e -i '.logger.resources.requests.memory = env(LOGR_MEM_REQ) | .logger.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/values.yaml
    yq e -i '.logger.resources.limits.cpu = env(LOGR_CPU_LIM) | .logger.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/values.yaml
    yq e -i '.logger.resources.limits.memory = env(LOGR_MEM_LIM) | .logger.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/values.yaml

    yq e -i '.metrics.appStackdriverExporter.resources.requests.cpu = env(MTRC_CPU_REQ) | .metrics.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/values.yaml
    yq e -i '.metrics.appStackdriverExporter.resources.requests.memory = env(MTRC_MEM_REQ) | .metrics.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/values.yaml
    yq e -i '.metrics.appStackdriverExporter.resources.limits.cpu = env(MTRC_CPU_LIM) | .metrics.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/values.yaml
    yq e -i '.metrics.appStackdriverExporter.resources.limits.memory = env(MTRC_MEM_LIM) | .metrics.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/values.yaml

    yq e -i '.metrics.proxyStackdriverExporter.resources.requests.cpu = env(SDRV_CPU_REQ) | .metrics.proxyStackdriverExporter.resources.requests.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/values.yaml
    yq e -i '.metrics.proxyStackdriverExporter.resources.requests.memory = env(SDRV_MEM_REQ) | .metrics.proxyStackdriverExporter.resources.requests.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/values.yaml
    yq e -i '.metrics.proxyStackdriverExporter.resources.limits.cpu = env(SDRV_CPU_LIM) | .metrics.proxyStackdriverExporter.resources.limits.cpu style=""' $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/values.yaml
    yq e -i '.metrics.proxyStackdriverExporter.resources.limits.memory = env(SDRV_MEM_LIM) | .metrics.proxyStackdriverExporter.resources.limits.memory style=""' $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/values.yaml
}

# For testing
# cd /Users/akila/Developer/Google/Apigee/Hybrid/install/APIGEE_HYBRID_BASE/TEST_APIGEE_HELM_CHARTS_HOME
# export APIGEE_HELM_CHARTS_HOME=$PWD
# fixHelmValues;
