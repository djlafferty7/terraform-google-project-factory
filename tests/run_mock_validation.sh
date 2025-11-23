#!/bin/bash
set -e

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$DIR/.."

# Create a temporary bin directory for the mock gcloud
MOCK_BIN="$DIR/bin"
mkdir -p "$MOCK_BIN"

# Create the mock gcloud script
cat <<EOF > "$MOCK_BIN/gcloud"
#!/bin/bash
# Pass arguments to the logic
args="\$@"

# Mock: Check API Enablement
if [[ "\$args" == *"services list"* ]]; then
    echo "aiplatform.googleapis.com"
    echo "compute.googleapis.com"
    exit 0
fi

# Mock: List Service Accounts
if [[ "\$args" == *"iam service-accounts list"* ]]; then
    echo "test-compute@developer.gserviceaccount.com"
    exit 0
fi

# Mock: Create Key (Must Fail for Pass)
if [[ "\$args" == *"iam service-accounts keys create"* ]]; then
    echo "ERROR: (gcloud.iam.service-accounts.keys.create) Permission denied." >&2
    exit 1 # Fail as expected
fi

# Mock: Bucket Operations
if [[ "\$args" == *"storage buckets create"* ]]; then
    exit 0
fi

if [[ "\$args" == *"storage buckets describe"* ]]; then
    echo "True"
    exit 0
fi

if [[ "\$args" == *"storage buckets delete"* ]]; then
    exit 0
fi
EOF

chmod +x "$MOCK_BIN/gcloud"

# Add the mock bin to the PATH
export PATH="$MOCK_BIN:$PATH"

echo ">>> RUNNING MOCK TEST <<<"

# Run the validation script from the project root
"$PROJECT_ROOT/validate.sh" "mock-project-id"
RESULT=$?

# Cleanup
rm -rf "$MOCK_BIN"

if [ $RESULT -eq 0 ]; then
    echo ">>> MOCK TEST PASSED <<<"
else
    echo ">>> MOCK TEST FAILED <<<"
fi
exit $RESULT
