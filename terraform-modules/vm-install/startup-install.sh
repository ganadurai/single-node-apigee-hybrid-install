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

function initVars() {
  # The VAR_* variables are either set via terraform variables set in main.tf, or export variables in the OS 
  APIGEE_NAMESPACE=${VAR_APIGEE_NAMESPACE}; export APIGEE_NAMESPACE;
  ENV_NAME=${VAR_ENV_NAME}; export ENV_NAME;
  ENV_GROUP=${VAR_ENV_GROUP}; export ENV_GROUP;
  DOMAIN=${VAR_DOMAIN}; export DOMAIN;
  REGION=${VAR_REGION}; export REGION;

  PROJECT_ID=${VAR_PROJECT_ID}; export PROJECT_ID;
  ORG_NAME=${VAR_ORG_NAME}; export ORG_NAME;
  CLUSTER_NAME=${VAR_CLUSTER_NAME}; export CLUSTER_NAME;
  TOKEN=${VAR_TOKEN}; export TOKEN;
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

  alias k=kubectl
  alias ksn='kubectl config set-context --current'
  alias ka='kubectl -n apigee'
  alias ka-ssh='ka exec --stdin --tty'
  alias ke='kubectl -n envoy-ns'
  alias ke-ssh='ke exec --stdin --tty'
}

function fetchSingleNodeInstall() {
  sudo mkdir /opt/install
  sudo chmod 777 -R /opt/install
  cd /opt/install
  git clone https://github.com/ganadurai/single-node-apigee-hybrid-install.git
  cd single-node-apigee-hybrid-install
  git switch single-click-install
  WORK_DIR=$(pwd);export WORK_DIR
  cd "$WORK_DIR"/scripts
}
  
echo "Step- Initvars";
initVars;

echo "Step- Install the needed tools/libraries";
installTools;

echo "Step- Fetch SingleNode Install Repo";
fetchSingleNodeInstall

echo "Step- Launch install-core"
"$WORK_DIR"/scripts/install-core.sh
