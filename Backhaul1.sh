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
