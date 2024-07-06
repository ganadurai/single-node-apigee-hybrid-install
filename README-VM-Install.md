# Hybrid Installation on AWS VM (Ubunut) or GCP VM 

To enable quick test and validation of Apigee Hybrid on a VM with 16 GB Memory.

## Pre-requisite tools/libraries install before executing the install
    ```bash
    sudo apt update
    sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y
    sudo apt-get install git -y
    sudo apt-get install jq -y
    sudo apt-get install google-cloud-sdk-kpt -y
    sudo apt-get install kubectl -y
    sudo apt-get install wget -y

    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null

    sudo apt-get install apt-transport-https --yes

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

    sudo apt-get update
    sudo apt-get install helm

    sudo wget https://github.com/mikefarah/yq/releases/download/v4.28.2/yq_linux_amd64.tar.gz -O - | tar xz && sudo mv yq_linux_amd64 /usr/bin/yq

    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
    wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update
    sudo apt-get install terraform

    curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-474.0.0-linux-x86_64.tar.gz
    tar -xf google-cloud-cli-474.0.0-linux-x86_64.tar.gz
    ./google-cloud-sdk/install.sh
    ./google-cloud-sdk/bin/gcloud init
    source ~/.bashrc

    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    kubectl version --client
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