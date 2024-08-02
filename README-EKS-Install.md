# Hybrid Installation on Mac

To enable quick test and validation of Apigee Hybrid on EKS with 16 GB Memory as worker node. 
To run the install in the AWS environment we employ an t2.micro Amazon linux instance as Launch Instance

## Log into 'Launch Instance and install pre-requisite tools/libraries
    ```bash
    sudo yum install git

    curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-478.0.0-linux-x86_64.tar.gz
    tar -xf google-cloud-cli-478.0.0-linux-x86_64.tar.gz
    ./google-cloud-sdk/install.sh
    source ~/.bashrc
    ```

### Prepare the directories
    ```bash
    mkdir ~/install
    cd ~/install
    export INSTALL_DIR=$(pwd)
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

### Log into AWS
    ```bash
    #Set the aws keys, refer https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-envvars.html#envvars-set
   
    export CLUSTER_NAME=hybrid-cluster
    export EKS_REGION=us-east-2
    export NODEGROUP_NAME=hybrid-cluster-nodegroup2
    
    export ACCOUNT_ID=$(aws sts get-caller-identity | jq .Account | cut -d '"' -f 2)
    export CASS_STORAGE_CLASS="ebs-sc"
    
    #Set the aws keys, refer https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-envvars.html#envvars-set
    
    aws configure
    ```

## Install and Validate
    ```bash
    cd $WORK_DIR/scripts/

    alias cmdscript="$WORK_DIR/scripts/install-eks-apigee-hybrid.sh "
    ```

## Prepare EKS cluster
    ```bash
    cmdscript --install-tools
    cmdscript --create-cluster;date
    #Not Needed
    #aws eks update-kubeconfig --region "$EKS_REGION" --name "$CLUSTER_NAME"
    #kubectl -n apigee patch pvc cassandra-data-apigee-cassandra-default-0 -p '{"spec": {"storageClassName":"gp2"}}'
    ```

## Log into GCP
    ```bash
    gcloud auth application-default login
    gcloud auth login $USER_ID	
    gcloud config set project $PROJECT_ID
    export TOKEN=$(gcloud auth print-access-token)
    ```

## Install Apigee Hybrid on EKS
    ```bash
    cmdscript --project-create
    cmdscript --apigee-org-create
    cmdscript --prep-install-dirs
    cmdscript --install-hybrid
    cmdscript --install-ingress
    ```

### Validation
    ```bash
    echo "EKS cluster running, logging in..."
    aws eks update-kubeconfig --region "$EKS_REGION" --name "$CLUSTER_NAME"
    alias k="kubectl "
    alias ka="kubectl -n apigee"
    alias ks="kubectl -n apigee-system"
    alias wa="watch kubectl get pods -n apigee"
    ```