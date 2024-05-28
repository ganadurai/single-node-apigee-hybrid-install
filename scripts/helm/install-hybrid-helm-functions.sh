#!/bin/bash

set -e

function hybridInstallViaHelmCharts() {

    if [ ! -f "$APIGEE_HELM_CHARTS_HOME/apigee-datastore/$SA_FILE_NAME.json" ]; then
        echo "Creating Service Accounts"
        chmod +x $APIGEE_HELM_CHARTS_HOME/apigee-operator/etc/tools/create-service-account

        $APIGEE_HELM_CHARTS_HOME/apigee-operator/etc/tools/create-service-account \
            --env non-prod \
            --dir $APIGEE_HELM_CHARTS_HOME/apigee-datastore

        #ls $APIGEE_HELM_CHARTS_HOME/apigee-datastore

        cp $APIGEE_HELM_CHARTS_HOME/apigee-datastore/$SA_FILE_NAME.json $APIGEE_HELM_CHARTS_HOME/apigee-telemetry/
        cp $APIGEE_HELM_CHARTS_HOME/apigee-datastore/$SA_FILE_NAME.json $APIGEE_HELM_CHARTS_HOME/apigee-org/
        cp $APIGEE_HELM_CHARTS_HOME/apigee-datastore/$SA_FILE_NAME.json $APIGEE_HELM_CHARTS_HOME/apigee-env/

        echo "waiting 10s for the newly created service account to sync"
        sleep 10

        echo "Required permission for Synchronizer getting added"
        curl -s -X POST -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type:application/json" \
            "https://apigee.googleapis.com/v1/organizations/${ORG_NAME}:setSyncAuthorization" \
            -d '{"identities":["'"serviceAccount:apigee-non-prod@${PROJECT_ID}.iam.gserviceaccount.com"'"]}'

        sleep 10

        SRVC_ACCNT_SYNC_STATUS=$(curl -s -X GET -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type:application/json" \
            "https://apigee.googleapis.com/v1/organizations/${ORG_NAME}:getSyncAuthorization" \
            grep serviceAccount:apigee-non-prod@${PROJECT_ID}.iam.gserviceaccount.com | jq ".identities[0]" | cut -d '"' -f 2)
        if [[ $SRVC_ACCNT_SYNC_STATUS == "serviceAccount:apigee-non-prod@$PROJECT_ID.iam.gserviceaccount.com" ]]; then
            echo "srvc account sync set"
        else
            echo "srvc account sync not set"
            exit 1;
        fi
    else
        echo "Service Accounts already existing, so skipping creation"
    fi

    if [ ! -d "$APIGEE_HELM_CHARTS_HOME/apigee-virtualhost/certs" ]; then
        echo "Creating self signed certs"
        mkdir $APIGEE_HELM_CHARTS_HOME/apigee-virtualhost/certs

        openssl req  -nodes -new -x509 -keyout $APIGEE_HELM_CHARTS_HOME/apigee-virtualhost/certs/keystore_$ENV_GROUP.key -out \
            $APIGEE_HELM_CHARTS_HOME/apigee-virtualhost/certs/keystore_$ENV_GROUP.pem -subj '/CN='$DOMAIN'' -days 3650
        ls $APIGEE_HELM_CHARTS_HOME/apigee-virtualhost/certs
    else
        echo "Certs already existing, so skipping creation"
    fi

    # set-overrides.sh
    echo "Fixing overrides file"
    # TODO : Add a check if INGRESS_NAME is less than 17 chars 
    fixOverridesFile;

    # install-crds-cert-mgr.sh
    echo "Install certs and crds"
    installCertMgr;
    installCRDS;

    # set-chart-values.ch
    fixHelmValues;

    # execute-charts.sh
    executeCharts; 

}