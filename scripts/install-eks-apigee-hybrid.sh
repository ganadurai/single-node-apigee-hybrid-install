#!/bin/bash

set -e

# shellcheck source=/dev/null
source ./install-functions.sh
source ./helm/install-hybrid-helm-functions.sh
source ./setup-eks.sh

source ./helm/set-overrides.sh
source ./helm/install-crds-cert-mgr.sh
source ./helm/set-chart-values.sh
source ./helm/execute-charts.sh

function logIntoCluster() {
    aws eks update-kubeconfig --region "$EKS_REGION" --name "$CLUSTER_NAME"
}

function installCluster() {
    eksPrepAndInstall;
}

parse_args "${@}"

banner_info "Step- Set Environment Variables";
setEnvironmentVariables

banner_info "Step- Validatevars";
validateVars
validateEksSetupVars

if [[ $SHOULD_INSTALL_TOOLS == "1" ]]; then
    installEksSetupTools;
fi

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
  echo "Delete EKS cluster manually from the AWS console, automation via this script not supported"
  exit 0;
fi

# Potential for common method for cloud installs (eks and gke)
if [[ $SHOULD_CREATE_PROJECT == "1" ]]; then
  banner_info "Step- Install Project"
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

if [[ $SHOULD_INSTALL_CLUSTER == "1" ]] && [[ $SHOULD_SKIP_INSTALL_CLUSTER == "0" ]]; then
  banner_info "Step- Install Cluster"
  installCluster;
fi

# Potential for common method for cloud installs (eks and gke)
if [[ $CLUSTER_ACTION == "1" ]]; then
  banner_info "Step- Log into cluster";
  logIntoCluster;
fi

# Potential for common method for cloud installs (eks and gke)
if [[ $SHOULD_PREP_HYBRID_INSTALL_DIRS == "1" ]]; then
  banner_info "Step- Prepare directories";
  prepInstallDirs;
  logIntoCluster;
  kubectl create namespace apigee
fi

# Potential for common method for cloud installs (eks and gke)
if [[ $SHOULD_INSTALL_CERT_MNGR == "1" ]]; then
  banner_info "Skipped- (this is handled as part of helm installs)";
fi

# Potential for common method for cloud installs (eks and gke)
if [[ $SHOULD_INSTALL_HYBRID == "1" ]]; then
  banner_info "Step- Hybrid Install";
  hybridInstallViaHelmCharts; 
fi

if [[ $SHOULD_INSTALL_INGRESS == "1" ]]; then
  banner_info "Step- Post Install";

  banner_info "Step- Deploy Sample Proxy For Validation"
  deploySampleProxyForValidation;

  banner_info "Step- Validation of proxy execution (Manual: execute below)";
  INGRESS_IP_ADDRESS=$(kubectl -n apigee get svc -l app=apigee-ingressgateway -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
  echo $INGRESS_IP_ADDRESS
  echo "nslookup $INGRESS_IP_ADDRESS"
  echo "curl \"https://$DOMAIN/apigee-hybrid-helloworld\" -k --resolve \"$DOMAIN:443:IPADDRESS_FROM_ABOVE\" -i"
fi

banner_info "COMPLETE"