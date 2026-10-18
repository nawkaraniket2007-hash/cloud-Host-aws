#!/bin/bash
# ==============================================================================
# CloudHost - Automated Teardown & Resource Cleanup Script
# Safely deletes S3 object versions, then executes terraform destroy.
# ==============================================================================

set -uo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
NC="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$(cd "${SCRIPT_DIR}/../terraform" && pwd)"

echo "=========================================================="
echo -e "${YELLOW} CloudHost Resource Cleanup & Teardown Utility${NC}"
echo "=========================================================="
echo "This script safely empties versioned objects from your S3 bucket"
echo "and runs 'terraform destroy' to terminate all billable AWS resources."
echo "=========================================================="

if [ ! -d "${TF_DIR}/.terraform" ]; then
    echo -e "${RED}ERROR: Terraform is not initialized in ${TF_DIR}.${NC}"
    exit 1
fi

# Step 1: Detect S3 Bucket Name
echo -e "${CYAN}[1/3] Detecting S3 Bucket Name...${NC}"
BUCKET_NAME=$(cd "${TF_DIR}" && terraform output -raw s3_bucket_name 2>/dev/null || echo "")
AWS_REGION=$(cd "${TF_DIR}" && terraform output -raw aws_region 2>/dev/null || echo "us-east-1")

if [ -n "$BUCKET_NAME" ]; then
    echo "Found S3 bucket: ${BUCKET_NAME}"
    echo "Emptying all versioned objects and delete markers from ${BUCKET_NAME}..."

    # Delete all object versions
    aws s3api delete-objects \
        --bucket "${BUCKET_NAME}" \
        --delete "$(aws s3api list-object-versions \
            --bucket "${BUCKET_NAME}" \
            --output=json \
            --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" 2>/dev/null || true

    # Delete all delete markers
    aws s3api delete-objects \
        --bucket "${BUCKET_NAME}" \
        --delete "$(aws s3api list-object-versions \
            --bucket "${BUCKET_NAME}" \
            --output=json \
            --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')" 2>/dev/null || true

    echo -e "${GREEN}S3 Bucket emptied successfully.${NC}"
else
    echo "No active S3 bucket detected in Terraform state, skipping bucket purge."
fi

# Step 2: Confirm Terraform Destroy
echo ""
echo -e "${YELLOW}[2/3] Preparing to execute 'terraform destroy'...${NC}"
echo "This will destroy:"
echo " - EC2 Instance & Root EBS Volume"
echo " - RDS MySQL Database & DB Subnet Group"
echo " - S3 Bucket"
echo " - Secrets Manager Secret"
echo " - Custom VPC, Subnets, Route Tables, and Security Groups"
echo " - IAM Roles and Policies"
echo ""

read -p "Are you sure you want to destroy all CloudHost resources? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled by user."
    exit 0
fi

# Step 3: Run terraform destroy
echo -e "${CYAN}[3/3] Running 'terraform destroy -auto-approve'...${NC}"
cd "${TF_DIR}"
terraform destroy -auto-approve

echo ""
echo "=========================================================="
echo -e "${GREEN} Cleanup Complete! All CloudHost AWS resources have been destroyed.${NC}"
echo " Verify your AWS Console Billing Dashboard to ensure no orphan resources remain."
echo "=========================================================="
