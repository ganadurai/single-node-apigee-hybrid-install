# Hybrid Installation on Mac

To enable quick test and validation of Apigee Hybrid on a Mac with 16 GB Memory.

## Pre-requisite tools/libraries install before executing the install
    ```bash

    install yq
    install jq
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
    set INSTALL_DIR=<Install Dir where this source will be downloaded>
    cd %INSTALL_DIR%
    ```
    
### Install the repos 
    ```bash
    cd %INSTALL_DIR%
    git clone https://github.com/ganadurai/single-node-apigee-hybrid-install.git
    cd single-node-apigee-hybrid-install
    set WORK_DIR=%cd%
    ```

### Setup Environment variables and tokens 
    ```bash
    set USER_ID=<gcp-login-email>
    set PROJECT_ID=<gcp-project-id>
    set BILLING_ACCOUNT_ID=<gcp-billing-id>
    set CLUSTER_NAME=<eks-cluster-name>

    set ORG_ID=<gcp-project-org-id, if organization id is not available you can provide 'organizations/0'> 

    set ANALYTICS_REGION=<gcp-analytics-region, you can use 'us-east1' as default>

    echo "all properties set..." 
    ```

### Log into GCP
    ```bash
    gcloud auth application-default login
    gcloud auth login $USER_ID --force
    gcloud config set project $PROJECT_ID
    for /f %%i in ('gcloud auth print-access-token') do set TOKEN=%%i
    ```

### Set environment variables
    ```bash
    set ENV_NAME="test-env"
    set DOMAIN="test.apigeehybrid.com"
    set ENV_GROUP="test-env-group"

    set ORG_ADMIN=%USER_ID%
    set ORG_NAME=%PROJECT_ID%
    set REGION=%ANALYTICS_REGION%
    set RUNTIMETYPE=HYBRID

    set CHART_REPO=oci://us-docker.pkg.dev/apigee-release/apigee-hybrid-helm-charts
    set CHART_VERSION=1.13.0
    set CERT_MGR_DWNLD_YAML=https://github.com/cert-manager/cert-manager/releases/download/v1.15.1/cert-manager.yaml

    set APIGEE_HYBRID_BASE=%WORK_DIR%/../APIGEE_HYBRID_BASE_%PROJECT_ID%
    set APIGEE_HELM_CHARTS_HOME=%APIGEE_HYBRID_BASE%/EDIT_APIGEE_HELM_CHARTS_HOME
    set APIGEE_HELM_CHARTS_HOME_ORIG=%APIGEE_HYBRID_BASE%/ORIG_APIGEE_HELM_CHARTS_HOME

    set SA_FILE_NAME=%PROJECT_ID%-apigee-non-prod

    set uidgen_userval=dsdljs-s9294-cnd2e3-lvns233
    for /f %i in ('echo uuidgen_userval') do set UUIDGEN=%i
    for /f %i in ('echo %UUIDGEN:-=%') do set UUIDGENVAL=%i

    set UNIQUE_INSTANCE_IDENTIFIER=%UUIDGENVAL% 

    set APIGEE_NAMESPACE=apigee
    set CLUSTER_LOCATION=%ANALYTICS_REGION%
    set ENVIRONMENT_GROUP_NAME=%ENV_GROUP%
    set ENVIRONMENT_NAME=%ENV_NAME%
    set INGRESS_NAME=%ENV_GROUP%-i
    set INGRESSGATEWAY_REPLICAS_MAX=3
    set NON_PROD_SERVICE_ACCOUNT_FILEPATH=%SA_FILE_NAME%.json

    set PATH_TO_CERT_FILE=certs/keystore_%ENV_GROUP%.pem
    set PATH_TO_KEY_FILE=certs/keystore_%ENV_GROUP%.key
    ```

## Install/Setup Project
    ```bash
    gcloud projects create $PROJECT_ID
    gcloud alpha billing projects link %PROJECT_ID% --billing-account=%BILLING_ACCOUNT_ID%
    gcloud services enable --project=%PROJECT_ID% \
      apigee.googleapis.com \
      apigeeconnect.googleapis.com \
      cloudapis.googleapis.com \
      cloudresourcemanager.googleapis.com \
      compute.googleapis.com \
      dns.googleapis.com \
      iam.googleapis.com \
      iamcredentials.googleapis.com \
      pubsub.googleapis.com \
      servicemanagement.googleapis.com \
      serviceusage.googleapis.com \
      storage-api.googleapis.com \
      storage-component.googleapis.com
    ```

## Apigee org create
    ```bash
    cd "%WORK_DIR%"/terraform-modules/apigee-install

    if exist "install-state.txt" (
        set /p last_project_id=<install-state.txt
        if "%last_project_id%" != "%PROJECT_ID%" (
            echo "Clearing up the terraform state"
            rm -Rf .terraform*
            rm -f terraform.tfstate
        )
    ) 

    # Validate the org and env name and the virtualhost on the below file
    # $WORK_DIR/terraform-modules/apigee-install/apigee.tfvars

    echo "%PROJECT_ID%" > install-state.txt

    terraform init
    terraform plan -var "apigee_org_create=true" \
        -var "project_id=$PROJECT_ID" --var-file="$WORK_DIR/terraform-modules/apigee-install/apigee.tfvars" \
        -var "ax_region=$AX_REGION"
    terraform apply -auto-approve -var "apigee_org_create=true" \
        -var "project_id=$PROJECT_ID" --var-file="$WORK_DIR/terraform-modules/apigee-install/apigee.tfvars" \
        -var "ax_region=$AX_REGION"

    ```

## Download Helm charts
    ```bash
    IF exist "%APIGEE_HYBRID_BASE%" (
    ) ELSE (
        mkdir %APIGEE_HYBRID_BASE%
    )

    IF exist "%APIGEE_HELM_CHARTS_HOME_ORIG%" (
    ) ELSE (
        mkdir %APIGEE_HELM_CHARTS_HOME_ORIG%
        cd %APIGEE_HELM_CHARTS_HOME_ORIG%
        helm pull $CHART_REPO/apigee-operator --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-datastore --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-env --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-ingress-manager --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-org --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-redis --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-telemetry --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-virtualhost --version $CHART_VERSION --untar
    )

    IF exist "%APIGEE_HELM_CHARTS_HOME%" (
    ) ELSE (
        mkdir %APIGEE_HELM_CHARTS_HOME%
        cd %APIGEE_HELM_CHARTS_HOME%
        helm pull $CHART_REPO/apigee-operator --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-datastore --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-env --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-ingress-manager --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-org --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-redis --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-telemetry --version $CHART_VERSION --untar
        helm pull $CHART_REPO/apigee-virtualhost --version $CHART_VERSION --untar
    )
    ```

## Create APigee Namespace
    ```bash
    kubectl get namespace %APIGEE_NAMESPACE%
    kubectl create namespace %APIGEE_NAMESPACE%
    ```

## Create service account - this could be done of the gcp console if the gcloud cli is not available
    ```bash
    if exist "%APIGEE_HELM_CHARTS_HOME%/apigee-datastore/%SA_FILE_NAME%.json" (
    ) ELSE (
        echo "Creating Service Accounts"
        chmod +x %APIGEE_HELM_CHARTS_HOME%/apigee-operator/etc/tools/create-service-account

        %APIGEE_HELM_CHARTS_HOME%/apigee-operator/etc/tools/create-service-account \
            --env non-prod \
            --dir %APIGEE_HELM_CHARTS_HOME%/apigee-datastore
        
        cp %APIGEE_HELM_CHARTS_HOME%/apigee-datastore/%SA_FILE_NAME%.json %APIGEE_HELM_CHARTS_HOME%/apigee-telemetry/
        cp %APIGEE_HELM_CHARTS_HOME%/apigee-datastore/%SA_FILE_NAME%.json %APIGEE_HELM_CHARTS_HOME%/apigee-org/
        cp %APIGEE_HELM_CHARTS_HOME%/apigee-datastore/%SA_FILE_NAME%.json %APIGEE_HELM_CHARTS_HOME%/apigee-env/

        echo "waiting 10s for the newly created service account to sync"

    )
    ```

## Step 5: Create TLS certificates
    ```bash
    if exist "%APIGEE_HELM_CHARTS_HOME%/apigee-virtualhost/certs" (
    ) ELSE (
        echo "Creating self signed certs"
        mkdir %APIGEE_HELM_CHARTS_HOME%/apigee-virtualhost/certs

        openssl req  -nodes -new -x509 -keyout %APIGEE_HELM_CHARTS_HOME%/apigee-virtualhost/certs/keystore_%ENV_GROUP%.key -out \
            %APIGEE_HELM_CHARTS_HOME%/apigee-virtualhost/certs/keystore_%ENV_GROUP%.pem -subj '/CN='%DOMAIN%'' -days 3650
        ls %APIGEE_HELM_CHARTS_HOME%/apigee-virtualhost/certs
    else (
        echo "Certs already existing, so skipping creation"
    )
    ```

## Step 6: Create the overrides
    ```bash
    sh %WORK_DIR%/scripts/helm/set-overrides.sh
    ```

## Step 7: Enable Synchronizer access - this could be done of the gcp console if the gcloud cli is not available
    ```bash
    echo "Required permission for Synchronizer getting added"
    curl -s -X POST -H "Authorization: Bearer %TOKEN%" \
        -H "Content-Type:application/json" \
        "https://apigee.googleapis.com/v1/organizations/%ORG_NAME%:setSyncAuthorization" \
        -d '{"identities":["'"serviceAccount:apigee-non-prod@%PROJECT_ID%.iam.gserviceaccount.com"'"]}'

    sleep 10

    SRVC_ACCNT_SYNC_STATUS=$(curl -s -X GET -H "Authorization: Bearer %TOKEN%" \
        -H "Content-Type:application/json" \
        "https://apigee.googleapis.com/v1/organizations/%ORG_NAME%:getSyncAuthorization" \
        grep serviceAccount:apigee-non-prod@%PROJECT_ID%.iam.gserviceaccount.com | jq ".identities[0]" | cut -d '"' -f 2)
    if ( %SRVC_ACCNT_SYNC_STATUS% == "serviceAccount:apigee-non-prod@%PROJECT_ID%.iam.gserviceaccount.com" )
        echo "srvc account sync set"
    else (
        echo "srvc account sync not set"
        exit 1;
    )
    ```

## Step 8: Install cert manager - Log into cluster & Install
    ```bash
    # Execute AWS login before executing the below step
    aws eks update-kubeconfig --name %CLUSTER_NAME%

    kubectl apply -f $CERT_MGR_DWNLD_YAML
    
    kubectl get all -n cert-manager -o wide

    cd $APIGEE_HELM_CHARTS_HOME
    ```

## Step 9: Install the CRDs
    ```bash
    cd $APIGEE_HELM_CHARTS_HOME


    kubectl apply -k  apigee-operator/etc/crds/default/ \
        --server-side \
        --force-conflicts \
        --validate=false \
        --dry-run=server
    
    kubectl apply -k  apigee-operator/etc/crds/default/ \
        --server-side \
        --force-conflicts \
        --validate=false
    
    apigee_crds=$(kubectl get crds | grep apigee | wc -l)
    if $apigee_crds -eq 10 (
        echo "apigee-operator CRD installed"
    )
    
    ```

## Step 10: Install Apigee hybrid Using Helm
    ```bash
    # Execute the steps from the google docs
    ```

## Install and Validate
    ```bash
    
    %WORK_DIR%/scripts/install-node-apigee-hybrid.sh --project-create
    %WORK_DIR%/scripts/install-node-apigee-hybrid.sh --apigee-org-create
    %WORK_DIR%/scripts/install-node-apigee-hybrid.sh --create-cluster
    %WORK_DIR%/scripts/install-node-apigee-hybrid.sh --prep-install-dirs
    %WORK_DIR%/scripts/install-node-apigee-hybrid.sh --install-hybrid
    cmdsc%WORK_DIR%/scripts/install-node-apigee-hybrid.shript --install-ingress
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