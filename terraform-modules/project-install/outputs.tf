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

/*
export VPC_SELF_LINK="$(terraform output -raw self_link)"; export $VPC_LINK
export VPC_LINK="$(terraform output -raw vpc_self_link)"; export $VPC_LINK
export SUBNET_LINKS="$(terraform output -raw subnet_self_links)"
*/