resource "google_folder" "client_root" {
  display_name = var.client_name
  parent       = "organizations/${var.org_id}"
}

# 1. Disable Key Hazards
resource "google_folder_organization_policy" "disable_service_account_key_creation" {
  folder     = google_folder.client_root.name
  constraint = "iam.disableServiceAccountKeyCreation"

  boolean_policy {
    enforced = true
  }
}

# 2. Modern Storage Security
resource "google_folder_organization_policy" "uniform_bucket_level_access" {
  folder     = google_folder.client_root.name
  constraint = "storage.uniformBucketLevelAccess"

  boolean_policy {
    enforced = true
  }
}

# 3. Identity Isolation
resource "google_folder_organization_policy" "allowed_policy_member_domains" {
  folder     = google_folder.client_root.name
  constraint = "iam.allowedPolicyMemberDomains"

  list_policy {
    allow {
      values = [var.directory_customer_id]
    }
  }
}

# 4. Secure Compute Access
resource "google_folder_organization_policy" "require_os_login" {
  folder     = google_folder.client_root.name
  constraint = "compute.requireOsLogin"

  boolean_policy {
    enforced = true
  }
}

# 5. No Public IPs
resource "google_folder_organization_policy" "vm_external_ip_access" {
  folder     = google_folder.client_root.name
  constraint = "compute.vmExternalIpAccess"

  list_policy {
    deny {
      all = true
    }
  }
}

module "project-factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 17.0" # Using a recent stable version compatible with provider v6

  name              = var.client_name
  random_project_id = true
  org_id            = var.org_id
  folder_id         = google_folder.client_root.id
  billing_account   = var.billing_account

  auto_create_network = false

  activate_apis = [
    "compute.googleapis.com",
    "aiplatform.googleapis.com",
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
  ]
}

# Consultancy Group (Platform Team) Access
resource "google_project_iam_member" "consultancy_editor" {
  project = module.project-factory.project_id
  role    = "roles/editor"
  member  = "group:${var.consultancy_group_email}"
}

resource "google_project_iam_member" "consultancy_iam_admin" {
  project = module.project-factory.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "group:${var.consultancy_group_email}"
}

# Client IT Group (Data & AI Bundle) Access
locals {
  client_roles = [
    "roles/compute.admin",
    "roles/aiplatform.admin",
    "roles/bigquery.admin",
    "roles/storage.admin",
    "roles/artifactregistry.admin",
    "roles/cloudbuild.builds.editor",
    "roles/serviceusage.serviceUsageConsumer",
  ]
}

resource "google_project_iam_member" "client_admin" {
  for_each = toset(local.client_roles)

  project = module.project-factory.project_id
  role    = each.value
  member  = "group:${var.client_admin_group_email}"
}
