#!/bin/bash

# === Backhaul Full Suite Installer and Manager ===

# --- API Installer Section ---
#!/bin/bash

# === Unified Backhaul Installer ===

# --- install_api.sh section ---
#!/bin/bash

set -e

# Colors
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# Paths
API_DIR="/opt/backhaul"
API_FILE="${API_DIR}/backhaul_api.py"
SERVICE_FILE="/etc/systemd/system/backhaul-api.service"
LOG_FILE="/var/log/backhaul_api.log"

function install_api() {
    echo -e "${YELLOW}[*] Installing Backhaul API...${NC}"

    read -rp "🔐 Enter API Token (default: mysecuretoken): " api_token
    api_token=${api_token:-mysecuretoken}

    mkdir -p "$API_DIR"

    echo -e "${YELLOW}[*] Installing Python dependencies...${NC}"
    pip3 install flask flask-cors --quiet

    # Create backhaul_api.py
    cat > "$API_FILE" <<EOF
from flask import Flask, jsonify, request
from flask_cors import CORS
import os, json, subprocess, logging
from functools import wraps

API_TOKEN = os.environ.get("BACKHAUL_API_TOKEN", "mysecuretoken")
LOG_FILE = "/var/log/backhaul_api.log"
JSON_DIR = "/json/backhaul"

logging.basicConfig(filename=LOG_FILE, level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

app = Flask(__name__)
CORS(app)

def require_token(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return jsonify({"error": "Missing or invalid Authorization header"}), 401
        token = auth.split(" ")[1]
        if token != API_TOKEN:
            return jsonify({"error": "Invalid API token"}), 403
        return f(*args, **kwargs)
    return wrapper

@app.route("/status", methods=["GET"])
@require_token
def list_tunnels():
    tunnels = []
    if os.path.isdir(JSON_DIR):
        for file in os.listdir(JSON_DIR):
            if file.endswith(".json"):
                with open(os.path.join(JSON_DIR, file)) as f:
                    tunnels.append(json.load(f))
    return jsonify(tunnels)

@app.route("/status/<name>", methods=["GET"])
@require_token
def get_tunnel(name):
    path = os.path.join(JSON_DIR, f"{name}.json")
    if os.path.isfile(path):
        with open(path) as f:
            return jsonify(json.load(f))
    return jsonify({"error": "Tunnel not found"}), 404

@app.route("/delete", methods=["POST"])
@require_token
def delete_tunnel():
    data = request.json
    name = data.get("name")
    if not name:
        return jsonify({"error": "Missing 'name'"}), 400
    subprocess.call(["systemctl", "stop", f"backhaul-{name}.service"])
    subprocess.call(["systemctl", "disable", f"backhaul-{name}.service"])
    subprocess.call(["rm", "-f", f"/etc/systemd/system/backhaul-{name}.service"])
    subprocess.call(["rm", "-f", f"/etc/backhaul/{name}.toml"])
    subprocess.call(["rm", "-f", f"/json/backhaul/{name}.json"])
    subprocess.call(["systemctl", "daemon-reload"])
    logging.info(f"[DELETE] {name} by API")
    return jsonify({"message": f"{name} deleted"})

@app.route("/create", methods=["POST"])
@require_token
def create_stub():
    return jsonify({"message": "POST /create API logic implemented separately"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8686)
EOF

    # Create systemd service
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Backhaul API Service
After=network.target

[Service]
Type=simple
Environment=BACKHAUL_API_TOKEN=${api_token}
ExecStart=/usr/bin/python3 ${API_FILE}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl enable backhaul-api
    systemctl restart backhaul-api

    echo -e "${GREEN}[✔] API successfully installed and started.${NC}"
    echo -e "${GREEN}📡 URL: http://localhost:8686/status (with Authorization: Bearer ${api_token})${NC}"
}

function remove_api() {
    echo -e "${RED}[!] Removing Backhaul API...${NC}"

    systemctl stop backhaul-api >/dev/null 2>&1 || true
    systemctl disable backhaul-api >/dev/null 2>&1 || true
    rm -f "$SERVICE_FILE"
    rm -f "$API_FILE"
    rm -f "$LOG_FILE"
    systemctl daemon-reload

    echo -e "${GREEN}✅ API and service removed.${NC}"
}

# Menu
clear
echo -e "${YELLOW}┌────────────────────────────────────┐"
echo -e "│  📦 Backhaul API Installer         │"
echo -e "└────────────────────────────────────┘${NC}"
echo
echo "1) Install API"
echo "2) Uninstall API"
echo "0) Exit"
echo
read -rp "Your choice: " choice

case $choice in
    1) install_api ;;
    2) remove_api ;;
    0) exit 0 ;;
    *) echo -e "${RED}Invalid choice!${NC}" ;;
esac


# --- backhaul_api.py section (inline) ---
cat > /opt/backhaul/backhaul_api.py << 'EOF'
# This is the API server script.

EOF


# --- Tunnel Manager Section ---
#!/bin/bash

# Backhaul Tunnel Manager Script (Core Installer + Tunnel Creator)
# Version: 2.1.0

config_dir="/etc/backhaul"
service_dir="/etc/systemd/system"
core_url="https://github.com/Musixal/Backhaul/releases/download/v0.6.5"
arch=$(uname -m)

# Detect architecture
detect_arch() {
  case "$arch" in
    x86_64) echo "amd64" ;;
    aarch64) echo "arm64" ;;
    armv7l) echo "armv7" ;;
    *) echo "unsupported" ;;
  esac
}

# Color helpers
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
colorize() { echo -e "${!1}$2${NC}"; }

press_key() { read -rp $'Press any key to continue...\n' -n1; }

# Install Backhaul Core
install_core() {
  mkdir -p "$config_dir"
  arch_id=$(detect_arch)
  if [[ "$arch_id" == "unsupported" ]]; then
    colorize RED "[ERROR] Unsupported architecture: $arch"
    return 1
  fi
  url="${core_url}/backhaul_premium-${arch_id}"
  curl -L "$url" -o "${config_dir}/backhaul_premium"
  chmod +x "${config_dir}/backhaul_premium"
  colorize GREEN "[OK] Backhaul Core installed at ${config_dir}/backhaul_premium"
}

# Remove Backhaul Core
remove_core() {
  rm -rf "$config_dir"
  colorize GREEN "[OK] Backhaul Core removed."
}

# Tunnel Configuration (simplified)
configure_tunnel() {
  [[ ! -f "$config_dir/backhaul_premium" ]] && echo -e "${RED}Core not installed. Run Install first.${NC}" && return 1

  read -rp "Enter tunnel type (iran/kharej): " type
  read -rp "Enter port: " port
  read -rp "Enter transport (tcp/udp/ws): " transport
  read -rp "Enter token: " token

  cat > "$config_dir/${type}${port}.toml" <<EOF
[${type}]
bind_addr = ":${port}"
transport = "${transport}"
token = "${token}"
keepalive_period = 60
log_level = "info"
EOF

  cat > "$service_dir/backhaul-${type}${port}.service" <<EOF
[Unit]
Description=Backhaul ${type} Tunnel on Port ${port}
After=network.target

[Service]
ExecStart=${config_dir}/backhaul_premium -c ${config_dir}/${type}${port}.toml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now "backhaul-${type}${port}.service"
  colorize GREEN "Tunnel ${type}${port} started and enabled."
}

# Main Menu
main_menu() {
  while true; do
    clear
    echo "========= Backhaul Tunnel Manager ========="
    echo "1) Install Backhaul Core"
    echo "2) Configure and Start Tunnel"
    echo "3) Remove Backhaul Core"
    echo "0) Exit"
    echo "=========================================="
    read -rp "Choose an option: " opt
    case "$opt" in
      1) install_core ;;
      2) configure_tunnel ;;
      3) remove_core ;;
      0) break ;;
      *) colorize RED "Invalid option" ;;
    esac
    press_key
  done
}

main_menu
