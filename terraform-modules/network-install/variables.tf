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

variable "project_id" {
  description = "Project id (also used for the Apigee Organization)."
  type        = string
}

variable "vpc_self_link" {
  description = "Network VPC self_link name to be used for hosting the instance."
  type        = string
}

variable create_vpc {
  description = "Flag to control VPC create"
  type        = bool
  default     = true
}

variable "network" {
  description = "Network name to be used for hosting the instance."
  type        = string
}

variable "subnets" {
  description = "Subnetwork name to be used for hosting the instance."
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
    secondary_ip_range = map(string)
  }))
}

variable "master_ip_cidr" {
  description = "Source ip cidr for firewall"
  type        = string
  default     = "192.168.0.0/28,172.16.0.16/28"
}

variable "region" {
  description = "Region"
  type        = string
}