#!/bin/bash

set -e

# shellcheck source=/dev/null
# source ./hybrid-artifacts/fill-resource-values.sh
# shellcheck source=/dev/null
# source ./hybrid-artifacts/add-resources-components.sh
# shellcheck source=/dev/null
# source ./hybrid-artifacts/hybrid-cluster-spec.sh

SCRIPT_NAME="${0##*/}"

function validateDockerInstall() {
  if [ -x "$(command -v docker)" ]; then
    echo "docker presence is validated ..."
  else
    echo "Docker is not running, install docker by running the script within the quotes './install-docker.sh; logout' and retry the hybrid install."
    exit 1;
  fi
}

function prepInstallDirs() {

    if [ ! -d "$APIGEE_HYBRID_BASE" ]; then
        mkdir $APIGEE_HYBRID_BASE
    fi

    if [ ! -d "$APIGEE_HELM_CHARTS_HOME_ORIG" ]; then
        mkdir $APIGEE_HELM_CHARTS_HOME_ORIG
        cd $APIGEE_HELM_CHARTS_HOME_ORIG 
        #export CHART_REPO=oci://us-docker.pkg.dev/apigee-release/apigee-hybrid-helm-charts
        #export CHART_VERSION=1.11.1
        helm pull $CHART_REPO/apigee-operator --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-datastore --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-env --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-ingress-manager --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-org --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-redis --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-telemetry --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-virtualhost --version $CHART_VERSION --untar
    fi

    if [ ! -d "$APIGEE_HELM_CHARTS_HOME" ]; then
        mkdir $APIGEE_HELM_CHARTS_HOME
        cd $APIGEE_HELM_CHARTS_HOME
        #export CHART_REPO=oci://us-docker.pkg.dev/apigee-release/apigee-hybrid-helm-charts
        #export CHART_VERSION=1.11.1
        helm pull $CHART_REPO/apigee-operator --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-datastore --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-env --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-ingress-manager --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-org --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-redis --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-telemetry --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-virtualhost --version $CHART_VERSION --untar
    fi
}

function validateVars() {
  if [[ -z $WORK_DIR ]]; then
      #echo "Environment variable WORK_DIR setting now..."
      WORK_DIR="$(pwd)/.."; export WORK_DIR;
      #echo "WORK_DIR=$WORK_DIR"
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

  if [[ -z $CHART_REPO ]]; then
    echo "Environment variable CHART_REPO is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $CHART_VERSION ]]; then
    echo "Environment variable CHART_VERSION is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $CERT_MGR_DWNLD_YAML ]]; then
    echo "Environment variable CERT_MGR_DWNLD_YAML is not set, please checkout README.md"
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

function setEnvironmentVariables() {
  export ENV_NAME="test-env"
  export DOMAIN="test.apigeehybrid.com"
  export ENV_GROUP="test-env-group"

  export ORG_ADMIN=$USER_ID
  export ORG_NAME=$PROJECT_ID
  export REGION=$ANALYTICS_REGION
  export RUNTIMETYPE=HYBRID

  export CHART_REPO=oci://us-docker.pkg.dev/apigee-release/apigee-hybrid-helm-charts
  export CHART_VERSION=1.12.0
  export CERT_MGR_DWNLD_YAML=https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

  export APIGEE_HYBRID_BASE=$WORK_DIR/../APIGEE_HYBRID_BASE_$PROJECT_ID
  export APIGEE_HELM_CHARTS_HOME=$APIGEE_HYBRID_BASE/EDIT_APIGEE_HELM_CHARTS_HOME
  export APIGEE_HELM_CHARTS_HOME_ORIG=$APIGEE_HYBRID_BASE/ORIG_APIGEE_HELM_CHARTS_HOME

  export SA_FILE_NAME=$PROJECT_ID-apigee-non-prod

  export UNIQUE_INSTANCE_IDENTIFIER=$(echo $(uuidgen)| tr -d '-') 

  export APIGEE_NAMESPACE=apigee
  export CLUSTER_LOCATION=$ANALYTICS_REGION
  export CLUSTER_NAME=hybrid-cluster
  export ENVIRONMENT_GROUP_NAME=$ENV_GROUP
  export ENVIRONMENT_NAME=$ENV_NAME
  export INGRESS_NAME=$ENV_GROUP-i
  export INGRESSGATEWAY_REPLICAS_MAX=3
  export NON_PROD_SERVICE_ACCOUNT_FILEPATH=$SA_FILE_NAME.json

  export PATH_TO_CERT_FILE=certs/keystore_$ENV_GROUP.pem
  export PATH_TO_KEY_FILE=certs/keystore_$ENV_GROUP.key
}

function installDeleteProject() {

  gcloud projects create $PROJECT_ID
  gcloud alpha billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT_ID

  #if [[ $1 == 'apply' ]] && [[ $DO_PROJECT_CREATE == 'false' ]]; then
  #  echo "Enabling org policies.."
    gcloud services enable --project="${PROJECT_ID}" \
      apigee.googleapis.com \
      apigeeconnect.googleapis.com \
      cloudapis.googleapis.com \
      cloudresourcemanager.googleapis.com \
      compute.googleapis.com \
      dns.googleapis.com \
      iam.googleapis.com \
      iamcredentials.googleapis.com \
      pubsub.googleapis.com \
      servicemanagement.googleapis.com \
      serviceusage.googleapis.com \
      storage-api.googleapis.com \
      storage-component.googleapis.com
  #fi

  #cd "$WORK_DIR"/terraform-modules/project-install

  #last_project_id=$(cat install-state.txt)
  #if [ "$last_project_id" != "" ] && [ "$last_project_id" != "$PROJECT_ID" ]; then
  #if [ "$last_project_id" != "$PROJECT_ID" ]; then
  #  echo "Clearing up the terraform state"
  #  rm -Rf .terraform*
  #  rm -f terraform.tfstate
  #fi
  
  #echo "$PROJECT_ID" > install-state.txt

  #terraform init

  #echo terraform plan -var "billing_account=$BILLING_ACCOUNT_ID" \
  #-var "project_id=$PROJECT_ID" -var "org_admin=$ORG_ADMIN" \
  #-var "project_create=$DO_PROJECT_CREATE" -var "region=$REGION" -var project_parent="$ORG_ID"

  #terraform plan -var "billing_account=$BILLING_ACCOUNT_ID" \
  #-var "project_id=$PROJECT_ID" -var "org_admin=$ORG_ADMIN" \
  #-var "project_create=$DO_PROJECT_CREATE" -var "region=$REGION" -var project_parent="$ORG_ID"
  #terraform "$1" -auto-approve -var "billing_account=$BILLING_ACCOUNT_ID" \
  #-var "project_id=$PROJECT_ID" -var "org_admin=$ORG_ADMIN" \
  #-var "project_create=$DO_PROJECT_CREATE" -var "region=$REGION" -var project_parent="$ORG_ID"
}

function validateAXRegion() {
  if [[ -z "$AX_REGION" ]]; then
    AX_REGION=$REGION;export AX_REGION;
  fi

  SUPPORTED_AX_REGIONS=(asia-northeast1 \
                        europe-west1 \
                        us-central1 \
                        us-east1 \
                        us-west1 \
                        australia-southeast1 \
                        europe-west2 \
                        asia-south1 \
                        asia-east1 \
                        asia-southeast1 \
                        asia-southeast2)
  REGION_CONTAINS=$(echo "${SUPPORTED_AX_REGIONS[@]:0}" | { grep "$AX_REGION" || true; } | wc -l);
  if [[ $REGION_CONTAINS -eq 1 ]]; then
    echo "Region $AX_REGION supported for Analytics !"
  else
    echo ""
    echo "Region $AX_REGION is not supported, set one of the below regions in env valiable AX_REGION"
    echo "${SUPPORTED_AX_REGIONS[*]}";
    echo ""
    exit 1;
  fi 
}

function checkAndApplyOrgconstranints() {
    echo "checking and applying constraints.."

    gcloud alpha resource-manager org-policies set-policy \
            --project="$PROJECT_ID" "$WORK_DIR/scripts/gke-artifacts/org-policies/disableServiceAccountKeyCreation.yaml"

    gcloud alpha resource-manager org-policies set-policy \
            --project="$PROJECT_ID" "$WORK_DIR/scripts/gke-artifacts/org-policies/requireOsLogin.yaml"

    gcloud alpha resource-manager org-policies set-policy \
            --project="$PROJECT_ID" "$WORK_DIR/scripts/gke-artifacts/org-policies/requireShieldedVm.yaml"

    RESULT=$(gcloud alpha resource-manager org-policies describe \
        constraints/compute.vmExternalIpAccess --project "$PROJECT_ID" | { grep ALLOW || true; } | wc -l);
    if [[ $RESULT -eq 0 ]]; then
        gcloud alpha resource-manager org-policies set-policy \
            --project="$PROJECT_ID" "$WORK_DIR/scripts/gke-artifacts/org-policies/vmExternalIpAccess.yaml"
        echo "Waiting 60s for org-policy take into effect! "
        sleep 60
    fi
}

function enableAPIsAndOrgAdmin() {
  echo "Enabling the needed APIs"
  gcloud services enable \
    apigee.googleapis.com \
    apigeeconnect.googleapis.com \
    cloudapis.googleapis.com \
    cloudresourcemanager.googleapis.com \
    compute.googleapis.com \
    dns.googleapis.com \
    iam.googleapis.com \
    iamcredentials.googleapis.com \
    pubsub.googleapis.com \
    servicemanagement.googleapis.com \
    serviceusage.googleapis.com \
    storage-api.googleapis.com \
    storage-component.googleapis.com --project "$PROJECT_ID"

  echo "Setting IAM role"
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member user:"$ORG_ADMIN" \
    --role roles/apigee.admin

  echo "Wait for 10s API enablement to synchronize.."
  sleep 10
}

function installApigeeOrg() {

  validateAXRegion;

  if [[ $SHOULD_CREATE_PROJECT == "1" ]]; then
    echo ""; #Rewrite if condition
  else
    enableAPIsAndOrgAdmin;
  fi

  cd "$WORK_DIR"/terraform-modules/apigee-install

  if [ -f "install-state.txt" ]; then
      last_project_id=$(cat install-state.txt)
      if [ "$last_project_id" != "$PROJECT_ID" ]; then
          echo "Clearing up the terraform state"
          rm -Rf .terraform*
          rm -f terraform.tfstate
      fi
  fi

  envsubst < "$WORK_DIR/terraform-modules/apigee-install/apigee.tfvars.tmpl" > \
    "$WORK_DIR/terraform-modules/apigee-install/apigee.tfvars"
  
  echo "$PROJECT_ID" > install-state.txt

  terraform init
  terraform plan -var "apigee_org_create=true" \
    -var "project_id=$PROJECT_ID" --var-file="$WORK_DIR/terraform-modules/apigee-install/apigee.tfvars" \
    -var "ax_region=$AX_REGION"
  terraform apply -auto-approve -var "apigee_org_create=true" \
    -var "project_id=$PROJECT_ID" --var-file="$WORK_DIR/terraform-modules/apigee-install/apigee.tfvars" \
    -var "ax_region=$AX_REGION"
}

#function checkNetworkExisits() {
#}

function fetchHybridInstall() {
  if [[ -d $WORK_DIR/../apigee-hybrid-install ]]; then #if the script is re-ran, clean it and pull a fresh copy
    rm -Rf "$WORK_DIR/../apigee-hybrid-install"
  fi

  cd "$WORK_DIR/.."
  git clone https://github.com/apigee/apigee-hybrid-install.git
  HYBRID_INSTALL_DIR="$WORK_DIR/../apigee-hybrid-install"; export HYBRID_INSTALL_DIR
}

function prepHybridInstallDirs() {

  #fetchHybridInstall;  

  export APIGEECTL_BASE=$WORK_DIR/../apigeectl-$PROJECT_ID
  export APIGEECTL_HOME=$APIGEECTL_BASE/apigeectl
  export HYBRID_FILES=$APIGEECTL_BASE/hybrid-files

  if [ ! -d "$APIGEECTL_BASE" ]; then
    mkdir "$APIGEECTL_BASE"
    cd "$APIGEECTL_BASE"
    VERSION=$(curl -s \
      https://storage.googleapis.com/apigee-release/hybrid/apigee-hybrid-setup/current-version.txt?ignoreCache=1)
    echo "APIGEE HYBRID Version = $VERSION"

    curl -LO  https://storage.googleapis.com/apigee-release/hybrid/apigee-hybrid-setup/$VERSION/apigeectl_linux_64.tar.gz

    tar xvzf apigeectl_linux_64.tar.gz -C "$APIGEECTL_BASE"
    mv *_linux_64 apigeectl
    rm apigeectl_linux_64.tar.gz

    mkdir "$HYBRID_FILES"
    cd "$HYBRID_FILES"

    mkdir overrides
    mkdir certs

    ln -s "$APIGEECTL_HOME"/tools tools
    ln -s "$APIGEECTL_HOME"/config config
    ln -s "$APIGEECTL_HOME"/templates templates
    ln -s "$APIGEECTL_HOME"/plugins plugins
    ls -l | grep ^l
  fi
}

function hybridInstall() {
  
  banner_info "Step- Setting up Service accounts";
  export SA_NAME=apigee-non-prod
  export SA_EMAIL=apigee-non-prod@$PROJECT_ID.iam.gserviceaccount.com

  "$HYBRID_FILES"/tools/create-service-account --env non-prod --dir "$HYBRID_FILES"/service-accounts
  ls "$HYBRID_FILES"/service-accounts

  banner_info "Step- Setting up Certs";
  openssl req  -nodes -new -x509 -keyout "$HYBRID_FILES/certs/keystore_$ENV_GROUP.key" -out "$HYBRID_FILES/certs/keystore_$ENV_GROUP.pem" -subj '/CN='$DOMAIN'' -days 3650
  ls "$HYBRID_FILES"/certs/

  UNIQUE_INSTANCE_IDENTIFIER=$(cat /proc/sys/kernel/random/uuid);echo $UNIQUE_INSTANCE_IDENTIFIER
  echo "$UNIQUE_INSTANCE_IDENTIFIER" > "$HYBRID_FILES"/UNIQUE_INSTANCE_IDENTIFIER.txt
  
  #defined in ./hybrid-artifacts/hybrid-cluster-spec.sh
  createOverrides4Hybrid;

  TOKEN=$(gcloud config config-helper --force-auth-refresh --format json | jq -r '.credential.access_token'); echo "$TOKEN"
  export TOKEN

  curl -X POST -H "Authorization: Bearer ${TOKEN}" -H "Content-Type:application/json" "https://apigee.googleapis.com/v1/organizations/${ORG_NAME}:setSyncAuthorization" -d '{"identities":["'"serviceAccount:apigee-non-prod@${ORG_NAME}.iam.gserviceaccount.com"'"]}'

  curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type:application/json" "https://apigee.googleapis.com/v1/organizations/${ORG_NAME}:getSyncAuthorization" -d ''

  cd "$HYBRID_FILES"

  "${APIGEECTL_HOME}"/apigeectl init -f overrides/overrides.yaml --dry-run=client
  "${APIGEECTL_HOME}"/apigeectl init -f overrides/overrides.yaml	
  echo "Waiting 3m for the apigee-system.."
  sleep 180s
  "${APIGEECTL_HOME}"/apigeectl check-ready -f overrides/overrides.yaml

  echo "Pods in apigee-system :"
  kubectl get pods -n apigee-system 
  echo ""
  echo "Pods in apigee :"
  kubectl get pods -n apigee

  "${APIGEECTL_HOME}"/apigeectl apply -f overrides/overrides.yaml --dry-run=client
  "${APIGEECTL_HOME}"/apigeectl apply -f overrides/overrides.yaml
  echo "Waiting 10m for the apigee namespace.."
  sleep 600s
  "${APIGEECTL_HOME}"/apigeectl check-ready -f overrides/overrides.yaml

  kubectl get pods -n apigee
}

function certManagerInstall() {
  cd "$HYBRID_INSTALL_DIR"
  echo "checking cert manager exixts"
  RESULT=$(kubectl get namespace | { grep cert-manager || true; } | wc -l);
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
  PROXY_REVISION=$(curl -X POST "$MGMT_HOST/v1/organizations/$ORG_NAME/apis?action=import&name=apigee-hybrid-helloworld" \
        -H "Authorization: Bearer $TOKEN" --form file=@"$WORK_DIR/apigee-hybrid-helloworld.zip" | \
    jq '.revision'|cut -d '"' -f 2);
  if [[ -z $PROXY_REVISION ]]; then
    echo "Error in uploading the sample proxy to management api endpoint : $MGMT_HOST"
    exit 1;
  fi
  curl -s -X POST "$MGMT_HOST/v1/organizations/$ORG_NAME/environments/$ENV_NAME/apis/apigee-hybrid-helloworld/revisions/$PROXY_REVISION/deployments?override=true" \
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
    local FLAGS_2

    # Flags that DON'T require an argument
    FLAGS_2="$(
        cat <<EOF
    --project-create             Creates GCP project and enables the needed apis for setting up apigee
    --apigee-org-create          Creates Apigee org within the assigned project.
    --create-cluster             Creates the GKE cluster or the VM instance that hosts
                                 container infrastructure.
    --skip-create-cluster        Skips creating the GKE cluster or the VM instance 
                                 (if done already)that hosts container infrastructure.
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
    
Helps with the installation of Apigee Hybrid. Can be used to either automate the
complete installation, or execute individual tasks

$FLAGS_2

EXAMPLES:

    Setsup everything on a existing project with an apigee org configured already:
        
        $ ./${SCRIPT_NAME} --setup-all
        
    Creates a new GCP project, configures Apigee org and installs Apigee Hybrid

        $ ./${SCRIPT_NAME} --project-create --setup-all

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
    export SHOULD_SKIP_INSTALL_TOOLS="0"
    export CLUSTER_ACTION="0"
    while [[ $# != 0 ]]; do
        case "${1}" in
        --install-tools)
            export SHOULD_INSTALL_TOOLS="1"
            shift 1
            ;;
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
        --prep-install-dirs)
            export SHOULD_PREP_HYBRID_INSTALL_DIRS="1"
            shift 1
            ;;
        --install-cert-manager)
            export SHOULD_INSTALL_CERT_MNGR="1"
            export CLUSTER_ACTION="1"
            shift 1
            ;;
        --install-hybrid)
            export SHOULD_INSTALL_HYBRID="1"
            export CLUSTER_ACTION="1"
            shift 1
            ;;
        --install-ingress)
            export SHOULD_INSTALL_INGRESS="1"
            export CLUSTER_ACTION="1"
            shift 1
            ;;
        --setup-all)
            export SHOULD_CREATE_PROJECT="1"
            export SHOULD_CREATE_APIGEE_ORG="1"
            export SHOULD_INSTALL_CLUSTER="1"
            export SHOULD_PREP_HYBRID_INSTALL_DIRS="1"
            export SHOULD_INSTALL_CERT_MNGR="1"
            export SHOULD_INSTALL_HYBRID="1"
            export SHOULD_INSTALL_INGRESS="1"
            export CLUSTER_ACTION="1"
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

    #if [[ "${SHOULD_CREATE_PROJECT}" == "1" ]]; then
       #export SHOULD_CREATE_APIGEE_ORG="1";
    #fi

    if [[ "${SHOULD_CREATE_PROJECT}"            != "1" && 
          "${SHOULD_CREATE_APIGEE_ORG}"         != "1" &&
          "${SHOULD_INSTALL_TOOLS}"             != "1" &&
          "${SHOULD_INSTALL_CLUSTER}"           != "1" &&
          "${SHOULD_PREP_HYBRID_INSTALL_DIRS}"  != "1" &&
          "${SHOULD_INSTALL_CERT_MNGR}"         != "1" &&
          "${SHOULD_INSTALL_HYBRID}"            != "1" &&
          "${SHOULD_INSTALL_INGRESS}"           != "1" &&
          "${SHOULD_DELETE_CLUSTER}"            != "1" &&
          "${SHOULD_DELETE_PROJECT}"            != "1" ]]; then
        usage
        exit
    fi

}
