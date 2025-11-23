# Landing Zone as a Product (LZaaP)

A Terraform module that provisions a secure, opinionated, and billable Google Cloud Project encapsulated within a dedicated client folder.

## Features

This module automates the setup of a client environment with the following features:

*   **Hierarchy & Isolation**: Creates a dedicated Folder for the client and a Project within it.
*   **Identity & Access Management**: Uses Google Groups for permissions (no individual users).
*   **Essential Tech Stack**: Enables key APIs by default (Compute, Vertex AI, BigQuery, Cloud Build, Artifact Registry).
*   **Security & Governance**: Enforces Organization Policies for:
    *   Disabling Service Account Key creation.
    *   Enforcing Uniform Bucket Level Access.
    *   Restricting IAM grants to the organization's domain (`allowedPolicyMemberDomains`).
    *   Enforcing OS Login for Compute Engine.
    *   Blocking all external IP access for VMs.

## Quick Start (Zero-Inference)

For a fully automated setup, use the provided `deploy.sh` script. This script will:
1. Check your environment prerequisites.
2. Interactively prompt you for all required inputs.
3. Automatically create the required Google Groups (if you have permissions).
4. Run Terraform to deploy the infrastructure.
5. Validate the deployment with security checks.

**Run the following command:**

```bash
./deploy.sh
```

---

## Prerequisites

Before running the deployment, ensure you have the following permissions and information.

### Required Permissions
The user running the script needs these roles on the **Organization**:
*   **Folder Creator** (`roles/resourcemanager.folderCreator`): To create the client folder.
*   **Project Creator** (`roles/resourcemanager.projectCreator`): To create the project.
*   **Billing User** (`roles/billing.user`): To link the project to the billing account.
*   **Group Admin** (Optional): To create Google Groups automatically. If you lack this, you can provide existing group emails.

### How to Find Your IDs

| ID Type | How to Find It |
| :--- | :--- |
| **Organization ID** | Run `gcloud organizations list` or look at the top-left dropdown in the Cloud Console. |
| **Billing Account ID** | Run `gcloud beta billing accounts list` or go to **Billing** in the Console. |
| **Customer ID** | Go to **admin.google.com** > **Account** > **Account Settings**. It usually starts with `C...`. |

### Important Notes
*   **New Projects Only**: This tool is designed to create a **NEW** project and folder structure. It cannot be used to "adopt" or import existing projects.
*   **Clean Slate**: The deployment enforces a clean networking slate (`auto_create_network = false`) and strict security policies.

---

## Manual Usage (Advanced)

If you prefer to run Terraform manually or integrate this into a CI/CD pipeline:

1.  **Clone the repository.**
2.  **Create a `terraform.tfvars` file** with your values (do not commit this file):

    ```hcl
    client_name              = "acme-corp"
    org_id                   = "123456789012"
    billing_account          = "012345-6789AB-CDEF01"
    consultancy_group_email  = "engineers@consultancy.com"
    client_admin_group_email = "admins@client.com"
    directory_customer_id    = "C01234567"
    region                   = "us-central1"
    ```

3.  **Initialize and Apply:**

    ```bash
    terraform init
    terraform apply
    ```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `client_name` | Name of the client (used for Folder/Project naming). | `string` | n/a |
| `org_id` | The Organization ID. | `string` | n/a |
| `billing_account` | The Billing Account ID. | `string` | n/a |
| `consultancy_group_email` | Email of the internal engineering group. | `string` | n/a |
| `client_admin_group_email` | Email of the client admin group. | `string` | n/a |
| `directory_customer_id` | The Google Workspace Customer ID. | `string` | n/a |
| `region` | Default region for resources. | `string` | `us-central1` |

## Testing & Validation

This project includes a validation script `validate.sh` to verify the environment after provisioning. The `deploy.sh` script runs this automatically.

### Prerequisites for Validation
*   `gcloud` CLI installed and authenticated.
*   Permissions to view the project, creating storage buckets (for testing), and managing IAM.

### Running the Validation

```bash
./validate.sh <PROJECT_ID>
```

The script checks:
1.  **API Enablement**: Verifies `aiplatform.googleapis.com` and `compute.googleapis.com` are enabled.
2.  **Security Policy (Negative Test)**: Confirms that creating a Service Account Key fails.
3.  **Bucket Uniform Access**: Creates a temporary bucket to verify `uniformBucketLevelAccess` is enforced.
