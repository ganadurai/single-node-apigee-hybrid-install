***This deployment model is intended ONLY for testing and sandbox purposes, **NOT for production deployments**. This setup is **NOT covered under any form of Google support**.***

# Single Node (all-in-one) Hybrid Installation

For simple tests and validation of Apigee Hybrid, are you concerned about the high platform cost and the effort involved in setting it up?

This tool solves your concerns. 

* Reduces the cost of running Apigee Hybrid to a minimum of $100 per month, compared to the standard Hybrid operating cost of $800 or more
* Provides end-to-end automation, starting with setup of GCP project, configuring an Apigee org and deploying Hybrid cluster

This implementation is needs a node : 4vCPU, 16GB RAM.

This deployment model is intended ONLY for testing and sandbox purposes, **NOT for production deployments**. This setup is **NOT covered under any form of Google support**.

## Following deployment options are supported

- [Mac](./README-Mac-Install.md)
- [GCP VM](./README-VM-Install.md)
- [AWS VM](./README-VM-Install.md) 
- [AWS EKS](./README-EKS-Install.md) 

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
