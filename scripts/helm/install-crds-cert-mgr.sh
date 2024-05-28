#!/bin/bash

set -e

function installCertMgr() {
    
    deployed_status=$(kubectl get pods -n cert-manager -o json | jq ".items[0].status.containerStatuses[0].ready") 
    echo $deployed_status
    if [[ $deployed_status == "true" ]]; then
        echo "cert-manager already deployed"
    else
        # Install cert manager
        kubectl apply -f $CERT_MGR_DWNLD_YAML
        #kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.1/cert-manager.yaml

        echo "Waiting 60s for cert-manager install to take into effect! "
        sleep 60

        kubectl wait pod --all -n cert-manager --for="jsonpath=.status.containerStatuses[0].ready=true" --timeout=60s
        exit_code=$?
        if (( $exit_code == 0 )); then
            echo "cert-manager successfully deployed"
        else
            echo "cert-manager not successfully deployed... Check on the pod status in the cert-manager namespace, Step 9 of the install docs"
            exit 1;
        fi
    fi
}

function installCRDS() {

    apigee_crds=$(kubectl get crds | grep apigee | wc -l)
    if [[ $apigee_crds -eq 10 ]]; then
        echo "apigee-operator CRD already installed"
    else
        # Install the CRDs
        cd $APIGEE_HELM_CHARTS_HOME


        kubectl apply -k  apigee-operator/etc/crds/default/ \
        --server-side \
        --force-conflicts \
        --validate=false \
        --dry-run=server

        exec_code=$?
        if (( $exec_code == 0 )); then
            echo "Install of CRDs dry run success"
        else
            echo "Install of CRDs dry run failed, check Step 11 of the docs"
            exit 1;
        fi

        kubectl apply -k  apigee-operator/etc/crds/default/ \
        --server-side \
        --force-conflicts \
        --validate=false

        echo "Waiting 60s for crds install to take into effect! "
        sleep 60
        
        apigee_crds=$(kubectl get crds | grep apigee | wc -l)
        if [[ $apigee_crds -eq 10 ]]; then
            echo "apigee-operator CRD installed"
        fi
    fi

}