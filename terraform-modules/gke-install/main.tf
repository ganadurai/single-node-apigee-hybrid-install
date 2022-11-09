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


data "google_client_config" "provider" {}

module "gke-cluster" {
  source                   = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/gke-cluster?ref=v16.0.0"
  project_id               = var.project_id
  name                     = var.gke_cluster.name
  location                 = var.gke_cluster.location
  network                  = var.vpc_self_link
  subnetwork               = var.subnet_self_link
  secondary_range_pods     = "pods"
  secondary_range_services = "services"
  master_authorized_ranges = var.gke_cluster.master_authorized_ranges
  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.gke_cluster.master_ip_cidr
    master_global_access    = true
  }
}

module "gke-nodepool-default" {
  source             = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/gke-nodepool?ref=v16.0.0"
  project_id         = var.project_id
  cluster_name       = var.gke_cluster.name
  location           = var.gke_cluster.location
  name               = "apigee-default-nodepool"
  node_machine_type  = var.node_machine_type
  node_preemptible   = var.node_preemptible_runtime
  initial_node_count = 1
  node_tags          = ["apigee-hybrid"]
  node_locations     = var.node_locations_data
  autoscaling_config = var.nodepool_autoscaling_config
}

resource "google_compute_firewall" "allow-master-webhook" {
  project   = var.project_id
  name      = "gke-master-apigee-webhooks"
  network   = var.vpc_self_link
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["9443"]
  }
  target_tags = ["apigee-hybrid"]
  source_ranges = [
    var.gke_cluster.master_ip_cidr,
  ]
}

module "nat" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-cloudnat?ref=v16.0.0"
  project_id     = var.project_id
  region         = var.gke_cluster.region
  name           = "nat-${var.gke_cluster.region}"
  router_network = var.vpc_self_link
}