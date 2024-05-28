variable "project_id" {
  description = "Project id (also used for the Apigee Organization)."
  type        = string
}

variable "apigee_org_create" {
  description = "Create apigee org. When set to false, skips org create"
  type        = bool
  default     = false
}

variable "ax_region" {
  description = "GCP region for storing Apigee analytics data (see https://cloud.google.com/apigee/docs/api-platform/get-started/install-cli)."
  type        = string
}

variable "apigee_envgroups" {
  description = "Apigee Environment Groups."
  type = map(object({
    environments = list(string)
    hostnames    = list(string)
  }))
  default = {}
}

variable "apigee_environments" {
  description = "List of Apigee Environment Names."
  type        = list(string)
  default     = []
}