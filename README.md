# Single VM (all-in-one) Hybrid Installation

This is an extension to the automated [Hybrid installation](https://cloud.google.com/apigee/docs/hybrid/preview/new-install-user-guide) focussed on executing the installation on a **single VM instance** with minimal resources (validated for GCP e2-standard-4: 4vCPU, 16GB RAM, 20GB disk). This deployment model is aimed for just  testing and sandbox purposes, **NOT for production deployments**. Also please note, this set up is **NOT covered under any form of Google support**. 

## Modes of deployment

* [Deploy single node GKE with terraform and install Apigee Hybrid](#gke-deploy-with-terraform-and-hybrid-install)

* [Deploy gcp VM instance with terraform and install Apigee Hybrid](#gcp-vm-deploy-with-terraform-and-hybrid-install)

* [On a existing VM Instance, install Apigee Hybrid](#standalone-vm-hybrid-install)


## GKE Deploy (with terraform) and Hybrid Install

### Prerequisites

1. Install Terraform on the machine that initiates the install.

1. Setup Environment variables
    ```bash
    export PROJECT_ID=<gcp-project-id>
    export ORG_NAME=<optional, apigee-org-name>
    export REGION=<region>
    export CLUSTER_NAME=<cluster-name>
    export ENV_NAME=<environment name>
    export ENV_GROUP=<environment group name>
    export DOMAIN=<environment group hostname>
    export APIGEE_NAMESPACE="apigee"
    export USE_GKE_GCLOUD_AUTH_PLUGIN=True
    ```

1. Install the tools needed. (git, google-cloud-sdk-gke-gcloud-auth-plugin, jq, kpt, kubectl, wget, docker). Execute the below commands to setup the tools in the instance, if missing in the instance where the setup is executed.
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

    # Host entry
    sudo -- sh -c "echo 127.0.0.1       docker-registry >> /etc/hosts";

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

1. Execute the gcloud auth and fetch the token
    ```bash
    gcloud config set project $PROJECT_ID
    ORG_ADMIN="<gcp account email>"
    gcloud auth login $ORG_ADMIN

    TOKEN=$(gcloud auth print-access-token); export TOKEN; echo "$TOKEN"
    ```

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

### Install and Validate
    
1. Execute the hybrid install. (takes around ~20 minutes)
    ```bash
    cd $WORK_DIR/scripts
    ./install-gke-apigee-hybrid.sh
    ```


## GCP VM Deploy (with terraform) and Hybrid Install

### Prerequisites

1. Install Terraform on the machine that initiates the install.

1. Setup Environment variables
    ```bash
    export PROJECT_ID=<gcp-project-id>
    export ORG_NAME=<optional, apigee-org-name>
    export REGION=<region>
    export CLUSTER_NAME=<cluster-name>
    export ENV_NAME=<environment name>
    export ENV_GROUP=<environment group name>
    export DOMAIN=<environment group hostname>
    export APIGEE_NAMESPACE="apigee"
    ```

1. Execute the gcloud auth and fetch the token
    ```bash
    gcloud config set project $PROJECT_ID
    ORG_ADMIN="<gcp account email>"
    gcloud auth login $ORG_ADMIN

    TOKEN=$(gcloud auth print-access-token); export TOKEN; echo "$TOKEN"
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

1. Execute the terraform commands
    ```bash
    $WORK_DIR/scripts/install-gcp-vm-apigee-hybrid.sh
    ```

1. Checkout [gcp cloud logging](https://console.cloud.google.com/logs/query;query=resource.type%3D%22gce_instance%22%0Astartup-script%20exit%20status%200) for the project where the VM is created, wait for startup script completion for installation of Docker (should see an entry 'startup-script exit status 0'. Should not take more than 3 minutes)

1. Execute the installation on the deployed VM, [follow the steps starting here.](#install-and-validation)
    

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

1. Confirm the below docker command executed successfully. If not make sure docker is installed (if above step is followed for docker install, relaunch the ssh session)
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
    export APIGEE_NAMESPACE="apigee"
    ```

### Install and Validation

1. Execute the gcloud auth and fetch the token
    ```bash
    gcloud config set project $PROJECT_ID
    gcloud auth login $ORG_ADMIN

    TOKEN=$(gcloud auth print-access-token); export TOKEN; echo "$TOKEN"
    ```

1. Run the execution, this installs the needed libraries, K3D cluster, creates the overlay files, deploy the Hybrid containers and Ingress Envoy proxy. (takes around ~20 minutes)
    ```bash
    cd $WORK_DIR/scripts
    ./install-vm-apigee-hybrid.sh
    ```
  
1. Test and validate the execution of proxy within the hybrid installation. 
    ```bash
    curl localhost:30080/hello-world -H 'Host: $DOMAIN'
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