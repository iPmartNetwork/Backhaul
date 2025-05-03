#!/bin/bash

# Installer for backhaul-api systemd service

SCRIPT_PATH="/usr/local/bin/backhaul.sh"
SERVICE_FILE="/etc/systemd/system/backhaul-api.service"

echo "[+] Installing Backhaul API..."

# Copy script to /usr/local/bin
cp ./backhaul_v2.3_api.sh "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# Create systemd service file
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Backhaul Internal API Service
After=network.target

[Service]
ExecStart=$SCRIPT_PATH --api
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start service
systemctl daemon-reload
systemctl enable --now backhaul-api

echo "[+] Backhaul API is now running as a systemd service on port 22490."
systemctl status backhaul-api --no-pager
