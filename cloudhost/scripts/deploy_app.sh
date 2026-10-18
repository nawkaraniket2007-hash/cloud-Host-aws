#!/bin/bash
# ==============================================================================
# CloudHost - Application Deployment / Hot-Reload Script
# Syncs application code, templates, and static assets, then reloads Gunicorn.
# Usage:
#   On EC2 instance: sudo ./deploy_app.sh
#   Or remotely:     ./deploy_app.sh <ec2-ip-address> [ssh-key-path]
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/../app" && pwd)"

if [ "$#" -eq 0 ]; then
    # Running locally on the EC2 instance
    echo "=== Deploying CloudHost Application Locally ==="
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root or with sudo."
        exit 1
    fi

    TARGET_DIR="/opt/cloudhost"
    mkdir -p "${TARGET_DIR}/templates" "${TARGET_DIR}/static/css" "${TARGET_DIR}/static/js"

    echo "Copying application files to ${TARGET_DIR}..."
    cp -r "${APP_DIR}/app.py" "${TARGET_DIR}/"
    cp -r "${APP_DIR}/requirements.txt" "${TARGET_DIR}/"
    cp -r "${APP_DIR}/templates/"* "${TARGET_DIR}/templates/"
    cp -r "${APP_DIR}/static/css/"* "${TARGET_DIR}/static/css/"
    cp -r "${APP_DIR}/static/js/"* "${TARGET_DIR}/static/js/"

    chown -R cloudhost:cloudhost "${TARGET_DIR}"

    echo "Restarting cloudhost.service..."
    systemctl daemon-reload
    systemctl restart cloudhost.service
    sleep 2

    echo "Checking service status:"
    systemctl status cloudhost.service --no-pager -n 5

    echo "=== Deployment Finished Successfully ==="
else
    # Running remotely from operator machine
    TARGET_IP="$1"
    SSH_KEY="${2:-}"
    SSH_CMD="ssh -o StrictHostKeyChecking=no"
    if [ -n "$SSH_KEY" ]; then
        SSH_CMD="ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no"
    fi

    echo "=== Deploying CloudHost Application to ${TARGET_IP} ==="
    RSYNC_SSH="ssh -o StrictHostKeyChecking=no"
    if [ -n "$SSH_KEY" ]; then
        RSYNC_SSH="ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no"
    fi

    echo "Syncing code files..."
    rsync -avz -e "${RSYNC_SSH}" \
        --exclude '__pycache__' \
        --exclude '.env' \
        "${APP_DIR}/" "ubuntu@${TARGET_IP}:/tmp/cloudhost_app/"

    echo "Applying updates on remote EC2 host..."
    ${SSH_CMD} "ubuntu@${TARGET_IP}" "
        sudo cp -r /tmp/cloudhost_app/* /opt/cloudhost/
        sudo chown -R cloudhost:cloudhost /opt/cloudhost
        sudo systemctl restart cloudhost.service
        sleep 2
        sudo systemctl is-active cloudhost.service
    "
    echo "=== Remote Deployment Succeeded ==="
fi
