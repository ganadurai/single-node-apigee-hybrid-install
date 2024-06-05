#!/bin/bash

set -e

# shellcheck source=/dev/null
source ./install-functions.sh
source ./helm/install-hybrid-helm-functions.sh

source ./helm/set-overrides.sh
source ./helm/install-crds-cert-mgr.sh
source ./helm/set-chart-values.sh
source ./helm/execute-charts.sh

function logIntoCluster() {
    aws eks update-kubeconfig --region "$AWS_EKS_REGION" --name "$CLUSTER_NAME"
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
  hybridPostInstallIngressGatewaySetup;

  banner_info "Step- Deploy Sample Proxy For Validation"
  deploySampleProxyForValidation;

  banner_info "Step- Validation of proxy execution";
  hybridPostInstallIngressGatewayValidation;
fi

banner_info "COMPLETE"