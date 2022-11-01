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

function insertEtcHosts() {
  if grep -q docker-registry /etc/hosts
  then
    echo "hosts entry already existing"
  else
    echo "Adding host entry in /etc/hosts file."
    sudo -- sh -c "echo 127.0.0.1       docker-registry >> /etc/hosts"; RESULT=$?
    if [ $RESULT -ne 0 ]; then
      echo "Error in adding entry '127.0.0.1       docker-registry' in /etc/hosts, add it manually and try again.."
      exit 1;
    fi
  fi
}

function startK3DCluster() {

  # Check if the docker-registry exists, if so the K3D cluster is already running
  docker_registry_port_mapping=$(docker ps -f name=docker-registry --format "{{ json . }}" | \
    jq 'select( .Status | contains("Up")) | .Ports '); export docker_registry_port_mapping
  if [[ -z "$docker_registry_port_mapping" ]]; then
    echo "Installing K3D"
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

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

function hybridPostInstallEnvoyIngressSetup() {
  cd "$WORK_DIR"/envoy

  #Extract the instance port for the docker-regitry
  docker_registry_forwarded_port=$(docker port docker-registry 5000)
  IFS=':' read -r -a array <<< "$docker_registry_forwarded_port"
  DOCKER_REGISTRY_PORT=${array[1]}; export DOCKER_REGISTRY_PORT
  echo "$DOCKER_REGISTRY_PORT"

  kubectl get namespace envoy-ns
  RESULT=$?

  if [[ $RESULT -ne 0 ]]; then
    kubectl create namespace envoy-ns
  fi

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

function hybridPostInstallEnvoyIngressValidation() {
  OUTPUT=$(curl -i localhost:30080/apigee-hybrid-helloworld -H "Host: $DOMAIN" | grep HTTP)
  printf "\n%s" "$OUTPUT"
  if [[ "$OUTPUT" == *"200"* ]]; then
    printf "\n\nSUCCESS: Hybrid is successfully installed\n\n"
  else
    printf "\n\nPlease check the logs and troubleshoot, proxy execution failed"
  fi
}

echo "Step- Validate Docker Install"
validateDockerInstall

echo "Step- Validatevars";
validateVars

echo "Step- Fetch Hybrid Install Repo";
fetchHybridInstall

echo "Step- Install the needed tools/libraries";
#installTools;

echo "Step- Update /etc/hosts";
#insertEtcHosts;

echo "Step- Start K3D cluster";
startK3DCluster;

echo "Step- Overlays prep for Install";
hybridPreInstallOverlaysPrep;

echo "Step- Hybrid Install";
certManagerAndHybridInstall;

echo "Step- Post Install";
hybridPostInstallEnvoyIngressSetup;

echo "Step- Deploy Sample Proxy For Validation"
deploySampleProxyForValidation;

echo "Step- Validation of proxy execution";
hybridPostInstallEnvoyIngressValidation;


