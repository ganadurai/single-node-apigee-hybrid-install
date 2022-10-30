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

locals {
  instance_name = var.hybrid_compute_instance.name
  instance_machine_type = var.hybrid_compute_instance.machine_type
  instance_zone = var.hybrid_compute_instance.zone
  instance_tags = var.hybrid_compute_instance.tags
  instance_boot_image = var.hybrid_compute_instance.boot_image
  instance_boot_size = var.hybrid_compute_instance.boot_size
  instance_boot_type = var.hybrid_compute_instance.boot_type
  instance_network = var.network
  instance_metadata_startup_script = var.hybrid_compute_instance.metadata_startup_script  
}

provider "google" {
  project = var.PROJECT_ID
}

#https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/compute-vm
module "hybrid_vm" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/compute-vm"

  project_id    = var.PROJECT_ID
  name          = "${local.instance_name}"
  instance_type = "${local.instance_machine_type}"
  zone          = "${local.instance_zone}"

  tags = "${local.instance_tags}"

  boot_disk = {
    image = "${local.instance_boot_image}"
    size = "${local.instance_boot_size}"
    type = "${local.instance_boot_type}"
  }

  network_interfaces = [{

    network                  = module.vpc_network.self_link
    subnetwork               = module.vpc_network.subnet_self_links["${var.hybrid_compute_instance.region}/${var.subnetwork.name}"]

    subnetwork_project = var.PROJECT_ID
    
    nat         = true
    addresses = null

  }]

  metadata = {
    /*
    startup-script = templatefile("${path.module}/startup-install.sh", { VAR_PROJECT_ID = var.PROJECT_ID,
                                                                  VAR_ORG_ADMIN = var.ORG_ADMIN, 
                                                                  VAR_APIGEE_NAMESPACE = var.APIGEE_NAMESPACE, 
                                                                  VAR_ENV_NAME = var.ENV_NAME, 
                                                                  VAR_ENV_GROUP = var.ENV_GROUP, 
                                                                  VAR_DOMAIN = var.DOMAIN, 
                                                                  VAR_REGION = var.REGION, 
                                                                  VAR_ORG_NAME = var.ORG_NAME, 
                                                                  VAR_CLUSTER_NAME = var.CLUSTER_NAME, 
                                                                  VAR_TOKEN = var.TOKEN })
    */
    serial-port-logging-enable = true
  }

  service_account_create = true

  depends_on = [
    module.vpc_network
  ]
}

module "vpc_network" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc"
  project_id                 = var.PROJECT_ID
  name                      = var.network
  subnets = [
    {
    name          = var.subnetwork.name
    ip_cidr_range = var.subnetwork.cidr
    region        = var.hybrid_compute_instance.region
    }
  ]
}

module "firewall" {
  source       = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc-firewall"
  project_id   = var.PROJECT_ID
  network      = var.network
  //admin_ranges = ["10.0.0.0/8"]
  custom_rules = {
    ntp-svc = {
      description          = "SSH access"
      direction            = "INGRESS"
      action               = "allow"
      ranges               = ["0.0.0.0/0"]
      targets              = var.hybrid_compute_instance.tags
      rules                = [{ protocol = "tcp", ports = [22] }]
      sources              = []
      extra_attributes     = {}
      use_service_accounts = false
    }
  }
  depends_on = [
    module.vpc_network
  ]
}
