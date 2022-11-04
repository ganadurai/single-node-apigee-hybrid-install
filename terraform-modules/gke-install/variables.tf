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

variable "ax_region" {
  description = "GCP region for storing Apigee analytics data (see https://cloud.google.com/apigee/docs/api-platform/get-started/install-cli)."
  type        = string
  default     = "us-central1"
}

variable "apigee_envgroups" {
  description = "Apigee Environment Groups."
  type = map(object({
    environments = list(string)
    hostnames    = list(string)
  }))
  default = {}
}

variable "apigee_environments" {
  description = "List of Apigee Environment Names."
  type        = list(string)
  default     = []
}

variable "billing_account" {
  description = "Billing account id."
  type        = string
  default     = null
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

variable "apigee_org_create" {
  description = "Create apigee org. When set to false, skips org create"
  type        = bool
  default     = false
}

variable "network" {
  description = "Network name to be used for hosting the instance."
  type        = string
  default     = "hybrid-runtime-cluster-vpc"
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

variable "cluster_region" {
  description = "Region for where to create the cluster."
  type        = string
  default     = "us-central1"
}

variable "cluster_location" {
  description = "Region/Zone for where to create the cluster."
  type        = string
  default     = "us-central1"
}

variable "gke_cluster" {
  description = "GKE Cluster Specification"
  type = object({
    name                     = string
    region                   = string
    location                 = string
    master_ip_cidr           = string
    master_authorized_ranges = map(string)
  })
  default = {
    name                      = "hybrid-cluster-2"
    location                  = "us-central1"
    master_authorized_ranges  = {
      "internet" = "0.0.0.0/0"
    }
    master_ip_cidr            = "192.168.0.0/28"
    region                    = "us-central1"
  }
}

variable "node_preemptible_runtime" {
  description = "Use preemptible VMs for runtime node pool"
  type        = bool
  default     = true
}

variable "node_locations_data" {
  description = "List of locations for the data node pool"
  type        = list(string)
  default     = ["us-central1-a"]
}

variable "node_machine_type" {
  description = "Machine type for node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "nodepool_autoscaling_config" {
  description = "autoscaling configuration."
  type = object({
    min_node_count = number
    max_node_count = number
  })
  default = {
    min_node_count = 1
    max_node_count = 1
  }
}

variable "kubernetes_access_token" {
  description = "Kubernetes Access Token (set to null to use the default Google Auth Context)"
  type        = string
  default     = null
}