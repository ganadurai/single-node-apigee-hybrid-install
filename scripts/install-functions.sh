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
source ./hybrid-artifacts/fill-resource-values.sh
# shellcheck source=/dev/null
source ./hybrid-artifacts/add-resources-components.sh

SCRIPT_NAME="${0##*/}"

function validateDockerInstall() {
  if [ -x "$(command -v docker)" ]; then
    echo "docker presence is validated ..."
  else
    echo "Docker is not running, install docker by running the script within the quotes './install-docker.sh; logout' and retry the hybrid install."
    exit 1;
  fi
}

function validateVars() {
  if [[ -z $WORK_DIR ]]; then
      #echo "Environment variable WORK_DIR setting now..."
      WORK_DIR="$(pwd)/.."; export WORK_DIR;
      #echo "WORK_DIR=$WORK_DIR"
  fi

  if [[ -z $HYBRID_INSTALL_DIR ]]; then
      #echo "Environment variable HYBRID_INSTALL_DIR setting now..."
      HYBRID_INSTALL_DIR="$(pwd)/../../apigee-hybrid-install"; export HYBRID_INSTALL_DIR;
      #echo "HYBRID_INSTALL_DIR=$HYBRID_INSTALL_DIR"
  fi

  if [[ -z $PROJECT_CREATE ]]; then
    PROJECT_CREATE=false;
  fi

  if [[ -z $ORG_CREATE ]]; then
    ORG_CREATE=false;
  fi

  if [[ -z $APIGEE_NAMESPACE ]]; then
      echo "Environment variable APIGEE_NAMESPACE setting now..."
      APIGEE_NAMESPACE="apigee"; export APIGEE_NAMESPACE;
      echo "APIGEE_NAMESPACE=$APIGEE_NAMESPACE"
  fi

  if [[ -z $ORG_NAME ]]; then
    echo "Environment variable ORG_NAME is not set, setting to PROJECT_ID"
    ORG_NAME=$PROJECT_ID; export ORG_NAME;
  fi

  if [[ -z $ENV_NAME ]]; then
    echo "Environment variable ENV_NAME is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $ENV_GROUP ]]; then
    echo "Environment variable ENV_GROUP is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $DOMAIN ]]; then
    echo "Environment variable DOMAIN is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $CLUSTER_NAME ]]; then
    echo "Environment variable CLUSTER_NAME is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $REGION ]]; then
    echo "Environment variable REGION is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $PROJECT_ID ]]; then
    echo "Environment variable PROJECT_ID is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $TOKEN ]]; then
    echo "Environment variable TOKEN is not set, please checkout README.md"
    exit 1
  fi

  if [[ $PROJECT_CREATE = true ]] && [[ -z $BILLING_ACCOUNT_ID ]]; then
    echo "BILLING_ACCOUNT_ID is not set with PROJECT_CREATE marked as true, please checkout README.md"
    exit 1
  fi

  if [[ -z $VPC_NETWORK_NAME ]]; then
    VPC_NETWORK_NAME="hybrid-runtime-cluster-vpc"; export VPC_NETWORK_NAME;
  fi

  if [[ -z $SUB_NETWORK_NAME ]]; then
    SUB_NETWORK_NAME="hybrid-runtime-cluster-vpc-subnetwork"; export SUB_NETWORK_NAME;
  fi
}

function installTools() {  
  sudo apt update
  sudo apt-get install git -y
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

function installDeleteProject() {
  cd "$WORK_DIR"/terraform-modules/project-install
  terraform init
  terraform plan -var "billing_account=$BILLING_ACCOUNT_ID" \
  -var "project_id=$PROJECT_ID" -var "org_admin=$ORG_ADMIN" -var "project_create=true"
  terraform "$1" -auto-approve -var "billing_account=$BILLING_ACCOUNT_ID" \
  -var "project_id=$PROJECT_ID" -var "org_admin=$ORG_ADMIN" -var "project_create=true"
}

function installApigeeOrg() {
  cd "$WORK_DIR"/terraform-modules/apigee-install
  rm -Rf .terraform*
  rm terraform.tfstate
  terraform init
  terraform plan -var "apigee_org_create=true" \
  -var "project_id=$PROJECT_ID" --var-file="$WORK_DIR/terraform-modules/apigee-install/apigee.tfvars"
  terraform apply -auto-approve -var "apigee_org_create=true" \
  -var "project_id=$PROJECT_ID" --var-file="$WORK_DIR/terraform-modules/apigee-install/apigee.tfvars"

}

function fetchHybridInstall() {
  if [[ -d $WORK_DIR/../apigee-hybrid-install ]]; then #if the script is re-ran, clean it and pull a fresh copy
    rm -Rf "$WORK_DIR/../apigee-hybrid-install"
  fi

  cd "$WORK_DIR/.."
  git clone https://github.com/apigee/apigee-hybrid-install.git
  HYBRID_INSTALL_DIR="$WORK_DIR/../apigee-hybrid-install"; export HYBRID_INSTALL_DIR
}

function hybridPreInstallOverlaysPrep() {

  fetchHybridInstall;

  echo "Filling in resource values"
  fillResourceValues;
  echo "Moving resource overlays into Hybrid install source"
  moveResourcesSpecsToHybridInstall;

  echo "Updating datastore kustomization"
  datastoreKustomizationFile="$HYBRID_INSTALL_DIR/overlays/instances/instance1/datastore/kustomization.yaml";
  datastoreComponentEntries=("./components/cassandra-resources")
  addComponents "$datastoreKustomizationFile" "${datastoreComponentEntries[@]}"

  echo "Updating organization kustomization"
  organizationKustomizationFile="$HYBRID_INSTALL_DIR/overlays/instances/instance1/organization/kustomization.yaml";
  componentEntries=("./components/connect-resources" "./components/ingressgateway-resources" "./components/mart-resources" "./components/watcher-resources")
  addComponents "$organizationKustomizationFile" "${componentEntries[@]}"

  echo "Updating environment kustomization"
  environmentKustomizationFile="$HYBRID_INSTALL_DIR/overlays/instances/instance1/environments/test/kustomization.yaml";
  componentEntries=("./components/runtime-resources" "./components/synchronizer-resources" "./components/udca-resources")
  addComponents "$environmentKustomizationFile" "${componentEntries[@]}"

  echo "Updating redis kustomization"
  redisKustomizationFile="$HYBRID_INSTALL_DIR/overlays/instances/instance1/redis/kustomization.yaml";
  componentEntries=("./components/redis-resources" "./components/redisenvoy-resources")
  addComponents "$redisKustomizationFile" "${componentEntries[@]}"

  echo "Updating telemetry kustomization"
  telemetryKustomizationFile="$HYBRID_INSTALL_DIR/overlays/instances/instance1/telemetry/kustomization.yaml";
  componentEntries=("./components/telemetry-resources")
  addComponents "$telemetryKustomizationFile" "${componentEntries[@]}"
}

function hybridInstall() {
  
  printf "\nInstalling and Setting up Hybrid containers\n"
  RESULT=0
  OUTPUT=$("$HYBRID_INSTALL_DIR"/tools/apigee-hybrid-setup.sh \
            --org "$ORG_NAME" --env "$ENV_NAME" --envgroup "$ENV_GROUP" \
            --ingress-domain "$DOMAIN" --cluster-name "$CLUSTER_NAME" \
            --cluster-region "$REGION" --gcp-project-id "$PROJECT_ID" \
            --setup-all --verbose > /tmp/hybrid-install-output.txt)
  printf "\nHybrid Install Result : %s\n" "$OUTPUT"
  if [[ "$OUTPUT" -eq 1 ]]; then
    if grep -q 'failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/validate?timeout=10s"' /tmp/hybrid-install-output.txt  
    then
      RESULT=1
    else
      RESULT=-1
    fi
  fi
  return $RESULT
}

function certManagerInstall() {
  cd "$HYBRID_INSTALL_DIR"
  echo "checking cert manager exixts"
  RESULT=$(kubectl get namespace | { grep cert-manager || true; } | wc -l); echo "$RESULT"
  echo "checked cert manager exists"
  if [[ $RESULT -eq 0 ]]; then
    kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.7.2/cert-manager.yaml
    date
    echo "Waiting 3m for the cert manager initialization"
    sleep 180
    date
  else
    echo "cert-manager is already present and running."
  fi
}

function hybridRuntimeInstall() {
  cd "$HYBRID_INSTALL_DIR"
  
  echo "ORG_NAME=$ORG_NAME"
  echo "ENV_NAME=$ENV_NAME"
  echo "ENV_GROUP=$ENV_GROUP"
  echo "DOMAIN=$DOMAIN"
  echo "CLUSTER_NAME=$CLUSTER_NAME"
  echo "REGION=$REGION"
  echo "PROJECT_ID=$PROJECT_ID" 
  
  touch /tmp/hybrid-install-output.txt
  hybridInstall;
  RESULT=$?

  counter=0;
  while [ $RESULT -eq 1 ] && [ $counter -lt 3 ]; do
    hybridInstall; #retrying to accomdate for cert-manager readiness
    RESULT=$?
    counter=$((counter+1))
  done

  if [[ $RESULT -eq -1 ]]; then
    echo "Unexpected error, checkout the logs for troubleshooting"
  fi

  kubectl wait "apigeedatastore/default" \
    "apigeeredis/default" \
    "apigeeenvironment/${ORG_NAME}-${ENV_NAME}" \
    "apigeeorganization/${ORG_NAME}" \
    "apigeetelemetry/apigee-telemetry" \
    -n "${APIGEE_NAMESPACE}" --for="jsonpath=.status.state=running" --timeout=5s
  exit_code=$?
  if (( "$exit_code" == 0 )); then
    echo "Hybrid successfully deployed"
  else
    echo "Hybrid not successfully deployed... Check on the pod status in the ${APIGEE_NAMESPACE} namespace"
    exit 1;
  fi
}

function deploySampleProxyForValidation() {
  export MGMT_HOST="https://apigee.googleapis.com"
  curl -X POST "$MGMT_HOST/v1/organizations/$ORG_NAME/apis?action=import&name=apigee-hybrid-helloworld" \
        -H "Authorization: Bearer $TOKEN" --form file=@"$WORK_DIR/apigee-hybrid-helloworld.zip"
  curl -X POST "$MGMT_HOST/v1/organizations/$ORG_NAME/environments/eval/apis/apigee-hybrid-helloworld/revisions/1/deployments?override=true" \
        -H "Authorization: Bearer $TOKEN"
  echo "Waiting for proxy deployment and ready for testing, 60s"
  sleep 60
}

function banner_info() {
    echo ""
    info "********************************************"
    info "${1}"
    info "********************************************"
}

function info() {
    if [[ "${VERBOSE}" -eq 1 && "${HAS_TS}" -eq 1 ]]; then
        echo "${SCRIPT_NAME}: ${1}" | TZ=utc ts '%Y-%m-%dT%.T' >&2
    else
        echo "${SCRIPT_NAME}: ${1}" >&2
    fi
}

warn() {
    info "[WARNING]: ${1}" >&2
}

function error() {
    info "[ERROR]: ${1}" >&2
}

function fatal() {
    error "${1}"
    exit 2
}

################################################################################
# Print help text.
################################################################################
usage() {
    local FLAGS_1 FLAGS_2

    # Flags that require an argument
    FLAGS_1="$(
        cat <<EOF
    --org             <ORGANIZATION_NAME>           Set the Apigee Organization.
                                                    If not set, the project configured
                                                    in gcloud will be used.
    --env             <ENVIRONMENT_NAME>            Set the Apigee Environment.
                                                    If not set, a random environment
                                                    within the organization will be
                                                    selected.
    --envgroup        <ENVIRONMENT_GROUP_NAME>      Set the Apigee Environment Group.
                                                    If not set, a random environment
                                                    group within the organization
                                                    will be selected.
    --domain          <ENVIRONMENT_GROUP_HOSTNAME>  Set the hostname. This will be
                                                    used to generate self signed
                                                    certificates.
    --namespace       <APIGEE_NAMESPACE>            The name of the namespace where
                                                    apigee components will be installed.
                                                    Defaults to "apigee".
    --cluster-name    <CLUSTER_NAME>                The Kubernetes cluster name.
    --cluster-region  <CLUSTER_REGION>              The region in which the
                                                    Kubernetes cluster resides.
    --gcp-project-id  <GCP_PROJECT_ID>              The GCP Project ID where the
                                                    Kubernetes cluster exists.
                                                    This can be different from
                                                    the Apigee Organization name.
    --token           <GCP_AUTH_TOKEN>              The GCP Project User Admin Token
                                                    Check README for details.
EOF
    )"

    # Flags that DON'T require an argument
    FLAGS_2="$(
        cat <<EOF
    --create-cluster             Creates the GKE cluster or the VM instance that hosts
                                 container infrastructure.
    --skip-create-cluster        Skips creating the GKE cluster or the VM instance 
                                 (if done already)that hosts container infrastructure.
    --prep-overlay-files         Creates the overlay files for the spec requests for the pods
    --install-cert-manager       Installs the cert manager in the cluster
    --install-hybrid             Deploys the apigee hybrid runtime place
    --install-ingress            Creates the ingress service to serve as the gatway to 
                                 access the deployed proxy 
    --setup-all                  Used to execute all the tasks that can be performed
                                 by the script.
    --delete-cluster             Delete cluster.
    --help                       Display usage information.
EOF
    )"

    cat <<EOF
    
USAGE: ${SCRIPT_NAME} --cluster-name <CLUSTER_NAME> --cluster-region <CLUSTER_REGION> [FLAGS]...

Helps with the installation of Apigee Hybrid. Can be used to either automate the
complete installation, or execute individual tasks

FLAGS that expect an argument:

$FLAGS_1

FLAGS without argument:

$FLAGS_2

EXAMPLES:

    Setup everything:
        
        $ ./${SCRIPT_NAME} --org apigee-hybrid --env eval --envgroup eval-group --domain eval.apigee.com --cluster-name hybrid-cluster --cluster-region us-west1 --setup-all
        
    Only apply configuration and enable verbose logging:

        $ ./${SCRIPT_NAME} --org apigee-hybrid --env eval --envgroup eval-group --domain eval.apigee.com --cluster-name hybrid-cluster --cluster-region us-west1 --create-cluster

EOF
}

################################################################################
# Checks for the existence of a second argument and exit if it does not exist.
################################################################################
arg_required() {
    if [[ ! "${2:-}" || "${2:0:1}" = '-' ]]; then
        fatal "Option ${1} requires an argument."
    fi
}

################################################################################
# Parse command line arguments.
################################################################################
parse_args() {
    export SHOULD_SKIP_INSTALL_CLUSTER="0"
    while [[ $# != 0 ]]; do
        case "${1}" in
        --project-create)
            export SHOULD_CREATE_PROJECT="1"
            shift 1
            ;;
        --apigee-org-create)
            export SHOULD_CREATE_APIGEE_ORG="1"
            shift 1
            ;;
        --create-cluster)
            export SHOULD_INSTALL_CLUSTER="1"
            shift 1
            ;;
        --skip-create-cluster)
            export SHOULD_SKIP_INSTALL_CLUSTER="1"
            shift 1
            ;;
        --prep-overlay-files)
            export SHOULD_PREP_OVERLAYS="1"
            shift 1
            ;;
        --install-cert-manager)
            export SHOULD_INSTALL_CERT_MNGR="1"
            shift 1
            ;;
        --install-hybrid)
            export SHOULD_INSTALL_HYBRID="1"
            shift 1
            ;;
        --install-ingress)
            export SHOULD_INSTALL_INGRESS="1"
            shift 1
            ;;
        --setup-all)
            export SHOULD_INSTALL_CLUSTER="1"
            export SHOULD_PREP_OVERLAYS="1"
            export SHOULD_INSTALL_CERT_MNGR="1"
            export SHOULD_INSTALL_HYBRID="1"
            export SHOULD_INSTALL_INGRESS="1"
            shift 1
            ;;
        --delete-cluster)
            export SHOULD_DELETE_CLUSTER="1"
            shift 1
            ;;
        --delete-project)
            export SHOULD_DELETE_PROJECT="1"
            shift 1
            ;;
        --help)
            usage
            exit
            ;;
        *)
            fatal "Unknown option '${1}'"
            ;;
        esac
    done

    if [[ "${SHOULD_CREATE_PROJECT}" == "1" ]]; then
       export SHOULD_CREATE_APIGEE_ORG="1";
    fi

    if [[ "${SHOULD_CREATE_PROJECT}"    != "1" && 
          "${SHOULD_CREATE_APIGEE_ORG}" != "1" &&
          "${SHOULD_INSTALL_CLUSTER}"   != "1" &&
          "${SHOULD_PREP_OVERLAYS}"     != "1" &&
          "${SHOULD_INSTALL_CERT_MNGR}" != "1" &&
          "${SHOULD_INSTALL_HYBRID}"    != "1" &&
          "${SHOULD_INSTALL_INGRESS}"   != "1" &&
          "${SHOULD_DELETE_CLUSTER}"    != "1" &&
          "${SHOULD_DELETE_PROJECT}"    != "1" ]]; then
        usage
        exit
    fi

}
