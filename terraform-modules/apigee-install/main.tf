locals {
  env_groups = var.apigee_envgroups
}

module "apigee" {
  source              = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/apigee-organization?ref=v16.0.0"
  project_id          = var.project_id
  analytics_region    = var.ax_region
  runtime_type        = "HYBRID"
  apigee_environments = var.apigee_environments
  apigee_envgroups    = var.apigee_envgroups
  count               = var.apigee_org_create ? 1 : 0
}