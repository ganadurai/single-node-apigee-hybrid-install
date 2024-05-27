#!/bin/bash

set -e

cd "$WORK_DIR/terraform-modules/vm-install"

NODE_ZONE=$(gcloud compute zones list --filter="region:$REGION" --limit=1 --format=json | \
    jq '.[0].name' | cut -d '"' -f 2); export NODE_ZONE;

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
    -var="REGION=$REGION" \
    -var="ZONE=$NODE_ZONE";
terraform destroy -auto-approve \
    -var="PROJECT_ID=${PROJECT_ID}" \
    -var="ORG_ADMIN=${ORG_ADMIN}" \
    -var="ORG_NAME=${ORG_NAME}" \
    -var="CLUSTER_NAME=${CLUSTER_NAME}" \
    -var="TOKEN=${TOKEN}" \
    -var="APIGEE_NAMESPACE=$APIGEE_NAMESPACE" \
    -var="ENV_NAME=$ENV_NAME" \
    -var="ENV_GROUP=$ENV_GROUP" \
    -var="DOMAIN=$DOMAIN" \
    -var="REGION=$REGION" \
    -var="ZONE=$NODE_ZONE";