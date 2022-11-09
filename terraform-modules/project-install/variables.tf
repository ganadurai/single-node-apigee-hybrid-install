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

variable "org_admin" {
  description = "User id email as apigee admin"
  type        = string
}

variable "billing_account" {
  description = "Billing account for the project"
  type        = string
}

variable "project_parent" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
  default     = null
  validation {
    condition     = var.project_parent == null || can(regex("(organizations|folders)/[0-9]+", var.project_parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "project_create" {
  description = "Create project. When set to false, uses a data source to reference existing project."
  type        = bool
  default     = false
}

variable "network" {
  description = "Network name to be used for hosting the instance."
  type        = string
  default     = "hybrid-runtime-cluster-vpc"
}

variable "region" {
  description = "Entities region"
  type        = string
  default     = "us-central1"
}

variable "subnets" {
  description = "Subnetwork name to be used for hosting the instance."
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
    secondary_ip_range = map(string)
  }))
  default = [{
    name          = "hybrid-runtime-cluster-vpc-subnetwork"
    ip_cidr_range = "10.0.0.0/24"
    region        = "us-central1"
    secondary_ip_range = {
      pods = "10.100.0.0/20"
      services = "10.101.0.0/23"
    }
  }]
}