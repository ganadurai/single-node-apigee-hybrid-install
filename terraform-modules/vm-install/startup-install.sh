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

function installGitTool() {  
  sudo apt update
  sudo apt-get install git -y
}

function fetchSingleNodeInstall() {
  sudo mkdir /opt/install
  sudo chmod 777 -R /opt/install
  cd /opt/install
  git clone https://github.com/ganadurai/single-node-apigee-hybrid-install.git
  cd single-node-apigee-hybrid-install
  git switch terraform-vm
  WORK_DIR=$(pwd);export WORK_DIR
  sudo chmod 777 -R "$WORK_DIR"
}

function prepEnvVarsFile() {
  touch "$WORK_DIR"/initvars.sh
  {
    echo "#!/bin/bash"
    echo ""
    echo "set -e"
    echo ""
    echo "export APIGEE_NAMESPACE=${VAR_APIGEE_NAMESPACE}"
    echo "export ENV_NAME=${VAR_ENV_NAME}"
    echo "export ENV_GROUP=${VAR_ENV_GROUP}"
    echo "export DOMAIN=${VAR_DOMAIN}"
    echo "export REGION=${VAR_REGION}"
    echo ""
    echo "export PROJECT_ID=${VAR_PROJECT_ID}"
    echo "export ORG_NAME=${VAR_ORG_NAME}"
    echo "export CLUSTER_NAME=${VAR_CLUSTER_NAME}"
  } >> "$WORK_DIR"/initvars.sh
  chmod +x "$WORK_DIR"/initvars.sh
}

function setEnvVariables() {
  {
    echo "export APIGEE_NAMESPACE=${VAR_APIGEE_NAMESPACE}"
    echo "export ENV_NAME=${VAR_ENV_NAME}"
    echo "export ENV_GROUP=${VAR_ENV_GROUP}"
    echo "export DOMAIN=${VAR_DOMAIN}"
    echo "export REGION=${VAR_REGION}"
    echo ""
    echo "export PROJECT_ID=${VAR_PROJECT_ID}"
    echo "export ORG_ADMIN=${VAR_ORG_ADMIN}"
    echo "export ORG_NAME=${VAR_ORG_NAME}"
    echo "export CLUSTER_NAME=${VAR_CLUSTER_NAME}"
    echo "export WORK_DIR=$WORK_DIR"
  } >> /etc/profile
}

function installDocker() {
  sudo apt-get update
  sudo apt install --yes apt-transport-https ca-certificates curl gnupg2 software-properties-common
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
  echo "Waiting for 10s..."
  sleep 10
  sudo apt-get update
  sudo apt install --yes docker-ce
  sudo usermod -aG docker "$(echo ${VAR_ORG_ADMIN} | tr . "_" | tr "@" "_")"
}

echo "Step- Install the needed tools/libraries";
installGitTool;

echo "Step- Fetch SingleNode Install Repo";
fetchSingleNodeInstall

echo "Step- Set Env Variables";
setEnvVariables

echo "Step- Docker Installation";
installDocker;


#echo "Step- Prep vars file";
#prepEnvVarsFile

#echo "Step- Launch install-core"
#"$WORK_DIR"/scripts/install-core.sh


