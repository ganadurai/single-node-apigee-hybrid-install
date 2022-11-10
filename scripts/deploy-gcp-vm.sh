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
    --create-vm                  Creates the the VM instance that hosts
                                 container infrastructure.
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

function checkAndApplyOrgconstranints() {
    gcloud alpha resource-manager org-policies describe \
        constraints/compute.vmExternalIpAccess --project "$PROJECT_ID" | grep ALLOW
    RESULT=$?
    if [[ $RESULT -ne 0 ]]; then
        gcloud alpha resource-manager org-policies set-policy \
            --project="$PROJECT_ID" "$WORK_DIR/scripts/org-policies/vmExternalIpAccess.yaml"
        echo "Waiting 30s for org-policy take into effect! "
        sleep 30
    fi
}

function createDestroyVM() {
    cd "$WORK_DIR/terraform-modules/vm-install"

    last_project_id=$(cat install-state.txt)
    if [ -z "$last_project_id" ] || [ last_project_id != "$PROJECT_ID" ]; then
        echo "Clearing up the terraform state"
        rm -Rf .terraform*
        rm -f terraform.tfstate
    fi

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
        -var="REGION=$REGION";
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
        -var="REGION=$REGION";

  echo "$PROJECT_ID" > install-state.txt
}

parse_args "${@}"

banner_info "Step- Validatevars";
validateVars

if [[ $SHOULD_CREATE_PROJECT == "1" ]]; then
  banner_info "Step- Install Project"
  installDeleteProject "apply";
fi

banner_info "Check and Apply org constranints"
checkAndApplyOrgconstranints;

if [[ $SHOULD_CREATE_APIGEE_ORG == "1" ]]; then
  banner_info "Step- Install Apigee Org"
  installApigeeOrg;
fi

if [[ $SHOULD_CREATE_VM == "1" ]]; then
  banner_info "Step- Create VM"
  createDestroyVM "apply";
fi

if [[ $SHOULD_DELETE_VM == "1" ]]; then
  banner_info "Step- Destroy VM"
  createDestroyVM "destroy";
fi


