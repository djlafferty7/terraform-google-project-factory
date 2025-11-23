# Project: Landing Zone as a Product (LZaaP)

## 1. Executive Summary
**Goal:** Transform the client environment setup from a manual, multi-day process into a 10-minute automated product.
**Output:** A Terraform module (V1) that provisions a secure, opinionated, and billable Google Cloud Project encapsulated within a dedicated client folder.

## 2. Technical Foundation
* **Core Engine:** We will not build from scratch. We must leverage the [Google Cloud Foundation Toolkit](https://cloud.google.com/foundation/docs/terraform-modules).
* **Upstream Module:** specifically `terraform-google-modules/project-factory/google`.
* **Infrastructure as Code:** Terraform (HCL).

## 3. V1 Functional Requirements

### A. Hierarchy & Isolation
* **Requirement:** Every new client gets a dedicated **Folder** under the Organization.
* **Naming Convention:** Folder name should match the `client_name` variable.
* **Project Location:** The actual GCP Project must be created *inside* this new Folder.

### B. Identity & Access Management (IAM)
* **Constraint:** No individual users (e.g., `user@gmail.com`) allowed in IAM bindings.
* **Strategy:** Use Google Groups for scalable permission management.
* **Required Bindings:**
    1.  **Internal Engineers:** A group (e.g., `consultancy-engineers@`) receives `roles/owner` (or high-level editor access).
    2.  **Client IT:** A group (e.g., `client-admins@`) receives `roles/editor` (or specific scoped access).

### C. The "Essential" Technology Stack
The module must enable the following APIs by default to ensure the environment is "Data & AI Ready" immediately:
* `compute.googleapis.com` (Compute Engine)
* `aiplatform.googleapis.com` (Vertex AI)
* `bigquery.googleapis.com` (BigQuery)
* `cloudbuild.googleapis.com` (Cloud Build)
* `artifactregistry.googleapis.com` (Artifact Registry)

### D. Security & Governance (The "Non-Negotiables")
The module must enforce specific Organization Policies at the **Project Level** (or Folder Level) to override any loose defaults.
1.  **Disable Key Hazards:** Enforce `iam.disableServiceAccountKeyCreation` to prevent unmanaged credentials.
2.  **Modern Storage:** Enforce `storage.uniformBucketLevelAccess` to prevent legacy ACL usage.

## 4. Input Interface (Variables)
The module must accept the following inputs:
* `client_name` (string): Name of the client (used for Folder/Project naming).
* `org_id` (string): The Organization ID.
* `billing_account` (string): The Billing Account ID to attach.
* `consultancy_group_email` (string): Email of the internal engineering group.
* `client_admin_group_email` (string): Email of the client admin group.
* `region` (string): Default region for resources (default: `us-central1` or similar).

## 5. Definition of Done
The V1 build is considered complete when:
1.  Running `terraform apply` creates a Folder and a Project.
2.  The Project is linked to the correct Billing Account.
3.  The specified APIs are enabled.
4.  IAM bindings show groups only, no users.
5.  Attempts to create a Service Account Key fail (Security Policy verification).
