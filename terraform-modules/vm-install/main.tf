locals {
  instance_name = var.hybrid_compute_instance.name
  instance_machine_type = var.hybrid_compute_instance.machine_type
  instance_zone = var.ZONE
  instance_tags = var.hybrid_compute_instance.tags
  instance_boot_image = var.hybrid_compute_instance.boot_image
  instance_boot_size = var.hybrid_compute_instance.boot_size
  instance_boot_type = var.hybrid_compute_instance.boot_type
  instance_network = var.network 
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
    subnetwork               = module.vpc_network.subnet_self_links["${var.REGION}/${var.subnetwork.name}"]

    subnetwork_project = var.PROJECT_ID
    
    nat         = true
    addresses = null

  }]

  metadata = {
    serial-port-logging-enable  = true
    startup-script              = var.exclude_startup_script ? "" : templatefile("${path.module}/startup-install.sh", { VAR_PROJECT_ID = var.PROJECT_ID,
                                                                        VAR_ORG_ADMIN = var.ORG_ADMIN, 
                                                                        VAR_APIGEE_NAMESPACE = var.APIGEE_NAMESPACE, 
                                                                        VAR_ENV_NAME = var.ENV_NAME, 
                                                                        VAR_ENV_GROUP = var.ENV_GROUP, 
                                                                        VAR_DOMAIN = var.DOMAIN, 
                                                                        VAR_REGION = var.REGION, 
                                                                        VAR_ORG_NAME = var.ORG_NAME, 
                                                                        VAR_CLUSTER_NAME = var.CLUSTER_NAME, 
                                                                        VAR_TOKEN = var.TOKEN })
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
    region        = var.REGION
    }
  ]
}

module "firewall" {
  source       = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v16.0.0"
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
