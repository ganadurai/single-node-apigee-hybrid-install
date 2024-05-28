data "google_client_config" "provider" {}

module "project" {
  source          = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v16.0.0"
  name            = var.project_id
  parent          = var.project_parent
  billing_account = var.billing_account
  project_create  = var.project_create
  services = [
    "apigee.googleapis.com",
    "apigeeconnect.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "pubsub.googleapis.com",
    "sourcerepo.googleapis.com",
    "logging.googleapis.com"
  ]
  
  /*
  This is needed with an valid org account
  policy_boolean = {
    "constraints/compute.requireShieldedVm" = false
    "constraints/iam.disableServiceAccountKeyCreation" = false
  }
  */
  
  iam = {
    "roles/apigee.admin" = [
      "user:${var.org_admin}"
    ]
  }
}