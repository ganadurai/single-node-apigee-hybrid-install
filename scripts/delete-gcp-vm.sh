#!/bin/bash

# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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