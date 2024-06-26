#!/bin/bash

set -e

# shellcheck source=/dev/null
source ./install-functions.sh

function installTools() {  
  wget https://github.com/mikefarah/yq/releases/download/v4.28.2/yq_linux_amd64.tar.gz -O - | \
  tar xz && sudo mv yq_linux_amd64 /usr/bin/yq

}

function installDeleteCluster() {
  cd "$WORK_DIR"/terraform-modules/gke-install

  if [ -f "install-state.txt" ]; then
      last_project_id=$(cat install-state.txt)
      if [ "$last_project_id" != "$PROJECT_ID" ]; then
          echo "Clearing up the terraform state"
          rm -Rf .terraform*
          rm -f terraform.tfstate
      fi
  fi

  CLUSTER_NODE_ZONE=$(gcloud compute zones list --filter="region:$REGION" --limit=1 --format=json | \
    jq '.[0].name' | cut -d '"' -f 2); export CLUSTER_NODE_ZONE;

  #NETWORKS=$(gcloud compute networks list --format=json \
  #  --filter="name:hybrid-runtime-cluster-vpc" | jq length)
  #if [[ NETWORKS -eq 0 ]]; then
  #  IS_CREATE_VPC="true"; export IS_CREATE_VPC
  #else
  #  IS_CREATE_VPC="false"; export IS_CREATE_VPC
  #fi

  envsubst < "$WORK_DIR/terraform-modules/gke-install/hybrid.tfvars.tmpl" > \
    "$WORK_DIR/terraform-modules/gke-install/hybrid.tfvars"

  echo "$PROJECT_ID" > install-state.txt

  terraform init
  terraform plan \
    --var-file="$WORK_DIR/terraform-modules/gke-install/hybrid.tfvars"
  terraform "$1" -auto-approve \
    --var-file="$WORK_DIR/terraform-modules/gke-install/hybrid.tfvars"
}

function logIntoCluster() {
  gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"
  TOKEN=$(gcloud auth print-access-token); export TOKEN;
}

# Potential for common method for cloud installs (eks and gke)
function hybridPostInstallIngressGatewaySetup() {
  
  export SERVICE_NAME=$ENV_NAME-ingrs-svc
  export ENV_GROUP_INGRESS=$INGRESS_NAME
  
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

# Potential for common method for cloud installs (eks and gke)
function hybridPostInstallIngressGatewayValidation() {

  OUTPUT=$(curl -s "https://$DOMAIN/apigee-hybrid-helloworld" \
                --resolve "$DOMAIN:443:$INGRESS_IP_ADDRESS" -k -i | grep HTTP); export OUTPUT
  echo "$OUTPUT"
  if [[ "$OUTPUT" == *"200"* ]]; then
    printf "\n\nSUCCESS: Hybrid is successfully installed\n\n"
    echo ""
    echo "Test the deployed sample proxy:"
    echo curl -s \"https://$DOMAIN/apigee-hybrid-helloworld\" --resolve \"$DOMAIN:443:$INGRESS_IP_ADDRESS\" -k -i
    echo "";echo "";
  else
    printf "\n\nPlease check the logs and troubleshoot, proxy execution failed"
  fi
}

parse_args "${@}"

banner_info "Step- Validatevars";
validateVars

# Potential for common method for cloud installs (eks and gke)
if [[ $SHOULD_DELETE_PROJECT == "1" ]]; then
  banner_info "Step- Delete Project"
  installDeleteProject "destroy";
  echo "Successfully deleted project, exiting"
  #https://console.cloud.google.com/networking/firewalls/list?project=$PROJECT_ID
  exit 0;
fi

if [[ $SHOULD_DELETE_CLUSTER == "1" ]]; then
  banner_info "Step- Delete Cluster"
  installDeleteCluster "destroy";
  echo "Successfully deleted cluster, exiting"
  exit 0;
fi

# Potential for common method for cloud installs (eks and gke)
if [[ $SHOULD_CREATE_PROJECT == "1" ]]; then
  banner_info "Step- Install Project"
  DO_PROJECT_CREATE='false'; #TODO: This stmt van be deleted
  installDeleteProject "apply";
fi

# Potential for common method for cloud installs (eks and gke)
if [[ $SHOULD_CREATE_APIGEE_ORG == "1" ]]; then
    banner_info "Step- Install Apigee Org"
    installApigeeOrg;

    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
      --member user:${USER_ID} \
      --role roles/apigee.admin
fi

banner_info "Step - Install Tools"
installTools

if [[ $SHOULD_INSTALL_CLUSTER == "1" ]] && [[ $SHOULD_SKIP_INSTALL_CLUSTER == "0" ]]; then
  banner_info "Step- Install Cluster"
  checkAndApplyOrgconstranints;
  installDeleteCluster "apply";
fi

# Potential for common method for cloud installs (eks and gke)
if [[ $CLUSTER_ACTION == "1" ]]; then
  banner_info "Step- Log into cluster";
  logIntoCluster;
fi

if [[ $SHOULD_PREP_HYBRID_INSTALL_DIRS == "1" ]]; then
  banner_info "Step- Prepare directories";
  prepHybridInstallDirs;
fi

if [[ $SHOULD_INSTALL_CERT_MNGR == "1" ]]; then
  banner_info "Step- cert manager Install";
  certManagerInstall;
fi

if [[ $SHOULD_INSTALL_HYBRID == "1" ]]; then
  banner_info "Step- Hybrid Install";
  hybridRuntimeInstall;
fi

if [[ $SHOULD_INSTALL_INGRESS == "1" ]]; then
  banner_info "Step- Post Install";
  hybridPostInstallIngressGatewaySetup;

  banner_info "Step- Deploy Sample Proxy For Validation"
  deploySampleProxyForValidation;

  banner_info "Step- Validation of proxy execution";
  hybridPostInstallIngressGatewayValidation;
fi

banner_info "COMPLETE"