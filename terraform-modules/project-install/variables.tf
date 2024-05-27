variable "project_id" {
  description = "Project id (also used for the Apigee Organization)."
  type        = string
}

variable "org_admin" {
  description = "User id email as apigee admin"
  type        = string
}

variable "billing_account" {
  description = "Billing account for the project"
  type        = string
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

variable "region" {
  description = "Entities region"
  type        = string
}