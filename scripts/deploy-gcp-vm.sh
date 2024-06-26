#!/bin/bash

set -e

# shellcheck source=/dev/null
source ./install-functions.sh

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
    --create-vm                  Creates the the VM instance that hosts container infrastructure.
    --delete-vm                  Deletes the the VM instance
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
        
    Creates a new GCP project, configures Apigee org and installs Apigee Hybrid within the specified GKE cluster 

        $ ./${SCRIPT_NAME} --project-create --setup-all

EOF
}

################################################################################
# Parse command line arguments.
################################################################################
parse_args() {
    export SHOULD_SKIP_INSTALL_CLUSTER="0"
    export CLUSTER_ACTION="0"
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
        --create-vm)
            export SHOULD_CREATE_VM="1"
            shift 1
            ;;
        --delete-vm)
            export SHOULD_DELETE_VM="1"
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
          "${SHOULD_CREATE_VM}"   != "1" &&
          "${SHOULD_DELETE_VM}"     != "1" ]]; then
        usage
        exit
    fi
}

function createDestroyVM() {
    cd "$WORK_DIR/terraform-modules/vm-install"

    if [ -f "install-state.txt" ]; then
        last_project_id=$(cat install-state.txt)
        if [ "$last_project_id" != "$PROJECT_ID" ]; then
            echo "Clearing up the terraform state"
            rm -Rf .terraform*
            rm -f terraform.tfstate
        fi
    fi

    NODE_ZONE=$(gcloud compute zones list --filter="region:$REGION" --limit=1 --format=json | \
    jq '.[0].name' | cut -d '"' -f 2); export NODE_ZONE;

    echo "$PROJECT_ID" > install-state.txt

    terraform init;
    terraform plan \
        -var="PROJECT_ID=${PROJECT_ID}" \
        -var="ORG_ADMIN=${ORG_ADMIN}" \
        -var="ORG_NAME=${ORG_NAME}" \
        -var="CLUSTER_NAME=${CLUSTER_NAME}" \
        -var="TOKEN=${TOKEN}" \
        -var="APIGEE_NAMESPACE=$APIGEE_NAMESPACE" \
        -var="ENV_NAME=$ENV_NAME" \
        -var="ENV_GROUP=$ENV_GROUP" \
        -var="DOMAIN=$DOMAIN" \
        -var="REGION=$REGION" \
        -var="ZONE=$NODE_ZONE";
    terraform "$1" -auto-approve \
        -var="PROJECT_ID=${PROJECT_ID}" \
        -var="ORG_ADMIN=${ORG_ADMIN}" \
        -var="ORG_NAME=${ORG_NAME}" \
        -var="CLUSTER_NAME=${CLUSTER_NAME}" \
        -var="TOKEN=${TOKEN}" \
        -var="APIGEE_NAMESPACE=$APIGEE_NAMESPACE" \
        -var="ENV_NAME=$ENV_NAME" \
        -var="ENV_GROUP=$ENV_GROUP" \
        -var="DOMAIN=$DOMAIN" \
        -var="REGION=$REGION" \
        -var="ZONE=$NODE_ZONE";

}

parse_args "${@}"

banner_info "Step- Validatevars";
validateVars

if [[ $SHOULD_DELETE_VM == "1" ]]; then
  banner_info "Step- Destroy VM"
  createDestroyVM "destroy";
  exit 0;
fi

if [[ $SHOULD_CREATE_PROJECT == "1" ]]; then
  banner_info "Step- Install Project"
  installDeleteProject "apply";
else
  enableAPIsAndOrgAdmin;
fi

if [[ $SHOULD_CREATE_APIGEE_ORG == "1" ]]; then
  banner_info "Step- Install Apigee Org"
  installApigeeOrg;
fi

banner_info "Check and Apply org constranints"
checkAndApplyOrgconstranints;

if [[ $SHOULD_CREATE_VM == "1" ]]; then
  banner_info "Step- Create VM"
  createDestroyVM "apply";
  
  banner_info "Step- Next Steps...";
  echo ""
  echo "Access the below url to confirm the existence of log entry 'startup-script exit status 0' this validates the bootup of the instance is successful (approx wait time 2mts)"
  echo "https://console.cloud.google.com/logs/query;query=startup-script%20exit%20status%200;?referrer=search&project=$PROJECT_ID"
  echo ""
  echo "Waiting 2m for the vm to boot up.."
  sleep 120s
  echo "Access the ssh console of the instance"
  echo "https://ssh.cloud.google.com/v2/ssh/projects/$PROJECT_ID/zones/$NODE_ZONE/instances/vm-hybrid-instance-1"
  echo ""
fi


