# Single Instance Hybrid Installation

This is an extension to the automated [Hybrid installation](https://cloud.google.com/apigee/docs/hybrid/preview/new-install-user-guide) , focussed on executing the installation on a VM instance with minimal resources (validated for GCP e2-standard-4: 4vCPU, 16GB RAM). Note: This deployment model is just for testing/sandbox purposes, not recommended for production.

## Prerequisites

1. Follow the instructions [listed here](https://cloud.google.com/apigee/docs/hybrid/preview/new-install-user-guide#prerequisites1) for the pre-steps and tools needed in this setup. 

1. Install yq tool for yaml manipulation
    ```
    sudo wget https://github.com/mikefarah/yq/releases/download/v4.28.2/yq_linux_amd64.tar.gz -O - |  tar xz && sudo mv yq_linux_amd64 /usr/bin/yq
    ```

1. Install the repo 
    ```
    git clone https://github.com/ganadurai/single-instance-apigee-hybrid-install.git
    cd single-instance-apigee-hybrid-install
    export WORK_DIR=$(pwd)

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
    
1. Set kubernetes context
    ```bash
    export KUBECONFIG=$(k3d kubeconfig write hybrid-cluster)
    ```
    
1. Validate kubernets context on the instance
    ```bash
    kubectl get nodes
    ```

## Hybrid Installation

1. Install cert manager
    ```bash
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

1. Confirm the pods in apigee namespace is either in RUNNING or COMPLETED state
    ```bash
    kubectl get pods
    ```

## Envoy proxy Installation
Envoy proxy will serve the gateway to execute the proxies in the runtime pod.

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
    localhost:$DOCKER_REGISTRY_PORT/apigee-hybrid/single-instance/envoy-proxy:v2 .

    docker push \
    localhost:$DOCKER_REGISTRY_PORT/apigee-hybrid/single-instance/envoy-proxy:v2

    SERVICE_NAME=$(kubectl get svc -n ${APIGEE_NAMESPACE} -l env=eval,app=apigee-runtime --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
    echo $SERVICE_NAME

    envsubst < envoy-deployment.tmpl > envoy-deployment.yaml

    kubectl delete -f envoy-deployment.yaml
    kubectl apply -f envoy-deployment.yaml
    ```
    
## Executing proxy 

1. Deploy proxy bundle $WORK_DIR/envoy/helloworld.zip in the environment set in variable $ENV, confirm the deployment status is success.

1. Test the proxy from within the instance
    ```bash
    curl localhost:30080/hello-world -H 'Host: $DOMAIN'
    ```
    

 