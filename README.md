# Single Node (all-in-one) Hybrid Installation

For executing simple tests or validation in a Hybrid deployment are you worried about the cost associated and the time consumed in the setups?? 

This tool solves these concerns. It overrides the resource needs for the Hybrid containers and make it possible to deploy on a single VM node (4vCPU, 16GB RAM). This makes the cost associated with Hybird installation less than $100 per month instead of more than $800.

This tool also provides end-to-end automation of creating a GCP project, configuring an Apigee org and deploying Hybrid on a instance.

This implementation is an extension to the automated [Hybrid installation](https://cloud.google.com/apigee/docs/hybrid/preview/new-install-user-guide). This deployment model is aimed for just testing and sandbox purposes, **NOT for production deployments**. Also please note, this set up is **NOT covered under any form of Google support**. 

## Modes of deployment

* [Deploy Apigee Hybrid on a single node GKE cluster](#apigee-hybrid-on-a-single-node-gke-cluster)

* [Deploy Apigee Hybrid on a single VM instance](#apigee-hybrid-on-a-single-vm-instance)

## Apigee Hybrid on a single node GKE cluster

### Prerequisites

Execute this toolkit from within the Cloudshell of GCP console. (All the needed tools for this install is already configured and available). 

If following this installation outside of CloudShell, follow the next two steps to get the needed tools and libraries.

1. Install Terraform on the machine that initiates the install. [Linux Install](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

1. Install the tools needed on the machine where the deployment is executed. (git, google-cloud-sdk-gke-gcloud-auth-plugin, jq, kpt, kubectl, wget, docker). Execute the below commands to setup the tools in the instance, if missing in the instance where the setup is executed.
    ```bash
    sudo apt update
    sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y
    sudo apt-get install git -y
    sudo apt-get install jq -y
    sudo apt-get install google-cloud-sdk-kpt -y
    sudo apt-get install kubectl -y
    sudo apt-get install wget -y

    sudo wget https://github.com/mikefarah/yq/releases/download/v4.28.2/yq_linux_amd64.tar.gz -O - | \
    tar xz && sudo mv yq_linux_amd64 /usr/bin/yq

    # Docker Install
    sudo apt install --yes apt-transport-https ca-certificates curl gnupg2 software-properties-common
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    echo "Waiting for 10s..."
    sleep 10
    sudo apt-get update
    sudo apt install --yes docker-ce
    sudo usermod -aG docker $USER

    printf "\n\n\nPlease close your shell session and reopen for the installs to be configured correctly !!\n\n"
    ```
    
### Download install libraries

1. Prepare the directories
    ```bash
    mkdir ~/install
    cd ~/install
    ```
    
1. Install the repos 
    ```bash
    git clone https://github.com/ganadurai/single-node-apigee-hybrid-install.git
    cd single-node-apigee-hybrid-install
    export WORK_DIR=$(pwd)
    
    cd $INSTALL_DIR  
    
    git clone https://github.com/apigee/apigee-hybrid-install.git
    cd apigee-hybrid-install
    export HYBRID_INSTALL_DIR=$(pwd)
    ```

### Setup Environment variables and tokens

1. Setup Environment variables
    ```bash
    export PROJECT_ID=<gcp-project-id>
    export ORG_NAME=<optional, apigee-org-name>
    export REGION=<region>
    export CLUSTER_NAME=<cluster-name>
    export ENV_NAME=<environment name>
    export ENV_GROUP=<environment group name>
    export DOMAIN=<environment group hostname>
    export USE_GKE_GCLOUD_AUTH_PLUGIN=True
    export BILLING_ACCOUNT_ID=<billing account-id> #Required, if opted to let the tool to spin up a GCP project
    ```

1. Execute the gcloud auth and fetch the token
    ```bash
    gcloud config set project $PROJECT_ID
    ORG_ADMIN="<gcp account email>"
    gcloud auth login $ORG_ADMIN

    TOKEN=$(gcloud auth print-access-token); export TOKEN;
    ```

### Install and Validate

1. Step into the install directory
    ```bash
    cd $WORK_DIR/scripts
    ```
    
1. Choose from one of the below deployment models:

* Execute Hybrid installation with a new GCP project and Apigee org created within it.
    ```bash
    ./install-gke-apigee-hybrid.sh --project-create --setup-all
    ```
    
* Execute Hybrid installation on an existing GCP project with Apigee org created within it.
    ```bash
    ./install-gke-apigee-hybrid.sh --apigee-org-create --setup-all
    ```

* Execute Hybrid installation on an existing GCP project with Apigee hybrid org instantiated already.
    ```bash
    ./install-gke-apigee-hybrid.sh --setup-all
    ```
    
1. Post installation, log into the cluster and view the pods.
    ```bash
    gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"
    kubectl -n apigee get pods
    ```

## Apigee Hybrid on a single VM instance

Minimum Spec needed :  4vCPU, 16GB RAM

Choose one from the two options below:
* [Execute the installation on a GCP VM.](#gcp-vm-installation)
* [Execute the installation on Standalone VM.](#standalone-vm-hybrid-install)
 
### GCP VM Installation

1. Execute this installation toolkit from within the Cloudshell of GCP console. (All the needed tools for this install is already configured and available). 

1. Setup Environment variables
    ```bash
    export PROJECT_ID=<gcp-project-id>
    export ORG_NAME=<optional, apigee-org-name>
    export REGION=<region>
    export CLUSTER_NAME=<cluster-name>
    export ENV_NAME=<environment name>
    export ENV_GROUP=<environment group name>
    export DOMAIN=<environment group hostname>
    export BILLING_ACCOUNT_ID=<billing account-id> #Required, if opted to let the tool to spin up a GCP project
    ```

1. Execute the gcloud auth and fetch the token
    ```bash
    gcloud config set project $PROJECT_ID
    ORG_ADMIN="<gcp account email>"
    gcloud auth login $ORG_ADMIN

    TOKEN=$(gcloud auth print-access-token); export TOKEN;
    ```

1. Prepare the directories
    ```bash
    mkdir ~/install
    cd ~/install
    ```
    
1. Install the repo on the machine that executes the install
    ```bash
    git clone https://github.com/ganadurai/single-node-apigee-hybrid-install.git
    cd single-node-apigee-hybrid-install
    export WORK_DIR=$(pwd)
    ```

1. Execute installation
    ```bash
    cd $WORK_DIR/scripts/
    
    # If you prefer the VM to be created with an new Project with Apigee org configured use the commande below
    ./deploy-gcp-vm.sh --project-create --create-vm
    
    # If you prefer the VM to be created within an existing Project with Apigee org
    ./deploy-gcp-vm.sh --create-vm
    
    ```

1. Checkout the instructions at the end of the installation output. 

1. SSH into the created VM to complete the Hybrid installation, [follow the steps starting here.](#install-and-validation)
    

## Standalone VM Hybrid Install

### Prerequisites

1. Following tools are needed for this setup (git, google-cloud-sdk-gke-gcloud-auth-plugin, jq, kpt, kubectl, wget, docker). Execute the below commands to setup the tools in the instance.
    ```bash
    sudo apt update
    sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y
    sudo apt-get install git -y
    sudo apt-get install jq -y
    sudo apt-get install google-cloud-sdk-kpt -y
    sudo apt-get install kubectl -y
    sudo apt-get install wget -y

    sudo wget https://github.com/mikefarah/yq/releases/download/v4.28.2/yq_linux_amd64.tar.gz -O - | \
    tar xz && sudo mv yq_linux_amd64 /usr/bin/yq

    sudo -- sh -c "echo 127.0.0.1       docker-registry >> /etc/hosts";

    sudo apt install --yes apt-transport-https ca-certificates curl gnupg2 software-properties-common
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    echo "Waiting for 10s..."
    sleep 10
    sudo apt-get update
    sudo apt install --yes docker-ce
    sudo usermod -aG docker $USER

    printf "\n\n\nPlease close your shell session and reopen for the installs to be configured correctly !!\n\n"
    ```

1. Confirm docker is ready and running on the VM instance
    ```bash
    docker images
    ```

1. Prepare the directories
    ```bash
    mkdir ~/install
    cd ~/install
    export INSTALL_DIR=$(pwd);
    ```

1. Install the repos 
    ```bash
    git clone https://github.com/ganadurai/single-node-apigee-hybrid-install.git
    cd single-node-apigee-hybrid-install
    export WORK_DIR=$(pwd)
    
    cd $INSTALL_DIR  
    
    git clone https://github.com/apigee/apigee-hybrid-install.git
    cd apigee-hybrid-install
    export HYBRID_INSTALL_DIR=$(pwd)

    cd $WORK_DIR
    ```

1. Setup Environment variables
    ```bash
    export PROJECT_ID=<gcp-project-id>
    export ORG_NAME=<optional, apigee-org-name>
    export REGION=<region>
    export CLUSTER_NAME=<cluster-name>
    export ENV_NAME=<environment name>
    export ENV_GROUP=<environment group name>
    export DOMAIN=<environment group hostname>
    export ORG_ADMIN=<gcp account email>
    ```

### Install and Validation

1. Execute the gcloud auth and fetch the token
    ```bash
    gcloud config set project $PROJECT_ID
    ORG_ADMIN="<gcp account email>"
    gcloud auth login $ORG_ADMIN

    TOKEN=$(gcloud auth print-access-token); export TOKEN;
    ```

1. Run the execution, this installs the needed libraries, K3D cluster, creates the overlay files, deploy the Hybrid containers and Ingress Envoy proxy. (takes around ~20 minutes)
    ```bash
    cd $WORK_DIR/scripts
    
    ./install-vm-apigee-hybrid.sh --setup-all
    ```
  
1. Test and validate the execution of proxy within the hybrid installation. 
    ```bash
    curl localhost:30080/apigee-hybrid-helloworld -H 'Host: $DOMAIN'
    ```

## Tunning of pod resource requests

If further customization of the resources on the pods is needed, adjust the values within the file $WORK_DIR/scripts/fill-resource-values.sh

## Troubleshooting

1. Hybrid installation timing out on webhook errors, rerun the install.

1. Issue during install with error "(gcloud.iam.service-accounts.keys.create) FAILED_PRECONDITIO". Clear up the unused keys for the Service account "apigee-all-sa" this install uses.

1. Failure on proxy execution: Verify the runtime pod has the proxy artifacts deployed and accessible within the pod
    ```bash
    RUNTIME_POD=$(kubectl -n ${APIGEE_NAMESPACE} get pods -l app=apigee-runtime --template \
    '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
    kubectl -n apigee exec --stdin --tty -c apigee-runtime $RUNTIME_POD -- \
    curl https://localhost:8443/hello-world -k -H 'Host: $DOMAIN'
    ```
    
1. Failure on proxy execution: Verify the runtime pod service is accessible from within the envoy proxy pod
    ```bash
    ENVOY_POD=$(kubectl -n envoy-ns get pods -l app=envoy-proxy \
    --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
    SERVICE_NAME=$(kubectl get svc -n ${APIGEE_NAMESPACE} -l env=eval,app=apigee-runtime \
    --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
    kubectl -n envoy-ns exec --stdin --tty $ENVOY_POD -- \
    curl https://${SERVICE_NAME}.${APIGEE_NAMESPACE}.svc.cluster.local:8443/hello-world -k -H 'Host: $DOMAIN'
    ```
    
1. Confirm the pod status in the ${APIGEE_NAMESPACE} and envoy-ns namespaces
    ```bash
    kubectl -n ${APIGEE_NAMESPACE} get pods
    kubectl -n envoy-ns get pods
    ```

1. Confirm the pod request resources are applied as defined in this setup
    ```bash
    $WORK_DIR/scripts/pod-resources.sh
    $WORK_DIR/scripts/node-resources.sh
    ```