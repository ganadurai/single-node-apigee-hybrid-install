***This deployment model is intended ONLY for testing and sandbox purposes, **NOT for production deployments**. This setup is **NOT covered under any form of Google support**.***

# Single Node (all-in-one) Hybrid Installation

For simple tests and validation of Apigee Hybrid, are you concerned about the high platform cost and the effort involved in setting it up?

This tool solves your concerns. 

* Reduces the cost of running Apigee Hybrid to a minimum of $100 per month, compared to the standard Hybrid operating cost of $800 or more
* Provides end-to-end automation, starting with setup of GCP project, configuring an Apigee org and deploying Hybrid on an instance. (single step install)

This implementation is built on top of the currently revamped [Hybrid installation](https://cloud.google.com/apigee/docs/hybrid/preview/new-install-user-guide) procedures. It follows the recommended [Kustomize tool overrides](https://cloud.google.com/apigee/docs/hybrid/preview/new-install-user-guide#kustomize-and-components) approach to keep the Hybrid container resources to a minimum, so all resources can be stood up on a single VM node (4vCPU, 16GB RAM).

This deployment model is intended ONLY for testing and sandbox purposes, **NOT for production deployments**. This setup is **NOT covered under any form of Google support**.

## Apigee Hybrid on a single node GKE cluster

### Prerequisites

Execute this toolkit from within the Cloudshell of GCP console. (All the needed tools for this install is already configured and available). 

If following this installation outside of CloudShell, refer to this [section](#libraries) to install the needed tools/libraries for this implementation.

    
### Download installation source

1. Prepare the directories
    ```bash
    mkdir ~/install
    cd ~/install
    export INSTALL_DIR=$(pwd)
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
    export ORG_ADMIN="<gcp account email>"
    gcloud auth login $ORG_ADMIN

    TOKEN=$(gcloud auth print-access-token); export TOKEN;
    ```

### Install and Validate

1. Step into the install directory
    ```bash
    cd $WORK_DIR/scripts
    ```
    
1. Choose from one of the below deployment models:

* Create GCP project, Apigee Org and deploy Apigee Hybrid
    ```bash
    ./install-gke-apigee-hybrid.sh --project-create --setup-all

    # Note: Coninue on the warning message that the project doesn't exist yet.
    ```
    
* Create Apigee Org within an existing GCP Project and deploy Apigee Hybrid.
    ```bash
    ./install-gke-apigee-hybrid.sh --apigee-org-create --setup-all
    ```

* Deploy Apigee Hybrid on an existing GCP project with Apigee Org instantiated already.
    ```bash
    ./install-gke-apigee-hybrid.sh --setup-all
    ```
    
3. Post installation, log into the cluster, view and confirm the running pods.
    ```bash
    gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"
    kubectl -n apigee get pods
    ```

4. Test the proxy deployed in the environment
    ```bash
    gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"
    
    export INGRESS_IP_ADDRESS=$(kubectl -n apigee get svc -l app=apigee-ingressgateway -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
    export DOMAIN="test.hapigee.com"
    
    curl "https://$DOMAIN/apigee-hybrid-helloworld" --resolve "$DOMAIN:443:$INGRESS_IP_ADDRESS" -k -i

    # If deploying a new proxy, update the above curl with the basepath of the proxy.
    
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
    SERVICE_NAME=$(kubectl get svc -n ${APIGEE_NAMESPACE} -l env="$ENV_NAME",app=apigee-runtime \
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

## Support Tools Install

### Libraries
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
    ```

 ### Docker Install
    ```
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
    
