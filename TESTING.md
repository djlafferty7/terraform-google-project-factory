# Testing Strategy: Landing Zone V1

## 1. Philosophy
This module is a "Product." It must be tested to ensure it delivers the promised value (APIs) and security (Policies).

## 2. Validation Script Requirements
We need a script (e.g., `validate.sh`) that runs after `terraform apply` to perform the following checks via `gcloud`:

### Check A: API Enablement
* **Command:** `gcloud services list --project=[PROJECT_ID] --enabled`
* **Assertion:** Verify that `aiplatform.googleapis.com` and `compute.googleapis.com` are present in the output.

### Check B: Security Policy (The Negative Test)
* **Goal:** Verify that `iam.disableServiceAccountKeyCreation` is active.
* **Method:** Attempt to create a key for the default Compute Engine service account.
* **Expected Result:** The command **MUST FAIL** with a permission denied or policy violation error. If it succeeds, the test fails.

### Check C: Bucket Uniform Access
* **Goal:** Verify Storage Policy.
* **Method:** Create a temporary bucket and check its configuration.
* **Command:** `gcloud storage buckets describe gs://[BUCKET_NAME] --format="value(iamConfiguration.uniformBucketLevelAccess.enabled)"`
* **Expected Result:** Output must be `True`.

## 3. Manual Acceptance Test (The "Smoke Test")
1. Run `terraform apply`.
2. Log into the GCP Console.
3. Navigate to the new Project.
4. Go to **IAM**. Verify you see *Groups* only, no individual users.
5. Go to **Vertex AI**. Verify the dashboard loads without an "Enable API" prompt.

## 4. Test Data
* Use a `testing.tfvars` file (git-ignored) to supply a real Billing ID and Org ID for the test runs.
