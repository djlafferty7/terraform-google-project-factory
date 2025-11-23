variable "client_name" {
  description = "Name of the client. Used for the Folder display name and Project ID prefix."
  type        = string
}

variable "org_id" {
  description = "The Organization ID where the resources will be created."
  type        = string
}

variable "billing_account" {
  description = "The Billing Account ID to attach to the project."
  type        = string
}

variable "consultancy_group_email" {
  description = "Email of the internal engineering group (Platform Team)."
  type        = string
}

variable "client_admin_group_email" {
  description = "Email of the client admin group (Client IT)."
  type        = string
}

variable "region" {
  description = "Default region for resources."
  type        = string
  default     = "us-central1"
}

variable "directory_customer_id" {
  description = "The Google Workspace Customer ID. Required for 'iam.allowedPolicyMemberDomains' constraint."
  type        = string
}
