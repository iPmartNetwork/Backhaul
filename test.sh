#!/bin/bash

set -e

VERSION="0.1"
CONFIG_DIR="/opt/backhaul"
BIN="$CONFIG_DIR/backhaul"
SERVICE_DIR="/etc/systemd/system"
JSON_LOG="/var/log/backhaul_tunnels.json"
GITHUB_REPO="https://github.com/Musixal/Backhaul/releases/tag/v0.6.5"

# Color setup
PURPLE='\033[0;35m'
INDIGO='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

mkdir -p "$CONFIG_DIR"

# Detect architecture and download binary
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH_DL="amd64" ;;
    aarch64) ARCH_DL="arm64" ;;
    *) echo -e "${YELLOW}[!] Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

FILE_URL="https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_${ARCH_DL}.tar.gz"
echo -e "${INDIGO}[i] Downloading Backhaul v0.6.5 for $ARCH_DL...${NC}"
curl -Lo "/tmp/backhaul_${ARCH_DL}.tar.gz" "$FILE_URL"
tar -xf "/tmp/backhaul_${ARCH_DL}.tar.gz" -C "$CONFIG_DIR"
chmod +x "$BIN"

echo -e "${PURPLE}=== Backhaul Tunnel Setup v${VERSION} ===${NC}"

read -rp "Tunnel name: " TUNNEL_NAME
read -rp "IRAN server IP or domain: " SERVER_IP
read -rp "Tunnel port (e.g. 443): " PORT
read -rp "Authentication token: " TOKEN

echo -e "${YELLOW}Select transport:${NC}"
echo -e "${INDIGO}1) tcp\n2) udp\n3) ws\n4) wss\n5) faketcptun\n6) icmp${NC}"
read -rp "Option [1-6]: " TRANSPORT

case $TRANSPORT in
    1) TRANSPORT_TYPE="tcp" ;;
    2) TRANSPORT_TYPE="udp" ;;
    3) TRANSPORT_TYPE="ws" ;;
    4) TRANSPORT_TYPE="wss" ;;
    5) TRANSPORT_TYPE="faketcptun" ;;
    6) TRANSPORT_TYPE="icmp" ;;
    *) echo -e "${YELLOW}[!] Invalid option${NC}"; exit 1 ;;
esac

EDGE_LINE="#edge_ip = \"\""
if [[ "$TRANSPORT_TYPE" =~ ^(ws|wss)$ ]]; then
    read -rp "Edge IP or domain (optional): " EDGE
    if [[ -n "$EDGE" ]]; then
        EDGE_LINE="edge_ip = \"$EDGE\""
    fi
fi

MUX_VERSION=2
POOL=8
NODELAY=true
WEB_PORT=0
SNIFFER=false
TUN_NAME="backhaul"
TUN_SUBNET="10.10.10.0/24"
MTU=1500

CONFIG_FILE="${CONFIG_DIR}/${TUNNEL_NAME}.toml"

cat <<EOF > "$CONFIG_FILE"
[client]
remote_addr = "${SERVER_IP}:${PORT}"
$EDGE_LINE
transport = "${TRANSPORT_TYPE}"
token = "${TOKEN}"
connection_pool = ${POOL}
aggressive_pool = false
keepalive_period = 75
nodelay = ${NODELAY}
retry_interval = 3
dial_timeout = 10
mux_version = ${MUX_VERSION}
mux_framesize = 32768
mux_recievebuffer = 4194304
mux_streambuffer = 2000000
sniffer = ${SNIFFER}
web_port = ${WEB_PORT}
sniffer_log = "/root/log.json"
log_level = "info"
ip_limit = false
tun_name = "${TUN_NAME}"
tun_subnet = "${TUN_SUBNET}"
mtu = ${MTU}
EOF

SERVICE_NAME="backhaul-${TUNNEL_NAME}.service"
SERVICE_FILE="${SERVICE_DIR}/${SERVICE_NAME}"

cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Backhaul Tunnel ($TUNNEL_NAME)
After=network.target

[Service]
ExecStart=$BIN -c $CONFIG_FILE
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"

STATUS="started"
if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    STATUS="failed"
fi

mkdir -p "$(dirname "$JSON_LOG")"
cat <<EOF > "$JSON_LOG"
{
  "version": "$VERSION",
  "tunnel_name": "$TUNNEL_NAME",
  "server_ip": "$SERVER_IP",
  "port": "$PORT",
  "transport": "$TRANSPORT_TYPE",
  "edge_ip": "${EDGE:-null}",
  "token": "$TOKEN",
  "status": "$STATUS",
  "config_file": "$CONFIG_FILE",
  "service": "$SERVICE_NAME"
}
EOF

echo -e "${PURPLE}✔ Tunnel '$TUNNEL_NAME' is $STATUS. Configuration saved to:${NC} ${YELLOW}$JSON_LOG${NC}"
