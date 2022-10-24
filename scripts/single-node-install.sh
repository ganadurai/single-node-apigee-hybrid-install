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

function dockerInstall() {
  sudo apt update;
  sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
  apt-cache policy docker-ce
  sudo apt install docker-ce -y
  sudo systemctl status docker
  sudo usermod -aG docker "${USER}"
  su - "${USER}"
}

#validate;
#fetchHybridInstall;
dockerInstall;