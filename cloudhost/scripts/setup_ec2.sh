#!/bin/bash
# ==============================================================================
# CloudHost - Standalone EC2 Manual Setup & Configuration Script
# Use this script when configuring an EC2 instance manually or in debugging mode.
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo " Starting CloudHost EC2 Host Configuration"
echo "=========================================================="

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script as root (e.g., sudo ./setup_ec2.sh)"
    exit 1
fi

# 1. Update and install packages
echo "[1/7] Updating apt repositories and installing core packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    nginx \
    git \
    awscli \
    jq \
    curl \
    netcat-openbsd

# 2. Setup user and directories
echo "[2/7] Configuring application user and directories..."
id -u cloudhost &>/dev/null || useradd -m -s /bin/bash cloudhost
mkdir -p /opt/cloudhost /var/log/cloudhost
chown -R cloudhost:cloudhost /opt/cloudhost /var/log/cloudhost

# 3. Setup Python virtual environment
echo "[3/7] Setting up Python virtual environment..."
if [ ! -d "/opt/cloudhost/venv" ]; then
    python3 -m venv /opt/cloudhost/venv
fi
/opt/cloudhost/venv/bin/pip install --upgrade pip

# 4. Install dependencies
echo "[4/7] Installing Python dependencies..."
if [ -f "/opt/cloudhost/requirements.txt" ]; then
    /opt/cloudhost/venv/bin/pip install -r /opt/cloudhost/requirements.txt
else
    /opt/cloudhost/venv/bin/pip install \
        "Flask>=3.0.0" \
        "PyMySQL>=1.1.0" \
        "cryptography>=42.0.0" \
        "boto3>=1.34.0" \
        "gunicorn>=22.0.0" \
        "python-dotenv>=1.0.0" \
        "requests>=2.31.0"
fi

# 5. Systemd service configuration
echo "[5/7] Registering systemd service..."
cat << 'SERVICE_EOF' > /etc/systemd/system/cloudhost.service
[Unit]
Description=CloudHost Gunicorn Application Service
After=network.target

[Service]
User=cloudhost
Group=cloudhost
WorkingDirectory=/opt/cloudhost
EnvironmentFile=/opt/cloudhost/.env
ExecStart=/opt/cloudhost/venv/bin/gunicorn \
    --workers 2 \
    --bind 127.0.0.1:5000 \
    --access-logfile /var/log/cloudhost/access.log \
    --error-logfile /var/log/cloudhost/error.log \
    app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE_EOF

systemctl daemon-reload

# 6. Nginx reverse proxy configuration
echo "[6/7] Configuring Nginx reverse proxy..."
cat << 'NGINX_EOF' > /etc/nginx/sites-available/cloudhost
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    client_max_body_size 12M;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 90;
        proxy_connect_timeout 90;
    }

    location /static/ {
        alias /opt/cloudhost/static/;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
}
NGINX_EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/cloudhost /etc/nginx/sites-enabled/cloudhost
nginx -t
systemctl restart nginx

# 7. Final status checks
echo "[7/7] Verifying setup status..."
echo "Nginx Service: $(systemctl is-active nginx)"
echo "Next step: Ensure /opt/cloudhost/.env contains valid DB and S3 credentials, then run:"
echo "  sudo systemctl restart cloudhost.service"
echo "=========================================================="
echo " Setup complete!"
echo "=========================================================="
