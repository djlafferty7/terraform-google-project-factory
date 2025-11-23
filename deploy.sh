#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function for printing
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. Pre-flight Checks
log_info "Starting Pre-flight Checks..."

if ! command -v terraform &> /dev/null; then
    log_error "Terraform is not installed or not in your PATH."
    log_info "Please install Terraform: https://developer.hashicorp.com/terraform/install"
    exit 1
fi

if ! command -v gcloud &> /dev/null; then
    log_error "Google Cloud CLI (gcloud) is not installed or not in your PATH."
    log_info "Please install gcloud: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# check if gcloud is authenticated
if ! gcloud auth print-identity_token &> /dev/null; then
    log_warn "It seems you are not authenticated with gcloud."
    log_info "Please run 'gcloud auth login' and 'gcloud auth application-default login'."
    # We don't exit here, just warn, in case they are using a different auth method (like env vars)
fi

log_success "Pre-flight checks passed."

echo ""
echo "================================================================="
echo "   Landing Zone as a Product (LZaaP) - Deployment Script"
echo "================================================================="
log_warn "This script creates a NEW Google Cloud Project and Folder."
log_warn "It is NOT designed to import or manage existing projects."
echo ""

# 2. Collect Inputs
log_info "Please provide the following configuration details:"

read -p "Client Name (e.g., acme-corp): " CLIENT_NAME
while [[ -z "$CLIENT_NAME" ]]; do
    log_error "Client Name cannot be empty."
    read -p "Client Name (e.g., acme-corp): " CLIENT_NAME
done

read -p "Organization ID (numeric): " ORG_ID
while [[ -z "$ORG_ID" ]]; do
    log_error "Organization ID cannot be empty."
    read -p "Organization ID (numeric): " ORG_ID
done

read -p "Billing Account ID (e.g., 000000-000000-000000): " BILLING_ACCOUNT
while [[ -z "$BILLING_ACCOUNT" ]]; do
    log_error "Billing Account ID cannot be empty."
    read -p "Billing Account ID (e.g., 000000-000000-000000): " BILLING_ACCOUNT
done

read -p "Google Workspace Customer ID (e.g., C01234567): " DIRECTORY_CUSTOMER_ID
while [[ -z "$DIRECTORY_CUSTOMER_ID" ]]; do
    log_error "Customer ID cannot be empty."
    read -p "Google Workspace Customer ID (e.g., C01234567): " DIRECTORY_CUSTOMER_ID
done

read -p "Region (default: us-central1): " REGION
REGION=${REGION:-us-central1}

# 3. Group Handling Logic
create_or_ask_group() {
    local group_role_name="$1"
    local group_email=""
    local create_choice=""

    echo ""
    log_info "Configuration for: $group_role_name"
    read -p "Do you want to create a NEW Google Group for this role? (y/n): " create_choice

    if [[ "$create_choice" =~ ^[Yy]$ ]]; then
        read -p "Enter desired email for the new group: " group_email

        log_info "Attempting to create group '$group_email'..."

        # Try creating the group. We suppress stdout but show stderr if it fails.
        if gcloud identity groups create "$group_email" --organization="$ORG_ID" --quiet 2>/dev/null; then
            log_success "Group '$group_email' created successfully."
        else
            # Try with customer ID if org id failed (sometimes needed for workspace)
             if gcloud identity groups create "$group_email" --customer="$DIRECTORY_CUSTOMER_ID" --quiet 2>/dev/null; then
                 log_success "Group '$group_email' created successfully."
             else
                log_warn "Failed to automatically create group '$group_email'. You might lack permissions."
                log_info "Falling back to manual input."
                read -p "Please enter the email of an EXISTING group for $group_role_name: " group_email
             fi
        fi
    else
        read -p "Enter the email of an EXISTING group for $group_role_name: " group_email
    fi

    # Validation
    while [[ -z "$group_email" ]]; do
        log_error "Group email cannot be empty."
        read -p "Enter the email of an EXISTING group for $group_role_name: " group_email
    done

    echo "$group_email"
}

CONSULTANCY_GROUP=$(create_or_ask_group "Consultancy/Platform Team")
CLIENT_ADMIN_GROUP=$(create_or_ask_group "Client IT/Admin Team")

# 4. Generate terraform.tfvars
echo ""
log_info "Generating terraform.tfvars..."

cat > terraform.tfvars <<EOF
client_name              = "${CLIENT_NAME}"
org_id                   = "${ORG_ID}"
billing_account          = "${BILLING_ACCOUNT}"
consultancy_group_email  = "${CONSULTANCY_GROUP}"
client_admin_group_email = "${CLIENT_ADMIN_GROUP}"
directory_customer_id    = "${DIRECTORY_CUSTOMER_ID}"
region                   = "${REGION}"
EOF

log_success "terraform.tfvars created."

# 5. Terraform Execution
echo ""
log_info "Initializing Terraform..."
terraform init

echo ""
log_info "Applying Terraform configuration..."
if terraform apply -auto-approve; then
    log_success "Infrastructure deployed successfully!"
else
    log_error "Terraform apply failed. Check the output above."
    exit 1
fi

# 6. Post-Deployment Validation
echo ""
log_info "Running post-deployment validation..."

# Extract Project ID from Terraform output
PROJECT_ID=$(terraform output -raw project_id)

if [[ -z "$PROJECT_ID" ]]; then
    log_error "Could not retrieve project_id from Terraform output. Skipping validation."
    exit 1
fi

if [[ -f "./validate.sh" ]]; then
    chmod +x ./validate.sh
    ./validate.sh "$PROJECT_ID"
else
    log_warn "validate.sh not found. Skipping validation."
fi

echo ""
log_success "Deployment and Validation Complete!"
