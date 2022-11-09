/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "vpc_self_link" {
  description = "Project VPC Link"
  value       = module.vpc.self_link
}

output "subnet_self_links" {
  description = "Subnet self links"
  value       = module.vpc.subnet_self_links["${var.region}/${var.subnets[0].name}"]
}

output "vpc_network_name" {
  description = "VPC network name"
  value       = locals.vpc_network_name
}

output "sub_network_name" {
  description = "Subnet name"
  value       = locals.sub_network_name
}

/*
export VPC_LINK="$(terraform output -raw vpc_self_link)";
export SUBNET_LINKS="$(terraform output -raw subnet_self_links)"; 
export VPC_NAME="$(terraform output -raw vpc_network_name)"; 
export SUB_NETWORK_NAME="$(terraform output -raw sub_network_name)";
echo "VPC_LINK=$VPC_LINK"
echo "SUBNET_LINKS=$SUBNET_LINKS"
echo "VPC_NAME=$VPC_NAME"
echo "SUB_NETWORK_NAME=$SUB_NETWORK_NAME"

VPC_LINK=https://www.googleapis.com/compute/v1/projects/h-apigee-project-9/global/networks/hybrid-runtime-cluster-vpc
SUBNET_LINKS=https://www.googleapis.com/compute/v1/projects/h-apigee-project-9/regions/us-central1/subnetworks/hybrid-runtime-cluster-vpc-subnetwork

VPC_LINK=https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/global/networks/$VPC_NETWORK_NAME
SUBNET_LINKS=https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/regions/$REGION/subnetworks/$SUB_NETWORK_NAME

*/