# A Single VM Hybrid Installation

This is an extension to the automated [Hybrid installation](https://cloud.google.com/apigee/docs/hybrid/preview/new-install-user-guide) focussed on executing the installation on a **single VM instance** with minimal resources (validated for GCP e2-standard-4: 4vCPU, 16GB RAM, 20GB disk). This deployment model is aimed for just  testing and sandbox purposes, **NOT for production deployments**. Also please note, this set up is **NOT covered under any form of Google support**. 

## Modes of deployment

* [Deploy new gcp instance with Terraform and install Hybrid Runtime plane](#terraform-gcp-vm-deploy-and-hybrid-install)

* [On a existing VM Instance, install Hybrid Runtime](#standalone-vm-hybrid-install)

## Terraform GCP VM Deploy and Hybrid Install

## Prerequisites

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
    sudo mkdir ~/install
    cd ~/install
    ```
    
1. Install the repo 
    ```bash
    git clone https://github.com/ganadurai/single-node-apigee-hybrid-install.git
    cd single-node-apigee-hybrid-install
    export WORK_DIR=$(pwd)
    cd $WORK_DIR/terraform-modules/vm-install
    ```

1. Execute the terraform commands
    ```bash
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
    
    terraform apply -auto-approve \
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
    ```

1. Checkout [gcp cloud logging](https://console.cloud.google.com/logs/query;query=resource.type%3D%22gce_instance%22%0Astartup-script%20exit%20status%200) for the project where the VM is created, wait for startup script completion for installation of Docker (should seen an entry 'startup-script exit status 0')

1. Execute the installation on the deployed VM, [follow the steps starting here.](#install-and-validation)
    

## Standalone VM Hybrid Install

## Prerequisites

1. Install docker on the machine.

1. Setup Environment variables
    ```bash
    export PROJECT_ID=<gcp-project-id>
    export ORG_NAME=<optional, apigee-org-name>
    export REGION=<region>
    export CLUSTER_NAME=<cluster-name>
    export ENV_NAME=<environment name>
    export ENV_GROUP=<environment group name>
    export DOMAIN=<environment group hostname>
    export ORG_ADMIN="<gcp account email>"
    ```

1. Prepare the directories
    ```bash
    mkdir ~/install
    cd ~/install
    export INSTALL_DIR=$(pwd);
    ```

1. Install git tool
    ```bash
    sudo apt update
    sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y
    sudo apt-get install git -y
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

## Install and Validation

1. Execute the gcloud auth and fetch the token
    ```bash
    gcloud config set project $PROJECT_ID
    gcloud auth login $ORG_ADMIN

    TOKEN=$(gcloud auth print-access-token); export TOKEN; echo "$TOKEN"
    ```

1. Run the execution, this installs the needed libraries, K3D cluster, creates the overlay files, deploy the Hybrid containers and Ingress Envoy proxy.
    ```bash
    cd $WORK_DIR/scripts
    ./install.sh --all
    ```
  
1. Test and validate the execution of proxy within the hybrid installation. 
    ```bash
    curl localhost:30080/hello-world -H 'Host: $DOMAIN'
    ```

## Tunning of pod resource requests

If further customization of the resources on the pods is needed, adjust the values within the file $WORK_DIR/scripts/fill-resource-values.sh

## Troubleshooting

1. Hybrid installation timing out on cert-manager webhook error, rerun the install with "--install-hybrid" flag.
    ```bash
    cd $WORK_DIR/scripts
    ./install.sh --install-hybrid   
    ```

1. Hybrid installation completes and issue in Envoy proxy ingress creation, re-run the install with --install-ingress flag.
    ```bash
    cd $WORK_DIR/scripts
    ./install.sh --install-ingress   
    ```

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