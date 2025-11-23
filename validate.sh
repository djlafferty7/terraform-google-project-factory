#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_ID="$1"

if [ -z "$PROJECT_ID" ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

echo "Starting validation for Project: $PROJECT_ID..."

# ---------------------------------------------------------
# Check A: API Enablement
# ---------------------------------------------------------
echo -n "Checking API Enablement... "

ENABLED_SERVICES=$(gcloud services list --project="$PROJECT_ID" --enabled --format="value(config.name)")

if echo "$ENABLED_SERVICES" | grep -q "aiplatform.googleapis.com" && echo "$ENABLED_SERVICES" | grep -q "compute.googleapis.com"; then
  echo -e "${GREEN}PASS${NC}"
else
  echo -e "${RED}FAIL${NC}"
  echo "Required APIs (aiplatform, compute) are not enabled."
  exit 1
fi

# ---------------------------------------------------------
# Check B: Security Policy (The Negative Test)
# ---------------------------------------------------------
echo -n "Checking Security Policy (Disable Key Creation)... "

# Get the default compute service account
DEFAULT_SA=$(gcloud iam service-accounts list --project="$PROJECT_ID" --filter="email ~ -compute@developer.gserviceaccount.com" --format="value(email)" | head -n 1)

if [ -z "$DEFAULT_SA" ]; then
    # Fallback if no compute SA, try to pick any SA or skip if none
    DEFAULT_SA=$(gcloud iam service-accounts list --project="$PROJECT_ID" --limit=1 --format="value(email)")
fi

if [ -z "$DEFAULT_SA" ]; then
    echo -e "${RED}SKIP${NC} (No Service Account found to test)"
else
    # Attempt to create a key - expected to FAIL
    if gcloud iam service-accounts keys create /dev/null --iam-account="$DEFAULT_SA" --project="$PROJECT_ID" --quiet > /dev/null 2>&1; then
        echo -e "${RED}FAIL${NC}"
        echo "ERROR: Successfully created a Service Account Key! Policy is not working."
        # Clean up the key we just created? Ideally we shouldn't have been able to create it.
        exit 1
    else
        echo -e "${GREEN}PASS${NC} (Key creation denied as expected)"
    fi
fi

# ---------------------------------------------------------
# Check C: Bucket Uniform Access
# ---------------------------------------------------------
echo -n "Checking Bucket Uniform Access... "

RANDOM_SUFFIX=$(date +%s)
TEST_BUCKET_NAME="validation-test-${PROJECT_ID}-${RANDOM_SUFFIX}"

# Create a bucket
if ! gcloud storage buckets create "gs://${TEST_BUCKET_NAME}" --project="$PROJECT_ID" --quiet > /dev/null 2>&1; then
    echo -e "${RED}FAIL${NC} (Could not create test bucket)"
    exit 1
fi

# Check the policy
UBLA_ENABLED=$(gcloud storage buckets describe "gs://${TEST_BUCKET_NAME}" --format="value(iamConfiguration.uniformBucketLevelAccess.enabled)")

# Clean up bucket
gcloud storage buckets delete "gs://${TEST_BUCKET_NAME}" --quiet > /dev/null 2>&1

if [ "$UBLA_ENABLED" == "True" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    echo "Uniform Bucket Level Access is NOT enabled on new buckets."
    exit 1
fi

echo "---------------------------------------------------------"
echo -e "${GREEN}All Validation Checks Passed!${NC}"
