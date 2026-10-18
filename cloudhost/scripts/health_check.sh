#!/bin/bash
# ==============================================================================
# CloudHost - Automated Health & Diagnostic Verification Script
# Tests web accessibility, API health endpoints, DB connectivity, and S3 status.
# Usage:
#   ./health_check.sh [http://<ec2-ip-or-dns>]
# ==============================================================================

set -uo pipefail

# ANSI Color codes for clean reporting
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$(cd "${SCRIPT_DIR}/../terraform" && pwd)"

TARGET_URL="${1:-}"

# Auto-detect URL from Terraform output if not provided
if [ -z "$TARGET_URL" ]; then
    if [ -f "${TF_DIR}/terraform.tfstate" ]; then
        echo -e "${CYAN}Querying website URL from Terraform output...${NC}"
        TARGET_URL=$(cd "${TF_DIR}" && terraform output -raw website_url 2>/dev/null || echo "")
    fi
fi

if [ -z "$TARGET_URL" ]; then
    echo -e "${YELLOW}Usage: ./health_check.sh http://<ec2-ip-or-dns>${NC}"
    exit 1
fi

# Strip trailing slash if present
TARGET_URL="${TARGET_URL%/}"

echo "=========================================================="
echo -e "${CYAN} Running CloudHost Diagnostics on: ${TARGET_URL}${NC}"
echo "=========================================================="

PASSED=0
FAILED=0

check_endpoint() {
    local name="$1"
    local endpoint="$2"
    local expected_http="$3"
    local expected_pattern="$4"

    echo -n "Checking ${name} (${endpoint})... "

    # Perform curl request with 5s timeout
    local response
    local http_code
    response=$(curl -s -w "\n%{http_code}" --connect-timeout 5 "${TARGET_URL}${endpoint}" 2>/dev/null || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    local body
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" -eq "$expected_http" ]; then
        if [ -n "$expected_pattern" ]; then
            if echo "$body" | grep -q "$expected_pattern"; then
                echo -e "${GREEN}[PASS]${NC} (HTTP $http_code)"
                PASSED=$((PASSED + 1))
            else
                echo -e "${RED}[FAIL]${NC} (HTTP $http_code, but pattern '${expected_pattern}' not matched)"
                echo "Response snippet: $(echo "$body" | head -n 3)"
                FAILED=$((FAILED + 1))
            fi
        else
            echo -e "${GREEN}[PASS]${NC} (HTTP $http_code)"
            PASSED=$((PASSED + 1))
        fi
    else
        echo -e "${RED}[FAIL]${NC} (Expected HTTP $expected_http, got $http_code)"
        FAILED=$((FAILED + 1))
    fi
}

# 1. Main Home Page Check
check_endpoint "Home Page" "/" 200 "CloudHost"

# 2. General Health Endpoint
check_endpoint "General Health" "/health" 200 "ok"

# 3. Amazon DynamoDB Database Health Endpoint
check_endpoint "DynamoDB Health" "/health/db" 200 "healthy"

# 4. Amazon S3 Storage Health Endpoint
check_endpoint "Amazon S3 Health" "/health/s3" 200 "healthy"

# 5. AWS Lambda Health Endpoint
check_endpoint "AWS Lambda Health" "/health/lambda" 200 "healthy"

# 6. Dashboard Page Check
check_endpoint "System Dashboard" "/dashboard" 200 "Dashboard"

# 7. Upload Page Check
check_endpoint "Upload Form" "/upload" 200 "Ingest"

echo "=========================================================="
echo -e "Diagnostic Results: ${GREEN}${PASSED} Passed${NC}, ${RED}${FAILED} Failed${NC}"
echo "=========================================================="

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}All infrastructure components (EC2, Nginx, Gunicorn, DynamoDB, S3, Lambda) are operational!${NC}"
    exit 0
else
    echo -e "${RED}One or more checks failed. See docs/troubleshooting.md for diagnostic steps.${NC}"
    exit 1
fi
