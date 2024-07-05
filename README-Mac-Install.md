# Hybrid Installation on Mac

To enable quick test and validation of Apigee Hybrid on a Mac with 16 GB Memory.

## Pre-requisite tools/libraries install before executing the install
    ```bash

    brew install yq
    brew install jq
    brew install wget
    brew install ca-certificates
    brew install gnupg2
    brew install helm

    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
    terraform -help

    brew install kubectl
    kubectl version --client

    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    ```

### Docker Installation

Follow the instructions here to install Docker on Mac
https://docs.docker.com/desktop/install/mac-install/

### gcloud cli installation

Follow the instructions here to install gcloud cli on Mac
https://cloud.google.com/sdk/docs/install-sdk


### Prepare the directories
    ```bash
    export INSTALL_DIR=<Install Dir where this source will be downloaded>
    cd $INSTALL_DIR
    ```
    
### Install the repos 
    ```bash
    cd $INSTALL_DIR
    git clone https://github.com/ganadurai/single-node-apigee-hybrid-install.git
    cd single-node-apigee-hybrid-install
    export WORK_DIR=$(pwd)
    ```

### Setup Environment variables and tokens 
    ```bash
    export USER_ID=<gcp-login-email>
    export PROJECT_ID=<gcp-project-id>
    export BILLING_ACCOUNT_ID=<gcp-billing-id>

    export ORG_ID=<gcp-project-org-id, if organization id is not available you can provide 'organizations/0'> 

    export ANALYTICS_REGION=<gcp-analytics-region, you can use 'us-east1' as default>

    echo "all properties set..." 
    ```

### Log into GCP
    ```bash
    gcloud auth application-default login
    gcloud auth login $USER_ID --force
    gcloud config set project $PROJECT_ID
    export TOKEN=$(gcloud auth print-access-token)
    ```

## Install and Validate
    ```bash
    cd $WORK_DIR/scripts/

    alias cmdscript="$WORK_DIR/scripts/install-mac-apigee-hybrid.sh "
    cmdscript --project-create
    cmdscript --apigee-org-create
    cmdscript --create-cluster
    cmdscript --prep-install-dirs
    cmdscript --install-hybrid
    cmdscript --install-ingress
    ```

### Validation & Progress check
    ```bash
    echo "K3D cluster running, logging in..."
    KUBECONFIG=$(k3d kubeconfig write hybrid-cluster); export KUBECONFIG
    alias ka="kubectl -n apigee"
    alias ks="kubectl -n apigee-system"
    alias wa="watch kubectl get pods -n apigee"

    ka get pods
    ```

### Cleanup of local cluster
    ```bash
    k3d cluster delete hybrid-cluster
    ```

### Delete project hosting Apigee Hybrid Org
    ```bash
    gcloud projects delete $PROJECT_ID
    ```