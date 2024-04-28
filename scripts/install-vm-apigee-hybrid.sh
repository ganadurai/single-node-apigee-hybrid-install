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
    brew install software-properties-common

    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
}

function installK3DCluster() {

  # Check if the docker-registry exists, if so the K3D cluster is already running
  docker_registry_port_mapping=$(docker ps -f name=docker-registry --format "{{ json . }}" | \
    jq 'select( .Status | contains("Up")) | .Ports '); export docker_registry_port_mapping
  if [[ -z "$docker_registry_port_mapping" ]]; then
    echo "Installing K3D"
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    k3d cluster create -p "443:443" -p "10256:10256" -p "30080:30080" hybrid-cluster --registry-create docker-registry 
  fi
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

function logIntoK3DCluster() {
  
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

    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
      --member user:${USER_ID} \
      --role roles/apigee.admin
fi

echo "Step- Validate Docker Install"
validateDockerInstall

if [[ $SHOULD_INSTALL_CLUSTER == "1" ]] && [[ $SHOULD_SKIP_INSTALL_CLUSTER == "0" ]]; then
  banner_info "Step- Install Cluster"
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


