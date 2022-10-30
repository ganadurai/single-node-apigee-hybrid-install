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
source ./hybrid-artifacts/fill-resource-values.sh
# shellcheck source=/dev/null
source ./hybrid-artifacts/add-resources-components.sh

function validateDockerInstall() {
  if [ -x "$(command -v docker)" ]; then
    echo "docker presence is validated ..."
  else
    echo "Docker is not running, install docker by running the script within the quotes './install-docker.sh; logout' and retry the hybrid install."
    exit 1;
  fi
}

function validateVars() {
  if [[ -z $WORK_DIR ]]; then
      echo "Environment variable WORK_DIR setting now..."
      WORK_DIR="$(pwd)/.."; export WORK_DIR;
      echo "WORK_DIR=$WORK_DIR"
  fi

  if [[ -z $APIGEE_NAMESPACE ]]; then
      echo "Environment variable APIGEE_NAMESPACE setting now..."
      APIGEE_NAMESPACE="apigee"; export APIGEE_NAMESPACE;
      echo "APIGEE_NAMESPACE=$APIGEE_NAMESPACE"
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

function installTools() {  
  sudo apt update
  sudo apt-get install git -y
  sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y
  sudo apt-get install jq -y
  sudo apt-get install google-cloud-sdk-kpt -y

  sudo apt-get install kubectl -y
  sudo apt-get install wget -y

  sudo wget https://github.com/mikefarah/yq/releases/download/v4.28.2/yq_linux_amd64.tar.gz -O - | \
  tar xz && sudo mv yq_linux_amd64 /usr/bin/yq

  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

  alias k=kubectl
  alias ksn='kubectl config set-context --current'
  alias ka='kubectl -n apigee'
  alias ka-ssh='ka exec --stdin --tty'
  alias ke='kubectl -n envoy-ns'
  alias ke-ssh='ke exec --stdin --tty'
}

function fetchHybridInstall() {
  if [[ -d $WORK_DIR/../apigee-hybrid-install ]]; then #if the script is re-ran, clean it and pull a fresh copy
    rm -Rf "$WORK_DIR/../apigee-hybrid-install"
  fi

  cd "$WORK_DIR/.."
  git clone https://github.com/apigee/apigee-hybrid-install.git
  HYBRID_INSTALL_DIR="$WORK_DIR/../apigee-hybrid-install"; export HYBRID_INSTALL_DIR
}

function insertEtcHosts() {
  if grep -q docker-registry /etc/hosts
  then
    echo "hosts entry already existing"
  else
    sudo -- sh -c "echo 127.0.0.1       docker-registry >> /etc/hosts"; RESULT=$?
    if [ $RESULT -ne 0 ]; then
      echo "Error in adding entry '127.0.0.1       docker-registry' in /etc/hosts, add it manually and try again.."
      exit 1;
    fi
  fi
}

function startK3DCluster() {
  docker_registry_port_mapping=$(docker ps -f name=docker-registry --format "{{ json . }}" | \
    jq 'select( .Status | contains("Up")) | .Ports '); export docker_registry_port_mapping
  if [[ -z "$docker_registry_port_mapping" ]]; then
    k3d cluster create -p "443:443" -p "10256:10256" -p "30080:30080" hybrid-cluster --registry-create docker-registry 

    docker_registry_port_mapping=$(docker ps -f name=docker-registry --format "{{ json . }}" | \
    jq 'select( .Status | contains("Up")) | .Ports '); export docker_registry_port_mapping
    if [[ -z $docker_registry_port_mapping ]]; then
      echo "Error in starting the K3D cluster on the instance";
      exit 1;
    else
      echo "Successfully started K3D cluster"
    fi
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
  date
  echo "Waiting 120s for the cert manager initialization"
  sleep 120
  date
  
  printf "\nInstalling and Setting up Hybrid containers\n"
  RESULT=0
  OUTPUT=$("$HYBRID_INSTALL_DIR"/tools/apigee-hybrid-setup.sh \
            --org "$ORG_NAME" --env "$ENV_NAME" --envgroup "$ENV_GROUP" \
            --ingress-domain "$DOMAIN" --cluster-name "$CLUSTER_NAME" \
            --cluster-region "$REGION" --gcp-project-id "$PROJECT_ID" \
            --setup-all --verbose > /tmp/hybrid-install-output.txt)
  printf "\nHybrid Install Result : %s\n" "$OUTPUT"
  if [[ "$OUTPUT" -eq 1 ]]; then
    if grep -q 'failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/validate?timeout=10s"' /tmp/hybrid-install-output.txt  
    then
      RESULT=1
    else
      RESULT=-1
    fi
  fi
  return $RESULT
}

function certManagerAndHybridInstall() {
  cd "$HYBRID_INSTALL_DIR"
  kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.7.2/cert-manager.yaml

  echo "ORG_NAME=$ORG_NAME"
  echo "ENV_NAME=$ENV_NAME"
  echo "ENV_GROUP=$ENV_GROUP"
  echo "DOMAIN=$DOMAIN"
  echo "CLUSTER_NAME=$CLUSTER_NAME"
  echo "REGION=$REGION"
  echo "PROJECT_ID=$PROJECT_ID" 
  
  sudo touch /tmp/hybrid-install-output.txt
  sudo chmod 666 /tmp/hybrid-install-output.txt
  hybridInstall;
  RESULT=$?

  counter=0;
  while [ $RESULT -eq 1 ] && [ $counter -lt 3 ]; do
    hybridInstall; #retrying to accomdate for cert-manager readiness
    RESULT=$?
    counter=$((counter+1))
  done

  if [[ $RESULT -eq -1 ]]; then
    echo "Unexpected error, checkout the logs for troubleshooting"
  fi

  kubectl wait "apigeedatastore/default" \
    "apigeeredis/default" \
    "apigeeenvironment/${ORG_NAME}-${ENV_NAME}" \
    "apigeeorganization/${ORG_NAME}" \
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

function hybridPostInstallEnvoyIngressSetup() {
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

function hybridPostInstallValidation() {
  export MGMT_HOST="https://apigee.googleapis.com"
  curl -X POST "$MGMT_HOST/v1/organizations/$ORG_NAME/apis?action=import&name=apigee-hybrid-helloworld" \
        -H "Authorization: Bearer $TOKEN" --form file=@"$WORK_DIR/apigee-hybrid-helloworld.zip"
  echo "Waiting for proxy deployment and ready for testing, 60s"
  sleep 60
  OUTPUT=$(curl -i localhost:30080/apigee-hybrid-helloworld -H "Host: $DOMAIN" | grep HTTP)
  printf "\n%s" "$OUTPUT"
  if [[ "$OUTPUT" == *"200"* ]]; then
    printf "\n\nSUCCESS: Hybrid is successfully installed\n\n"
  else
    printf "\n\nPlease check the logs and troubleshoot, proxy execution failed"
  fi
}

echo "Step- Validatevars";
validateVars

echo "Step- Fetch Hybrid Install Repo";
fetchHybridInstall

echo "Step- Install the needed tools/libraries";
installTools;

echo "Step- Update /etc/hosts";
insertEtcHosts;

echo "Step- Start K3D cluster";
startK3DCluster;

echo "Step- Overlays prep for Install";
hybridPreInstallOverlaysPrep;

echo "Step- Hybrid Install";
certManagerAndHybridInstall;

echo "Step- Post Install";
hybridPostInstallEnvoyIngressSetup;

echo "Step- Validation of proxy execution";
hybridPostInstallValidation;