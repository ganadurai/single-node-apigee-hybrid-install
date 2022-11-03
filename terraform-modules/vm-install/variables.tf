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

// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance#nested_boot_disk

variable "PROJECT_ID" {
  description = "Project id (also used for the Apigee Organization)."
  type        = string
}

variable "ORG_ADMIN" {
  description = "User having access to create vm instance"
  type        = string
}

variable "ORG_NAME" {
  description = "Organization Name"
  type        = string
}

variable "CLUSTER_NAME" {
  description = "Cluster Name"
  type        = string
}

variable "TOKEN" {
  description = "Auth Token"
  type        = string
}

variable "APIGEE_NAMESPACE" {
  description = "Apigee Namespace"
  type        = string
  default     = "apigee"
}

variable "ENV_NAME" {
  description = "Environment Name"
  type        = string
}

variable "ENV_GROUP" {
  description = "Environment Group"
  type        = string
}

variable "DOMAIN" {
  description = "Environment domain (hostname)"
  type        = string
}

variable "REGION" {
  description = "Deployment region"
  type        = string
}


variable "network" {
  description = "Network name to be used for hosting the instance."
  type        = string
  default     = "hybrid-runtime-default-vpc"
}

variable "subnetwork" {
  description = "Subnetwork name to be used for hosting the instance."
  type = object({
    name      = string
    cidr      = string
  })
  default = {
    name      = "hybrid-runtime-default-vpc-subnetwork"
    cidr      = "10.210.210.0/29"
  }
}

variable "vpc_create" {
  description = "Create VPC. When set to false, uses a data source to reference existing VPC."
  type        = bool
  default     = false
}

variable "hybrid_compute_instance" {
  description = "GCP Compute Instance that hosts the Hybrid containers"
  type = object({
    name                    = string
    machine_type            = string
    region                  = string
    zone                    = string
    boot_image              = string
    boot_size               = string
    boot_type               = string
    tags                    = list(string)
    network                 = string
    subnetwork              = string
  })
  default = {
    name                    = "vm-hybrid-instance-1"
    machine_type            = "e2-standard-4"
    region                  = "us-central1"
    zone                    = "us-central1-a"
    boot_image              = "debian-cloud/debian-11"
    boot_size               = "20"
    boot_type               = "pd-balanced"
    tags                    = ["vm-hybrid-instance"]
    network                 = "hybrid-cluster-network"
    subnetwork              = "hybrid-cluster-subnet"
  }
}

variable "exclude_startup_script" {
  description = "Create VPC. When set to false, uses a data source to reference existing VPC."
  type        = bool
  default     = true
}