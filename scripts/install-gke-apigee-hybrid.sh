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

function installProjectAndCluster() {
  cd "$WORK_DIR"/terraform-modules/gke-install

  envsubst < "$WORK_DIR/terraform-modules/gke-install/hybrid.tfvars.tmpl" > \
    "$WORK_DIR/terraform-modules/gke-install/hybrid.tfvars"

  terraform init
  terraform plan \
    --var-file="$WORK_DIR/terraform-modules/gke-install/hybrid.tfvars" \
    -var "project_id=$PROJECT_ID"
  terraform apply -auto-approve \
    --var-file="$WORK_DIR/terraform-modules/gke-install/hybrid.tfvars" \
    -var "project_id=$PROJECT_ID"
}

function logIntoCluster() {
  gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"
}

function hybridPostInstallIngressGatewaySetup() {
  
  export SERVICE_NAME=$ENV_NAME-ingrs-svc
  export ENV_GROUP_INGRESS=$ENV_GROUP-ingrs
  
  envsubst < "$WORK_DIR/scripts/gke-artifacts/apigee-ingress-svc.tmpl" > \
    "$WORK_DIR/scripts/gke-artifacts/apigee-ingress-svc.yaml"

  kubectl apply -f "$WORK_DIR/scripts/gke-artifacts/apigee-ingress-svc.yaml"

  echo "Waiting 60s for the Load balancer deployment for the ingress ..."
  sleep 60

  kubectl get svc -n apigee -l app=apigee-ingressgateway
  
  export INGRESS_IP_ADDRESS=$(kubectl -n apigee get svc -l app=apigee-ingressgateway -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
  
  curl -H 'User-Agent: GoogleHC/' "https://$DOMAIN/healthz/ingress" -k \
    --resolve "$DOMAIN:443:$INGRESS_IP_ADDRESS"

}

function hybridPostInstallIngressGatewayValidation() {

  OUTPUT=$(curl -s "https://$DOMAIN/apigee-hybrid-helloworld" \
                --resolve "$DOMAIN:443:$INGRESS_IP_ADDRESS" -k -i | grep HTTP); export OUTPUT
  echo "$OUTPUT"
  if [[ "$OUTPUT" == *"200"* ]]; then
    printf "\n\nSUCCESS: Hybrid is successfully installed\n\n"
  else
    printf "\n\nPlease check the logs and troubleshoot, proxy execution failed"
  fi
}

#parse_args "${@}"

echo "Step- Validatevars";
validateVars

echo "Step- Install Project and Cluster"
installProjectAndCluster;

echo "Step- Log into cluster";
logIntoCluster;

echo "Step- Overlays prep for Install";
hybridPreInstallOverlaysPrep;

echo "Step- cert manager Install";
certManagerInstall;

echo "Step- Hybrid Install";
hybridRuntimeInstall;

echo "Step- Post Install";
hybridPostInstallIngressGatewaySetup;

echo "Step- Deploy Sample Proxy For Validation"
deploySampleProxyForValidation;

echo "Step- Validation of proxy execution";
hybridPostInstallIngressGatewayValidation;

