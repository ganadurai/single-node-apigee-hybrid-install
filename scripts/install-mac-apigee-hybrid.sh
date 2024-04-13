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
source ./install-functions.sh
source ./helm/install-hybrid-helm-functions.sh

source ./helm/set-overrides.sh
source ./helm/install-crds-cert-mgr.sh
source ./helm/set-chart-values.sh
source ./helm/execute-charts.sh

function installTools() {  
    brew install yq
    brew install jq
    brew install wget
    brew install ca-certificates
    brew install gnupg2
    # brew install software-properties-common

    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
}

function installCluster() {
    k3d cluster create -p "443:443" -p "30080:30080" $CLUSTER_NAME --registry-create docker-registry
    K3D_NODE=$(kubectl get nodes -o json | jq '.items[0].metadata.name' | cut -d '"' -f 2)
    kubectl label nodes $K3D_NODE cloud.google.com/gke-nodepool=apigee-runtime

    kubectl create namespace apigee
}

function deleteCluster() {
    k3d cluster delete $CLUSTER_NAME;
}

function logIntoCluster() {
  docker_registry_port_mapping=$(docker ps -f name=docker-registry --format "{{ json . }}" | \
  jq 'select( .Status | contains("Up")) | .Ports '); export docker_registry_port_mapping
  if [[ -z $docker_registry_port_mapping ]]; then
    echo "Error in starting the K3D cluster on the instance";
    exit 1;
  else
    echo "K3D cluster running, logging in..."
    KUBECONFIG=$(k3d kubeconfig write hybrid-cluster); export KUBECONFIG
  fi
}

function prepInstallDirs() {

    if [ ! -d "$APIGEE_HYBRID_BASE" ]; then
        mkdir $APIGEE_HYBRID_BASE
    fi

    if [ ! -d "$APIGEE_HELM_CHARTS_HOME_ORIG" ]; then
        mkdir $APIGEE_HELM_CHARTS_HOME_ORIG
        cd $APIGEE_HELM_CHARTS_HOME_ORIG 
        export CHART_REPO=oci://us-docker.pkg.dev/apigee-release/apigee-hybrid-helm-charts
        export CHART_VERSION=1.11.1
        helm pull $CHART_REPO/apigee-operator --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-datastore --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-env --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-ingress-manager --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-org --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-redis --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-telemetry --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-virtualhost --version $CHART_VERSION --untar
    fi

    if [ ! -d "$APIGEE_HELM_CHARTS_HOME" ]; then
        mkdir $APIGEE_HELM_CHARTS_HOME
        cd $APIGEE_HELM_CHARTS_HOME
        export CHART_REPO=oci://us-docker.pkg.dev/apigee-release/apigee-hybrid-helm-charts
        export CHART_VERSION=1.11.1
        helm pull $CHART_REPO/apigee-operator --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-datastore --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-env --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-ingress-manager --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-org --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-redis --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-telemetry --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-virtualhost --version $CHART_VERSION --untar
    fi
}

function hybridPostInstallIngressGatewaySetup() {
  
  export SERVICE_NAME=$ENV_NAME-ingrs-svc
  export ENV_GROUP_INGRESS=$INGRESS_NAME
  
  envsubst < "$WORK_DIR/scripts/gke-artifacts/apigee-ingress-svc.tmpl" > \
    "$WORK_DIR/scripts/gke-artifacts/apigee-ingress-svc.yaml"

  kubectl apply -f "$WORK_DIR/scripts/gke-artifacts/apigee-ingress-svc.yaml"

  echo "Waiting 60s for the Load balancer deployment for the ingress ..."
  sleep 60

  kubectl get svc -n apigee -l app=apigee-ingressgateway
  
  export INGRESS_IP_ADDRESS=$(kubectl -n apigee get svc -l app=apigee-ingressgateway -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
  
  curl -H 'User-Agent: GoogleHC/' "https://$DOMAIN/healthz/ingress" -k \
    --resolve "$DOMAIN:443:$INGRESS_IP_ADDRESS"

}

function hybridPostInstallIngressGatewayValidation() {

  OUTPUT=$(curl -s "https://$DOMAIN/apigee-hybrid-helloworld" \
                --resolve "$DOMAIN:443:$INGRESS_IP_ADDRESS" -k -i | grep HTTP); export OUTPUT
  echo "$OUTPUT"
  if [[ "$OUTPUT" == *"200"* ]]; then
    printf "\n\nSUCCESS: Hybrid is successfully installed\n\n"
    echo ""
    echo "Test the deployed sample proxy:"
    echo curl -s \"https://$DOMAIN/apigee-hybrid-helloworld\" --resolve \"$DOMAIN:443:$INGRESS_IP_ADDRESS\" -k -i
    echo "";echo "";
  else
    printf "\n\nPlease check the logs and troubleshoot, proxy execution failed"
  fi
}

function hybridPostInstallEnvoyIngressSetup() {
  cd "$WORK_DIR"/envoy

  #Extract the instance port for the docker-regitry
  docker_registry_forwarded_port=$(docker port docker-registry 5000)
  IFS=':' read -r -a array <<< "$docker_registry_forwarded_port"
  DOCKER_REGISTRY_PORT=${array[1]}; export DOCKER_REGISTRY_PORT
  echo "$DOCKER_REGISTRY_PORT"

  
  RESULT=$(kubectl get namespace | { grep envoy-ns || true; } | wc -l);
  if [[ $RESULT -eq 0 ]]; then
    kubectl create namespace envoy-ns
  fi

  #Build and Push the images
  docker build -t \
  localhost:"$DOCKER_REGISTRY_PORT"/apigee-hybrid/single-node/envoy-proxy:v1 .

  docker push \
  localhost:"$DOCKER_REGISTRY_PORT"/apigee-hybrid/single-node/envoy-proxy:v1

  SERVICE_NAME=$(kubectl get svc -n "${APIGEE_NAMESPACE}" -l env="$ENV_NAME",app=apigee-runtime --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
  export SERVICE_NAME;

  #Validate the substitutin variables
  if [[ -z $DOCKER_REGISTRY_PORT ]]; then
    echo "Instance port for the docker-regitry is not derived successfully, exiting.."
    exit 1
  fi
  if [[ -z $SERVICE_NAME ]]; then
    echo "Hybrid runtime pod's name is not derived successfully, exiting"
    exit 1
  fi
  
  envsubst < envoy-deployment.tmpl > envoy-deployment.yaml

  kubectl apply -f envoy-deployment.yaml

  echo "Waiting for envoy services to be ready...10s"
  kubectl -n envoy-ns wait --for=jsonpath='{.status.phase}'=Running pod -l app=envoy-proxy --timeout=10s

}

function hybridPostInstallEnvoyIngressValidation() {
  OUTPUT=$(curl -i localhost:30080/apigee-hybrid-helloworld -H "Host: $DOMAIN" | grep HTTP)
  printf "\n%s" "$OUTPUT"
  if [[ "$OUTPUT" == *"200"* ]]; then
    printf "\n\nSUCCESS: Hybrid is successfully installed\n\n"
    echo ""
    echo "Test the deployed sample proxy:"
    echo curl localhost:30080/apigee-hybrid-helloworld -H \"Host: $DOMAIN\" -i
    echo "";echo "";
  else
    printf "\n\nPlease check the logs and troubleshoot, proxy execution failed"
  fi
}

parse_args "${@}"

banner_info "Step- Validatevars";
validateVars

if [[ $SHOULD_CREATE_PROJECT == "1" ]]; then
  banner_info "Step- Install Project"
  DO_PROJECT_CREATE='false'; #Just enable the org policies
  installDeleteProject "apply";
fi

if [[ $SHOULD_CREATE_APIGEE_ORG == "1" ]]; then
    banner_info "Step- Install Apigee Org"
    installApigeeOrg;

    # validate the executioner has the  roles/apigee.admin
    # gcloud projects get-iam-policy ${PROJECT_ID}  \
    #    --flatten="bindings[].members" \
    #    --format='table(bindings.role)' \
    #    --filter="bindings.members:${USER_ID}" | grep apigee.admin

    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
      --member user:${USER_ID} \
      --role roles/apigee.admin

    # API to enable the required permission for Synchronizer
    #curl -s -X GET -H "Authorization: Bearer $TOKEN" \
    #    -H "Content-Type:application/json" \
    #    "https://apigee.googleapis.com/v1/organizations/${ORG_NAME}:getSyncAuthorization" \
    #    grep serviceAccount:apigee-non-prod@${PROJECT_ID}.iam.gserviceaccount.com
    
    #echo "Required permission for Synchronizer, so adding"
    #curl -s -X POST -H "Authorization: Bearer ${TOKEN}" \
    #    -H "Content-Type:application/json" \
    #    "https://apigee.googleapis.com/v1/organizations/${ORG_NAME}:setSyncAuthorization" \
    #    -d '{"identities":["'"serviceAccount:apigee-non-prod@${PROJECT_ID}.iam.gserviceaccount.com"'"]}'
           
fi

if [[ $SHOULD_INSTALL_TOOLS == "1" ]] && [[ $SHOULD_SKIP_INSTALL_TOOLS == "0" ]]; then
  banner_info "Step - Install Tools"
  installTools
fi

if [[ $SHOULD_INSTALL_CLUSTER == "1" ]] && [[ $SHOULD_SKIP_INSTALL_CLUSTER == "0" ]]; then
  banner_info "Step- Install Cluster"
  #checkAndApplyOrgconstranints;
  installCluster;
fi

if [[ $CLUSTER_ACTION == "1" ]]; then
  banner_info "Step- Log into cluster";
  logIntoCluster;
fi

if [[ $SHOULD_PREP_HYBRID_INSTALL_DIRS == "1" ]]; then
  banner_info "Step- Prepare directories";
  prepInstallDirs;
fi

if [[ $SHOULD_INSTALL_CERT_MNGR == "1" ]]; then
  banner_info "Skipped- (this is handled as part of helm installs)";
fi

if [[ $SHOULD_INSTALL_HYBRID == "1" ]]; then
  banner_info "Step- Hybrid Install";
  # install-hybrid-helm-functions.sh
  hybridInstallViaHelmCharts; 
fi

if [[ $SHOULD_INSTALL_INGRESS == "1" ]]; then
  TOKEN=$(gcloud auth print-access-token); export TOKEN;

  echo "Step- Post Install";
  hybridPostInstallEnvoyIngressSetup;

  echo "Step- Deploy Sample Proxy For Validation"
  deploySampleProxyForValidation;

  echo "Step- Validation of proxy execution";
  hybridPostInstallEnvoyIngressValidation;
fi

if [[ $SHOULD_DELETE_PROJECT == "1" ]]; then
  banner_info "Step- Delete Project"
  installDeleteProject "destroy";
  echo "Successfully deleted project, exiting"
  #https://console.cloud.google.com/networking/firewalls/list?project=$PROJECT_ID
  exit 0;
fi

if [[ $SHOULD_DELETE_CLUSTER == "1" ]]; then
  banner_info "Step- Delete Cluster"
  deleteCluster;
  echo "Successfully deleted cluster, exiting"
  exit 0;
fi

banner_info "COMPLETE"