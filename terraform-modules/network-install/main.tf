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

resource "google_compute_firewall" "allow-master-webhook" {
  project   = var.project_id
  name      = "gke-master-apigee-webhooks-${var.region}"
  network   = var.vpc_self_link
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["9443"]
  }
  target_tags = ["apigee-hybrid"]
  source_ranges = [
    var.master_ip_cidr,
  ]
  depends_on = [
    module.vpc
  ]
}

module "nat" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-cloudnat?ref=v16.0.0"
  project_id     = var.project_id
  region         = var.region
  name           = "nat-${var.region}"
  router_network = var.vpc_self_link
  depends_on = [
    module.vpc
  ]
}

module "vpc" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v16.0.0"
  project_id = var.project_id
  name       = var.network
  subnets    = var.subnets
  count      = var.create_vpc ? 1 : 0
}

