#!/bin/bash

set -e

function executeCharts() {
    
    clusterReadinessCheck;

    deployApigeeOperator;
    deployApigeeDatastore;
    deployApigeeTelemetry;
    deployApigeeRedis;
    deployApigeeIngressMgr;
    deployApigeeOrg;
    deployApigeeEnv;
    deployApigeeEnvGroup;
}

function clusterReadinessCheck() {
    echo "Checking cluster readiness";

    if [ ! -d "$APIGEE_HELM_CHARTS_HOME/cluster-check" ]; then
        mkdir $APIGEE_HELM_CHARTS_HOME/cluster-check
    fi
        
    cp $WORK_DIR/scripts/helm/apigee-k8s-cluster-ready-check.yaml $APIGEE_HELM_CHARTS_HOME/cluster-check

    kubectl apply -f $APIGEE_HELM_CHARTS_HOME/cluster-check/apigee-k8s-cluster-ready-check.yaml

    kubectl wait job --all --for="jsonpath=.status.succeeded=1" --timeout=30s && \
    kubectl wait job --all --for="jsonpath=.status.conditions[0].status=True" --timeout=30s && \
    kubectl wait job --all --for="jsonpath=.status.conditions[0].type=Complete" --timeout=30s
    exit_code=$?
    #echo $exit_code
    if (( $exit_code == 0 )); then
        echo "apigee-k8s-cluster-ready-check ready"
    else
        echo "apigee-k8s-cluster-ready-check not ready, check Step 10 of the docs"
        exit 1;
    fi

    kubectl delete -f $APIGEE_HELM_CHARTS_HOME/cluster-check/apigee-k8s-cluster-ready-check.yaml
    echo "Done, checking cluster readiness";

}

function deployApigeeOperator() {

    cd $APIGEE_HELM_CHARTS_HOME  

    helm upgrade operator apigee-operator/ \
        --install \
        --create-namespace \
        --namespace apigee-system \
        --atomic \
        -f overrides.yaml \
        --dry-run

    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart apigee-operator dry run success"
    else
        echo "helm chart apigee-operator dry run failed, check Step 11 of the docs"
        exit 1;
    fi

    helm upgrade operator apigee-operator/ \
        --install \
        --create-namespace \
        --namespace apigee-system \
        --atomic \
        -f overrides.yaml

    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart apigee-operator success"
    else
        echo "helm chart apigee-operator failed, check Step 11 of the docs"
        exit 1;
    fi

    echo "Waiting max 120s for helm apigee-operator install to take into effect! "

    #deployed_status=$(helm ls -n apigee-system -o json | jq ".[].status" | cut -d '"' -f 2) 
    #echo $deployed_status
    #if [[ $deployed_status == "deployed" ]]; then
    #    echo "helm chart apigee-operator post apply, success"
    #else
    #    echo "helm chart apigee-operator post apply failed, check Step 11 of the docs"
    #    exit 1;
    #fi
    
    kubectl wait deploy apigee-controller-manager -n apigee-system --for="jsonpath=.status.readyReplicas=1" --timeout=120s
    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart apigee-controller-manager post apply, success"
    else
        echo "helm chart apigee-controller-manager post apply failed, check Step 11 of the docs"
        exit 1;
    fi
}

function deployApigeeDatastore() {

    cd $APIGEE_HELM_CHARTS_HOME  

    helm upgrade datastore apigee-datastore/ \
        --install \
        --namespace apigee \
        --atomic \
        -f overrides.yaml \
        --dry-run

    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart apigee-datastore dry run success"
    else
        echo "helm chart apigee-datastore dry run failed, check Step 11 of the docs"
        exit 1;
    fi

    helm upgrade datastore apigee-datastore/ \
        --install \
        --namespace apigee \
        --atomic \
        -f overrides.yaml

    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart apigee-datastore success"
    else
        echo "helm chart apigee-datastore failed, check Step 11 of the docs"
        exit 1;
    fi

    echo "Waiting max 300s for helm apigeedatastore install to take into effect! "
    
    kubectl wait apigeedatastore default -n apigee --for="jsonpath=.status.state=running" --timeout=300s
    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart apigee-datastore post apply, success"
    else
        echo "helm chart apigee-datastore post apply failed, check Step 11 of the docs"
        exit 1;
    fi
}

function deployApigeeTelemetry() {

    cd $APIGEE_HELM_CHARTS_HOME

    helm upgrade telemetry apigee-telemetry/ \
        --install \
        --namespace apigee \
        --atomic \
        -f overrides.yaml \
        --dry-run

    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart apigee-telemetry dry run success"
    else
        echo "helm chart apigee-telemetry dry run failed, check Step 11 of the docs"
        exit 1;
    fi

    helm upgrade telemetry apigee-telemetry/ \
        --install \
        --namespace apigee \
        --atomic \
        -f overrides.yaml

    echo "Waiting max 300s for helm apigeetelemetry install to take into effect! "
    
    kubectl wait apigeetelemetry apigee-telemetry -n apigee --for="jsonpath=.status.state=running" --timeout=300s
    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart apigee-telemetry post apply, success"
    else
        echo "helm chart apigee-telemetry post apply failed, check Step 11 of the docs"
        exit 1;
    fi
}

function deployApigeeRedis() {

    cd $APIGEE_HELM_CHARTS_HOME

    helm upgrade redis apigee-redis/ \
        --install \
        --namespace apigee \
        --atomic \
        -f overrides.yaml \
        --dry-run

    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart apigee-redis dry run success"
    else
        echo "helm chart apigee-redis dry run failed, check Step 11 of the docs"
        exit 1;
    fi

    helm upgrade redis apigee-redis/ \
        --install \
        --namespace apigee \
        --atomic \
        -f overrides.yaml

    echo "Waiting max 300s for helm apigeeredis install to take into effect! "
    
    kubectl wait apigeeredis default -n apigee --for="jsonpath=.status.state=running" --timeout=300s
    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart apigee-redis post apply, success"
    else
        echo "helm chart apigee-redis post apply failed, check Step 11 of the docs"
        #exit 1;
    fi
}

function deployApigeeIngressMgr() {

    cd $APIGEE_HELM_CHARTS_HOME
    
    helm upgrade ingress-manager apigee-ingress-manager/ \
        --install \
        --namespace apigee \
        --atomic \
        -f overrides.yaml \
        --dry-run

    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart ingress-manager dry run success"
    else
        echo "helm chart ingress-manager dry run failed, check Step 11 of the docs"
        exit 1;
    fi
    
    helm upgrade ingress-manager apigee-ingress-manager \
        --install \
        --namespace apigee \
        --atomic \
        -f overrides.yaml

    echo "Waiting 120s for helm apigee-ingressgateway-manager install to take into effect! "
    sleep 120
    
    availableReplicas=$(kubectl -n apigee get deployment apigee-ingressgateway-manager -o json | jq ".status.availableReplicas")
    readyReplicas=$(kubectl -n apigee get deployment apigee-ingressgateway-manager -o json | jq ".status.readyReplicas")
    replicas=$(kubectl -n apigee get deployment apigee-ingressgateway-manager -o json | jq ".status.replicas")
    if (( $availableReplicas == $readyReplicas )); then
        if (( $replicas == $readyReplicas )); then
            echo "helm chart apigee-ingressgateway-manager post apply, success"
        else
            echo "helm chart apigee-ingressgateway-manager post apply failed, replicas and readyReplicas didnt match, check Step 11 of the docs"
            exit 1;
        fi
    else
        echo "helm chart apigee-ingressgateway-manager post apply failed, check Step 11 of the docs"
        exit 1;
    fi
}

function deployApigeeOrg() {

    cd $APIGEE_HELM_CHARTS_HOME

    helm upgrade $ORG_NAME apigee-org \
        --install \
        --namespace apigee \
        --atomic \
        -f overrides.yaml \
        --dry-run

    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart apigee-org dry run success"
    else
        echo "helm chart apigee-org dry run failed, check Step 11 of the docs"
        exit 1;
    fi

    helm upgrade $ORG_NAME apigee-org/ \
        --install \
        --namespace apigee \
        --atomic \
        -f overrides.yaml

    echo "Waiting max 600s for helm apigeeorg install to take into effect! "
    
    kubectl -n apigee get apigeeorg

    exec_code=$?
    if (( $exec_code == 0 )); then
        AORG_NAME=$(kubectl get apigeeorg -n apigee -o json | jq ".items[0].metadata.name" | cut -d '"' -f 2)
        kubectl wait apigeeorg $AORG_NAME -n apigee --for="jsonpath=.status.state=running" --timeout=600s
        exec_code=$?
        if (( $exec_code == 0 )); then
            echo "helm chart apigee-org post apply, success"
        else
            echo "helm chart apigee-org post apply failed, check Step 11 of the docs"
            exit 1;
        fi
    else
        echo "helm chart apigee-org post apply failed, failure in get apigee-org, check Step 11 of the docs"
        exit 1;
    fi
}

function deployApigeeEnv() {

    cd $APIGEE_HELM_CHARTS_HOME

    helm upgrade $ENV_NAME apigee-env/ \
        --install \
        --namespace apigee \
        --atomic \
        --set env=$ENV_NAME \
        -f overrides.yaml \
        --dry-run

    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart apigee-env dry run success"
    else
        echo "helm chart apigee-env dry run failed, check Step 11 of the docs"
        exit 1;
    fi

    helm upgrade $ENV_NAME apigee-env \
        --install \
        --namespace apigee \
        --atomic \
        --set env=$ENV_NAME \
        -f overrides.yaml

    echo "Waiting 600s for helm apigeeenv install to take into effect! "
    
    kubectl -n apigee get apigeeenv

    exec_code=$?
    if (( $exec_code == 0 )); then
        AENV_NAME=$(kubectl get apigeeenv -n apigee -o json | jq ".items[0].metadata.name" | cut -d '"' -f 2)
        kubectl wait apigeeenv $AENV_NAME -n apigee --for="jsonpath=.status.state=running" --timeout=600s
        exec_code=$?
        if (( $exec_code == 0 )); then
            echo "helm chart apigee-env post apply, success"
        else
            echo "helm chart apigee-env post apply failed, check Step 11 of the docs"
            exit 1;
        fi
    else
        echo "helm chart apigee-env post apply failed, failure in get apigee-env, check Step 11 of the docs"
        exit 1;
    fi
}

function deployApigeeEnvGroup() {

    cd $APIGEE_HELM_CHARTS_HOME

    helm upgrade $ENVIRONMENT_GROUP_NAME apigee-virtualhost/ \
        --install \
        --namespace apigee \
        --atomic \
        --set envgroup=$ENVIRONMENT_GROUP_NAME \
        -f overrides.yaml \
        --dry-run

    exec_code=$?
    if (( $exec_code == 0 )); then
        echo "helm chart apigee-virtualhost dry run success"
    else
        echo "helm chart apigee-virtualhost dry run failed, check Step 11 of the docs"
        exit 1;
    fi

    helm upgrade $ENVIRONMENT_GROUP_NAME apigee-virtualhost/ \
        --install \
        --namespace apigee \
        --atomic \
        --set envgroup=$ENVIRONMENT_GROUP_NAME \
        -f overrides.yaml

    echo "Waiting 300s for helm apigee-virtualhost install to take into effect! "
    sleep 30;

    kubectl -n apigee get arc

    exec_code=$?
    if (( $exec_code == 0 )); then
        AR_NAME=$(kubectl get ar -n apigee -o json | jq ".items[0].metadata.name" | cut -d '"' -f 2)
        kubectl wait ar $AR_NAME -n apigee --for="jsonpath=.status.state=running" --timeout=300s
        exec_code=$?
        if (( $exec_code == 0 )); then
            echo "helm chart apigee-virtualhost post apply, success"
        else
            echo "helm chart apigee-virtualhost post apply failed, check Step 11 of the docs"
            exit 1;
        fi
    else
        echo "helm chart apigee-virtualhost post apply failed, failure in get apigee-route, check Step 11 of the docs"
        exit 1;
    fi

}