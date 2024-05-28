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
  depends_on = [
    module.vpc
  ]
}

module "gke-nodepool-default" {
  source             = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/gke-nodepool?ref=v16.0.0"
  project_id         = var.project_id
  cluster_name       = var.gke_cluster.name
  location           = var.gke_cluster.location
  name               = "apigee-default-nodepool"
  node_machine_type  = var.node_machine_type
  node_preemptible   = var.node_preemptible_runtime
  initial_node_count = 2
  node_tags          = ["apigee-hybrid"]
  node_locations     = var.node_locations_data
  autoscaling_config = var.nodepool_autoscaling_config
  depends_on = [
    module.gke-cluster
  ]
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
  depends_on = [
    module.gke-cluster
  ]
}

module "nat" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-cloudnat?ref=v16.0.0"
  project_id     = var.project_id
  region         = var.gke_cluster.region
  name           = "nat-${var.gke_cluster.region}"
  router_network = var.vpc_self_link
  depends_on = [
    module.gke-cluster
  ]
}

module "vpc" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v16.0.0"
  project_id = var.project_id
  name       = var.network
  subnets    = var.subnets
  count      = var.create_vpc ? 1 : 0
}