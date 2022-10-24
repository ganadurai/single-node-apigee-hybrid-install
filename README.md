# A Single VM Hybrid Installation

This is an extension to the automated [Hybrid installation](https://cloud.google.com/apigee/docs/hybrid/preview/new-install-user-guide) focussed on executing the installation on a **single VM instance** with minimal resources (validated for GCP e2-standard-4: 4vCPU, 16GB RAM). Note: This deployment model is aimed to solve for testing and sandbox purposes, **not for production deployments**.

## Prerequisites

1. Follow the instructions [listed here](https://cloud.google.com/apigee/docs/hybrid/preview/new-install-user-guide#prerequisites1) for the tools needed for hybrid installation. 
    ```bash
    sudo apt update
    sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y
    sudo apt-get install git -y
    sudo apt-get install jq -y
    sudo apt-get install google-cloud-sdk-kpt -y
    sudo apt-get install -y kubectl
    sudo apt-get install wget
    ```

1. Install yq tool for yaml manipulation
    ```bash
    sudo wget https://github.com/mikefarah/yq/releases/download/v4.28.2/yq_linux_amd64.tar.gz -O - |  tar xz && sudo mv yq_linux_amd64 /usr/bin/yq
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
    mkdir install 
    cd install
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

1. Install [K3D](https://k3d.io/) (k3d makes it very easy to create single-node k3s clusters in docker). K3D is a wrapper to [K3S](https://k3s.io/) (K3s is a highly available, certified Kubernetes distribution designed for production workloads in unattended, resource-constrained, remote locations or inside IoT appliances.) 
    ```bash
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    ```
  
1. Create hosts entry in the /etc/hosts. This is needed for running K3D supported docker registry within the instance
    ```bash
    127.0.0.1       docker-registry
    ```

1. Create K3D cluster
    ```bash
    k3d cluster create -p "443:443" -p "10256:10256" -p "30080:30080" hybrid-cluster --registry-create docker-registry 
    ```
    
1. Validate docker registry is up and running as a docker container
    ```bash
    docker ps -f name=docker-registry
    ```
    
1. Set kubernetes context and cluster node check.
    ```bash
    export KUBECONFIG=$(k3d kubeconfig write hybrid-cluster)
    kubectl get nodes
    ```

## Prepare overlay files, before Hybrid installation

1. Execute the following script that plugs-in the resource oveerrides for the pods and pushes the files into hybrid overlays folder.
    ```bash
    cd $WORK_DIR/scripts
    ./preinstall.sh
    ```
1. Confirm the overlays files are added and kustomization files are updated
    ```bash
    cd $HYBRID_INSTALL_DIR
    git status
    ```

## Hybrid Installation

1. Install cert manager
    ```bash
    cd $HYBRID_INSTALL_DIR
    kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.7.2/cert-manager.yaml
    ```
  
1. Confirm the [environment variables](https://cloud.google.com/apigee/docs/hybrid/preview/new-install-user-guide#common-variables-used-in-this-guide) needed for installation are set. 
    ```bash
    echo "ORG_NAME=$ORG_NAME"
    echo "ENV_NAME=$ENV_NAME"
    echo "ENV_GROUP=$ENV_GROUP"
    echo "DOMAIN=$DOMAIN"
    echo "CLUSTER_NAME=$CLUSTER_NAME"
    echo "REGION=$REGION"
    echo "PROJECT_ID=$PROJECT_ID" 
    ```

1. Execute the hybrid installation 
    ```bash
    $WORK_DIR/tools/apigee-hybrid-setup.sh --org $ORG_NAME --env $ENV_NAME --envgroup $ENV_GROUP --ingress-domain $DOMAIN --cluster-name $CLUSTER_NAME --cluster-region $REGION --gcp-project-id $PROJECT_ID  --setup-all --verbose 
    ```

1. Confirm the pods in apigee namespace is either in RUNNING or COMPLETED state. Checkout the resources on the node
    ```bash
    watch kubectl get pods -n apigee (wait for all pods in completed or running state)
    $WORK_DIR/scripts/node-resources.sh
    $WORK_DIR/scripts/pod-resources.sh
    ```

## Envoy proxy Installation
Envoy proxy will serve the gateway to execute the proxies into the runtime pod.

1. Step into the folder containing envoy related artifacts
    ```bash
    cd $WORK_DIR/envoy
    ```

1. Extract the port number of the docker registry its exposed on
    ```bash
    docker_registry_forwarded_port=$(docker port docker-registry 5000)
    IFS=':' read -r -a array <<< "$docker_registry_forwarded_port"
    DOCKER_REGISTRY_PORT=${array[1]}; export DOCKER_REGISTRY_PORT
    echo $DOCKER_REGISTRY_PORT
    ```

1. Create the namespace for envoy objects
    ```bash
    kubectl create namespace envoy-ns
    ```
    
1. Build the images, substitute the variables and deploy the objects
    ```bash
    docker build -t \
    localhost:$DOCKER_REGISTRY_PORT/apigee-hybrid/single-node/envoy-proxy:v1 .

    docker push \
    localhost:$DOCKER_REGISTRY_PORT/apigee-hybrid/single-node/envoy-proxy:v1

    SERVICE_NAME=$(kubectl get svc -n ${APIGEE_NAMESPACE} -l env=eval,app=apigee-runtime --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
    echo $SERVICE_NAME
    
    #Validate the substitutin variables
    echo DOCKER_REGISTRY_PORT=$DOCKER_REGISTRY_PORT
    echo SERVICE_NAME=$SERVICE_NAME
    echo APIGEE_NAMESPACE=$APIGEE_NAMESPACE
    
    envsubst < envoy-deployment.tmpl > envoy-deployment.yaml

    kubectl apply -f envoy-deployment.yaml
    ```
    
## Executing proxy 

1. Deploy proxy bundle $WORK_DIR/envoy/helloworld.zip targetting the environment set in variable $ENV_NAME, confirm the deployment status is success. Check if the proxy name and the basepath not already exists.
    ```bash
    export MGMT_HOST="https://apigee.googleapis.com"
    curl -X POST "$MGMT_HOST/v1/organizations/$ORG_NAME/apis?action=import&name=helloworld" \
         -H "Authorization: Bearer $TOKEN" --form file=@"$WORK_DIR/helloworld.zip"
    ```

1. Test and validate the execution of proxy within the hybrid installation. 
    ```bash
    curl localhost:30080/hello-world -H 'Host: $DOMAIN'
    ```

## Tunning of pod resource requests
If further customization of the resources on the pods is needed, adjust the values within the file $WORK_DIR/scripts/fill-resource-values.sh

 