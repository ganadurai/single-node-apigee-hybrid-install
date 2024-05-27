#!/bin/bash

set -e

function fixOverridesFile() {

    echo UNIQUE_INSTANCE_IDENTIFIER = $UNIQUE_INSTANCE_IDENTIFIER
    echo APIGEE_NAMESPACE = $APIGEE_NAMESPACE
    echo PROJECT_ID = $PROJECT_ID
    echo ANALYTICS_REGION = $ANALYTICS_REGION
    echo CLUSTER_NAME = $CLUSTER_NAME
    echo CLUSTER_LOCATION = $CLUSTER_LOCATION
    echo ORG_NAME = $ORG_NAME
    echo ENVIRONMENT_NAME = $ENVIRONMENT_NAME
    echo NON_PROD_SERVICE_ACCOUNT_FILEPATH = $NON_PROD_SERVICE_ACCOUNT_FILEPATH
    echo INGRESS_NAME = $INGRESS_NAME
    echo INGRESSGATEWAY_REPLICAS_MAX = $INGRESSGATEWAY_REPLICAS_MAX
    echo ENVIRONMENT_GROUP_NAME = $ENVIRONMENT_GROUP_NAME
    echo PATH_TO_CERT_FILE = $PATH_TO_CERT_FILE
    echo PATH_TO_KEY_FILE = $PATH_TO_KEY_FILE


    if [[ -z $UNIQUE_INSTANCE_IDENTIFIER ]]; then
        echo "Unique identifier is missing, to generate the value $(echo $(uuidgen)| tr -d '-')"
        exit 1
    fi

    if [[ -z $APIGEE_NAMESPACE ]]; then
        echo "APIGEE_NAMESPACE is missing, exiting)"
        exit 1
    fi

    if [[ -z $PROJECT_ID ]]; then
        echo "PROJECT_ID is missing, exiting)"
        exit 1
    fi

    if [[ -z $ANALYTICS_REGION ]]; then
        echo "ANALYTICS_REGION is missing, exiting)"
        exit 1
    fi

    if [[ -z $CLUSTER_NAME ]]; then
        echo "CLUSTER_NAME is missing, exiting)"
        exit 1
    fi

    if [[ -z $CLUSTER_LOCATION ]]; then
        echo "CLUSTER_LOCATION is missing, exiting)"
        exit 1
    fi

    if [[ -z $ORG_NAME ]]; then
        echo "ORG_NAME is missing, exiting)"
        exit 1
    fi

    if [[ -z $ENVIRONMENT_NAME ]]; then
        echo " is missing, exiting)"
        exit 1
    fi

    if [[ -z $NON_PROD_SERVICE_ACCOUNT_FILEPATH ]]; then
        echo "NON_PROD_SERVICE_ACCOUNT_FILEPATH is missing, exiting)"
        exit 1
    fi

    if [[ -z $INGRESS_NAME ]]; then
        echo "INGRESS_NAME is missing, exiting)"
        exit 1
    fi

    if [[ -z $INGRESSGATEWAY_REPLICAS_MAX ]]; then
        echo "INGRESSGATEWAY_REPLICAS_MAX is missing, exiting)"
        exit 1
    fi

    if [[ -z $ENVIRONMENT_GROUP_NAME ]]; then
        echo "ENVIRONMENT_GROUP_NAME is missing, exiting)"
        exit 1
    fi

    if [[ -z $PATH_TO_CERT_FILE ]]; then
        echo "PATH_TO_CERT_FILE is missing, exiting)"
        exit 1
    fi

    if [[ -z $PATH_TO_KEY_FILE ]]; then
        echo "PATH_TO_KEY_FILE is missing, exiting)"
        exit 1
    fi

    if [[ -z $APIGEE_HELM_CHARTS_HOME ]]; then
        echo "APIGEE_HELM_CHARTS_HOME value is missing, exiting)"
        exit 1
    fi

    cp $WORK_DIR/scripts/helm/overrides-orig.yaml $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    
    yq e -i '.instanceID = env(UNIQUE_INSTANCE_IDENTIFIER)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.namespace = env(APIGEE_NAMESPACE)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml

    yq e -i '.gcp.projectID = env(PROJECT_ID)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.gcp.region = env(ANALYTICS_REGION)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml

    yq e -i '.k8sCluster.name = env(CLUSTER_NAME)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.k8sCluster.region = env(CLUSTER_LOCATION)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.org = env(ORG_NAME)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml

    yq e -i '.envs[0].name = env(ENVIRONMENT_NAME)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.envs[0].serviceAccountPaths.synchronizer = env(NON_PROD_SERVICE_ACCOUNT_FILEPATH)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.envs[0].serviceAccountPaths.runtime = env(NON_PROD_SERVICE_ACCOUNT_FILEPATH)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.envs[0].serviceAccountPaths.udca = env(NON_PROD_SERVICE_ACCOUNT_FILEPATH)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml

    yq e -i '.ingressGateways[0].name = env(INGRESS_NAME)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.ingressGateways[0].replicaCountMax = env(INGRESSGATEWAY_REPLICAS_MAX)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq -i 'del(.ingressGateways[0].svcAnnotations)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml

    yq e -i '.virtualhosts[0].name = env(ENVIRONMENT_GROUP_NAME)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.virtualhosts[0].selector.ingress_name = env(INGRESS_NAME)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.virtualhosts[0].sslCertPath = env(PATH_TO_CERT_FILE)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.virtualhosts[0].sslKeyPath = env(PATH_TO_KEY_FILE)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml

    yq e -i '.mart.serviceAccountPath = env(NON_PROD_SERVICE_ACCOUNT_FILEPATH)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.connectAgent.serviceAccountPath = env(NON_PROD_SERVICE_ACCOUNT_FILEPATH)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.logger.serviceAccountPath = env(NON_PROD_SERVICE_ACCOUNT_FILEPATH)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.metrics.serviceAccountPath = env(NON_PROD_SERVICE_ACCOUNT_FILEPATH)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.udca.serviceAccountPath = env(NON_PROD_SERVICE_ACCOUNT_FILEPATH)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
    yq e -i '.watcher.serviceAccountPath = env(NON_PROD_SERVICE_ACCOUNT_FILEPATH)' $APIGEE_HELM_CHARTS_HOME/overrides.yaml
}

# For testing
function setSampleInitValues() {
    export PROJECT_ID=apigee-hybrid-feb2024

    export ORG_NAME=$PROJECT_ID
    export ANALYTICS_REGION="us-east1"
    export REGION="us-east1"
    export RUNTIMETYPE=HYBRID
    export ENV_NAME="test-env"
    export DOMAIN="test.apigeehybrid.com"
    export ENV_GROUP="test-env-group"

    export APIGEE_HELM_CHARTS_HOME=/Users/akila/Developer/Google/Apigee/Hybrid/install/APIGEE_HYBRID_BASE/TEST_APIGEE_HELM_CHARTS_HOME
    export SA_FILE_NAME=$PROJECT_ID-apigee-non-prod

    export UNIQUE_INSTANCE_IDENTIFIER=$(echo $(uuidgen)| tr -d '-')
    export APIGEE_NAMESPACE=apigee
    export CLUSTER_LOCATION=$ANALYTICS_REGION
    export CLUSTER_NAME=hybrid-cluster
    export ENVIRONMENT_GROUP_NAME=$ENV_GROUP
    export ENVIRONMENT_NAME=$ENV_NAME
    export INGRESS_NAME=$ENV_GROUP-i
    export INGRESSGATEWAY_REPLICAS_MAX=3
    export NON_PROD_SERVICE_ACCOUNT_FILEPATH=$SA_FILE_NAME.json

    export PATH_TO_CERT_FILE=certs/keystore_test-env-group.pem
    export PATH_TO_KEY_FILE=certs/keystore_test-env-group.key

}

# Unit Testing
#setSampleInitValues;
#fixOverridesFile;