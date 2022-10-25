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
  if [[ -z $WORK_DIR ]]; then
      echo "Environment variable WORK_DIR is not set, please checkout README.md"
      exit 1
  fi

  if [[ -z $ORG_NAME ]]; then
    echo "Environment variable ORG_NAME is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $ENV_NAME ]]; then
    echo "Environment variable ENV_NAME is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $ENV_GROUP ]]; then
    echo "Environment variable ENV_GROUP is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $DOMAIN ]]; then
    echo "Environment variable DOMAIN is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $CLUSTER_NAME ]]; then
    echo "Environment variable CLUSTER_NAME is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $REGION ]]; then
    echo "Environment variable REGION is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $PROJECT_ID ]]; then
    echo "Environment variable PROJECT_ID is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $TOKEN ]]; then
    echo "Environment variable TOKEN is not set, please checkout README.md"
    exit 1
  fi
}

function gitClone() { #This is the manual step, should include in README doc.
  sudo apt update
  sudo apt-get install git -y
  git clone https://github.com/ganadurai/single-node-apigee-hybrid-install.git
  cd single-node-apigee-hybrid-install
  git switch single-click-install
  WORK_DIR=$(pwd);export WORK_DIR
  cd "$WORK_DIR"/scripts
}

function fetchHybridInstall() {
  git clone https://github.com/apigee/apigee-hybrid-install.git
  cd apigee-hybrid-install
  HYBRID_INSTALL_DIR=$(pwd); export HYBRID_INSTALL_DIR
}

function installTools() {
  sudo apt update
  sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y
  sudo apt-get install jq -y
  sudo apt-get install google-cloud-sdk-kpt -y

  sudo apt-get install kubectl -y
  sudo apt-get install wget -y

  sudo wget https://github.com/mikefarah/yq/releases/download/v4.28.2/yq_linux_amd64.tar.gz -O - | \
  tar xz && sudo mv yq_linux_amd64 /usr/bin/yq

  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
}

function installDocker() {
  sudo apt-get update

  sudo apt install --yes apt-transport-https ca-certificates curl gnupg2 software-properties-common

  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

  sudo add-apt-repository "deb [arch=amd64] 
  https://download.docker.com/linux/debian $(lsb_release -cs) stable"

  sleep 20

  sudo apt-get update

  sudo apt install --yes docker-ce

  # https://thatlinuxbox.com/blog/article.php/access-docker-after-install-without-logout
  USERNAME=$(whoami)
  sudo gpasswd -a "$USERNAME" docker
  sudo grpconv
  newgrp docker

  docker images
}

function insertEtcHosts() {
  echo "127.0.0.1       docker-registry" >> /etc/hosts
}

function startK3DCluster() {

  k3d cluster create -p "443:443" -p "10256:10256" -p "30080:30080" hybrid-cluster --registry-create docker-registry 

  docker_registry_port_mapping=$(docker ps -f name=docker-registry --format "{{ json . }}" | \
  jq 'select( .Status | contains("Up")) | .Ports '); export docker_registry_port_mapping
  if [[ -z $docker_registry_port_mapping ]]; then
    echo "Successfully started K3D cluster"
  else
    echo "Error in starting the K3D cluster";
    exit 1;
  fi

  #Setting kubeconfig context
  KUBECONFIG=$(k3d kubeconfig write hybrid-cluster); export KUBECONFIG
  
  kubectl get nodes
  RESULT=$?
  if [ $RESULT -ne 0 ]; then
    echo "Kubeconfig not properly set, please verify the K3D cluster is up and running."
    exit 1
  fi
}

function hybridPreInstallOverlaysPrep() {
  echo "Filling in resource values"
  fillResourceValues;
  echo "Moving resource overlays into Hybrid install source"
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
}

function hybridInstall() {
  cd "$HYBRID_INSTALL_DIR"
  kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.7.2/cert-manager.yaml

  echo "ORG_NAME=$ORG_NAME"
  echo "ENV_NAME=$ENV_NAME"
  echo "ENV_GROUP=$ENV_GROUP"
  echo "DOMAIN=$DOMAIN"
  echo "CLUSTER_NAME=$CLUSTER_NAME"
  echo "REGION=$REGION"
  echo "PROJECT_ID=$PROJECT_ID" 
  
  "$HYBRID_INSTALL_DIR"/tools/apigee-hybrid-setup.sh \
  --org "$ORG_NAME" --env "$ENV_NAME" --envgroup "$ENV_GROUP" \
  --ingress-domain "$DOMAIN" --cluster-name "$CLUSTER_NAME" \
  --cluster-region "$REGION" --gcp-project-id "$PROJECT_ID" \
  --setup-all --verbose 

  kubectl wait "apigeedatastore/default" \
    "apigeeredis/default" \
    "apigeeenvironment/${ORGANIZATION_NAME}-${ENVIRONMENT_NAME}" \
    "apigeeorganization/${ORGANIZATION_NAME}" \
    "apigeetelemetry/apigee-telemetry" \
    -n "${APIGEE_NAMESPACE}" --for="jsonpath=.status.state=running" --timeout=5s
  exit_code=$?
  if (( "$exit_code" == 0 )); then
    echo "Hybrid successfully deployed"
  else
    echo "Hybrid not successfully deployed... Check on the pod status in the ${APIGEE_NAMESPACE} namespace"
    exit 1;
  fi
}

function hybridPostInstallEnvoyIngress() {
  cd "$WORK_DIR"/envoy

  #Extract the instance port for the docker-regitry
  docker_registry_forwarded_port=$(docker port docker-registry 5000)
  IFS=':' read -r -a array <<< "$docker_registry_forwarded_port"
  DOCKER_REGISTRY_PORT=${array[1]}; export DOCKER_REGISTRY_PORT
  echo "$DOCKER_REGISTRY_PORT"

  kubectl create namespace envoy-ns

  #Build and Push the images
  docker build -t \
  localhost:"$DOCKER_REGISTRY_PORT"/apigee-hybrid/single-node/envoy-proxy:v1 .

  docker push \
  localhost:"$DOCKER_REGISTRY_PORT"/apigee-hybrid/single-node/envoy-proxy:v1

  SERVICE_NAME=$(kubectl get svc -n "${APIGEE_NAMESPACE}" -l env=eval,app=apigee-runtime --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
  
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
}

function hybridPostInstallValidation() {
  export MGMT_HOST="https://apigee.googleapis.com"
  curl -X POST "$MGMT_HOST/v1/organizations/$ORG_NAME/apis?action=import&name=apigee-hybrid-helloworld" \
        -H "Authorization: Bearer $TOKEN" --form file=@"$WORK_DIR/apigee-hybrid-helloworld.zip"
  
  curl localhost:30080/apigee-hybrid-helloworld -H "Host: $DOMAIN"
}

validate;
fetchHybridInstall;
installTools;
installDocker;
insertEtcHosts;
startK3DCluster;
hybridPreInstallOverlaysPrep;
hybridInstall;
hybridPostInstallEnvoyIngressSetup;
hybridPostInstallValidation;