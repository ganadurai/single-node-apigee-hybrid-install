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

function installDeleteNetwork() {
  cd "$WORK_DIR"/terraform-modules/network-install

  if [[ -z $SUB_NETWORK_NAME_IP_CIDR_RANGE ]]; then
    SUB_NETWORK_NAME_IP_CIDR_RANGE="10.0.0.0/24"; export SUB_NETWORK_NAME_IP_CIDR_RANGE;
  fi
  if [[ -z $SUB_NETWORK_SECONDARY_PODS ]]; then
    SUB_NETWORK_SECONDARY_PODS="10.100.0.0/20"; export SUB_NETWORK_SECONDARY_PODS;
  fi
  if [[ -z $SUB_NETWORK_SECONDARY_SRVICES ]]; then
    SUB_NETWORK_SECONDARY_SRVICES="10.101.0.0/23"; export SUB_NETWORK_SECONDARY_SRVICES;
  fi

  last_project_id=$(cat install-state.txt)
  if [ "$last_project_id" != "$PROJECT_ID" ]; then
    echo "Clearing up the terraform state"
    rm -Rf .terraform*
    rm -f terraform.tfstate
  fi

  envsubst < "$WORK_DIR/terraform-modules/network-install/network.tfvars.tmpl" > \
    "$WORK_DIR/terraform-modules/network-install/network.tfvars"

  echo "$PROJECT_ID" > install-state.txt

  terraform init
  terraform plan \
    --var-file="$WORK_DIR/terraform-modules/network-install/network.tfvars"
  terraform "$1" -auto-approve \
    --var-file="$WORK_DIR/terraform-modules/network-install/network.tfvars"

}

SUB_NETWORK_NAME_IP_CIDR_RANGE="11.0.0.0/24"; export SUB_NETWORK_NAME_IP_CIDR_RANGE;
SUB_NETWORK_SECONDARY_PODS="11.100.0.0/20"; export SUB_NETWORK_SECONDARY_PODS;
SUB_NETWORK_SECONDARY_SRVICES="11.101.0.0/23"; export SUB_NETWORK_SECONDARY_SRVICES;

VPC_NETWORK_NAME="hybrid-runtime-cluster-vpc-2"; export VPC_NETWORK_NAME;
SUB_NETWORK_NAME="hybrid-runtime-cluster-vpc-subnetwork-2"; export SUB_NETWORK_NAME;


installDeleteNetwork "apply";