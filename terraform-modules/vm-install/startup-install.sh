#!/bin/bash

set -e

#TODO : THis is not called, delete it. 
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

  USERANDGROUP="$(echo "${VAR_ORG_ADMIN}" | tr . "_" | tr "@" "_")"; export USERANDGROUP
}

function installTools() {  
  sudo apt update
  sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y
  sudo apt-get install git -y
  sudo apt-get install jq -y
  sudo apt-get install google-cloud-sdk-kpt -y
  sudo apt-get install kubectl -y
  sudo apt-get install wget -y

  sudo wget https://github.com/mikefarah/yq/releases/download/v4.28.2/yq_linux_amd64.tar.gz -O - | \
  tar xz && sudo mv yq_linux_amd64 /usr/bin/yq

  sudo -- sh -c "echo 127.0.0.1       docker-registry >> /etc/hosts";
}

function fetchSingleNodeInstall() {
  sudo mkdir /opt/install
  sudo chmod 777 -R /opt/install
  cd /opt/install
  git clone https://github.com/ganadurai/single-node-apigee-hybrid-install.git
  cd single-node-apigee-hybrid-install
  
  USERANDGROUP="$(echo "${VAR_ORG_ADMIN}" | tr . "_" | tr "@" "_")"; export USERANDGROUP
  sudo chown -R "$USERANDGROUP":"$USERANDGROUP" /opt/install/single-node-apigee-hybrid-install
  WORK_DIR=$(pwd);export WORK_DIR
  #sudo chmod 777 -R "$WORK_DIR"
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
  
  USERANDGROUP="$(echo "${VAR_ORG_ADMIN}" | tr . "_" | tr "@" "_")"; export USERANDGROUP
  sudo usermod -aG docker "$USERANDGROUP"
}

echo "Step- Install the needed tools/libraries";
installTools;

echo "Step- Fetch SingleNode Install Repo";
fetchSingleNodeInstall

echo "Step- Set Env Variables";
setEnvVariables

echo "Step- Docker Installation";
installDocker;


