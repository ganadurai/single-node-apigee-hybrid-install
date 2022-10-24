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

function validate() {
    if [[ -z $HYBRID_INSTALL_DIR ]]; then
        echo "Environment variable HYBRID_INSTALL_DIR is not set, please checkout README.md"
        exit 1
    fi

    if [[ -z $WORK_DIR ]]; then
        echo "Environment variable WORK_DIR is not set, please checkout README.md"
        exit 1
    fi
}

function fetchHybridInstall() {
  git clone https://github.com/apigee/apigee-hybrid-install.git
  cd apigee-hybrid-install
  HYBRID_INSTALL_DIR=$(pwd); export HYBRID_INSTALL_DIR
}

function gitClone() {
  sudo apt update
  sudo apt-get install git -y
  git clone https://github.com/ganadurai/single-node-apigee-hybrid-install.git
  cd single-node-apigee-hybrid-install
  WORK_DIR=$(pwd);export WORK_DIR
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

function dockerInstall() {
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

#validate;
#fetchHybridInstall;
installTools;
dockerInstall;