variable "project_id" {
  description = "Project id (also used for the Apigee Organization)."
  type        = string
}

variable "vpc_self_link" {
  description = "Network VPC self_link name to be used for hosting the instance."
  type        = string
}

variable "subnet_self_link" {
  description = "Subnetwork  self_link name to be used for hosting the instance."
  type        = string
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
}

variable "node_preemptible_runtime" {
  description = "Use preemptible VMs for runtime node pool"
  type        = bool
  default     = true
}

variable "node_locations_data" {
  description = "List of locations for the data node pool"
  type        = list(string)
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
    min_node_count = 2
    max_node_count = 2
  }
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