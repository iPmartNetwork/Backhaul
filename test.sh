#!/bin/bash

set -e

VERSION="0.1"
CONFIG_DIR="/opt/backhaul"
BIN="$CONFIG_DIR/backhaul"
SERVICE_DIR="/etc/systemd/system"
JSON_LOG="/var/log/backhaul_tunnels.json"

# Terminal colors
PURPLE='\033[0;35m'
INDIGO='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p "$CONFIG_DIR"

# Detect OS and architecture
ARCH=$(uname -m)
OS=$(uname | tr '[:upper:]' '[:lower:]')

case "$ARCH" in
    x86_64) ARCH_DL="amd64" ;;
    aarch64) ARCH_DL="arm64" ;;
    *) echo -e "${YELLOW}[!] Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

case "$OS" in
    linux|darwin) PLATFORM="$OS" ;;
    *) echo -e "${YELLOW}[!] Unsupported operating system: $OS${NC}"; exit 1 ;;
esac

FILE="backhaul_${PLATFORM}_${ARCH_DL}.tar.gz"
FILE_URL="https://github.com/Musixal/Backhaul/releases/download/v0.6.5/$FILE"
CHECKSUM_URL="$FILE_URL.sha256"

echo -e "${INDIGO}[i] Downloading Backhaul v0.6.5 for ${PLATFORM}/${ARCH_DL}...${NC}"
curl -fLo "/tmp/$FILE" "$FILE_URL" || {
  echo -e "${YELLOW}[!] Download failed. Falling back to default linux_amd64...${NC}"
  curl -fLo "/tmp/backhaul_linux_amd64.tar.gz" "https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz"
  tar -xf "/tmp/backhaul_linux_amd64.tar.gz" -C "$CONFIG_DIR"
}

# Verify file integrity
if curl -fsSL "$CHECKSUM_URL" -o "/tmp/$FILE.sha256"; then
  echo "$(cat /tmp/$FILE.sha256)  /tmp/$FILE" | sha256sum -c -
else
  echo -e "${YELLOW}[!] SHA256 file not found. Continuing with caution...${NC}"
fi

tar -xf "/tmp/$FILE" -C "$CONFIG_DIR"
chmod +x "$BIN"

# Optional: Run Tunnel Manager
read -rp "Do you want to open the Tunnel Manager? (y/n): " MANAGE_CHOICE
if [[ "$MANAGE_CHOICE" == "y" || "$MANAGE_CHOICE" == "Y" ]]; then
    if [[ -x "$CONFIG_DIR/backhaul_manager.sh" ]]; then
        bash "$CONFIG_DIR/backhaul_manager.sh"
        exit 0
    else
        echo -e "${YELLOW}[!] backhaul_manager.sh not found.${NC}"
    fi
fi

# Server role (IR or External)
echo -e "${YELLOW}Is the server located in Iran or abroad?${NC}"
echo -e "${INDIGO}1) Iran\n2) Abroad${NC}"
read -rp "Option [1-2]: " SERVER_LOCATION

case $SERVER_LOCATION in
    1) ROLE="iran" ;;
    2) ROLE="kharej" ;;
    *) echo -e "${YELLOW}[!] Invalid option${NC}"; exit 1 ;;
esac

# Tunnel details
echo -e "${PURPLE}=== Backhaul Tunnel Setup v${VERSION} ===${NC}"
read -rp "Tunnel name: " TUNNEL_NAME
read -rp "IR server IP or domain: " SERVER_IP
read -rp "Tunnel port (e.g. 443): " PORT
read -rp "Authentication token: " TOKEN

echo -e "${YELLOW}Select transport type:${NC}"
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

# Default values
MUX_VERSION=2
POOL=8
NODELAY=true
WEB_PORT=0
SNIFFER=false
TUN_NAME="backhaul"
TUN_SUBNET="10.10.10.0/24"
MTU=1500

CONFIG_FILE="${CONFIG_DIR}/${TUNNEL_NAME}.toml"

# Generate TOML config
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

# Create systemd service
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

# Service status check
STATUS="started"
if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    STATUS="failed"
fi

# Save JSON output
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
  "service": "$SERVICE_NAME",
  "role": "$ROLE"
}
EOF

echo -e "${PURPLE}✔ Tunnel '$TUNNEL_NAME' is $STATUS.${NC}"
echo -e "${YELLOW}📁 Config path: $JSON_LOG${NC}"

# Edit notice
echo -e "${INDIGO}[i] To edit config use: nano $CONFIG_FILE then restart with:${NC}"
echo -e "${YELLOW}systemctl restart $SERVICE_NAME${NC}"

# === Integrated Tunnel Manager ===
while true; do
    echo -e "
${PURPLE}Backhaul Tunnel Manager${NC}"
    echo "1) List tunnels"
    echo "2) Show status"
    echo "3) Start tunnel"
    echo "4) Stop tunnel"
    echo "5) Restart tunnel"
    echo "6) Delete tunnel"
    echo "7) Show config JSON"
    echo "8) Edit tunnel config"
    echo "0) Exit"
    read -rp "Choose option: " CHOICE

    case $CHOICE in
        1) ls "$CONFIG_DIR"/*.toml 2>/dev/null | sed 's#.*/##;s/\.toml$//' ;;
        2) read -rp "Enter tunnel name: " TUN; systemctl status "backhaul-$TUN.service" ;;
        3) read -rp "Enter tunnel name: " TUN; systemctl start "backhaul-$TUN.service" ;;
        4) read -rp "Enter tunnel name: " TUN; systemctl stop "backhaul-$TUN.service" ;;
        5) read -rp "Enter tunnel name: " TUN; systemctl restart "backhaul-$TUN.service" ;;
        6) read -rp "Enter tunnel name: " TUN
           systemctl disable --now "backhaul-$TUN.service"
           rm -f "/etc/systemd/system/backhaul-$TUN.service"
           rm -f "$CONFIG_DIR/$TUN.toml"
           echo "Tunnel $TUN deleted." ;;
        7) if [[ -f "$JSON_LOG" ]]; then jq . "$JSON_LOG"; else echo "No JSON config found."; fi ;;
        8) read -rp "Enter tunnel name: " TUN
           nano "$CONFIG_DIR/$TUN.toml"
           systemctl restart "backhaul-$TUN.service" ;;
        0) break ;;
        *) echo "Invalid option." ;;
    esac
done
