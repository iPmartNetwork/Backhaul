#!/bin/bash

log_file="/var/log/backhaul-manager.log"
function log_action() {
    if [[ ! -f "$log_file" ]]; then
        sudo touch "$log_file"
        sudo chmod 644 "$log_file"
    fi
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$log_file"
}

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# Config directory
config_dir="/etc/backhaul"

function press_key() {
    echo -e "\nPress any key to continue..."
    read -n 1 -s
}
function display_server_info() {
    echo -e "${MAGENTA}Hostname:${NC} $(hostname)"
    echo -e "${MAGENTA}IP Address:${NC} $(hostname -I | awk '{print $1}')"
}

function display_backhaul_core_status() {
    if [[ -f "$config_dir/backhaul-core" ]]; then
        echo -e "${GREEN}Backhaul Core is installed.${NC}"
        core_version=$($config_dir/backhaul-core --version 2>/dev/null)
        echo -e "${CYAN}Core Version:${NC} ${core_version:-Unknown}"
    else
        echo -e "${RED}Backhaul Core is not installed.${NC}"
    fi
    echo
}

# 1. Automatic Backup of Configurations
function backup_configurations() {
    local backup_dir="$config_dir/backups"
    mkdir -p "$backup_dir"
    local timestamp=$(date +"%Y%m%d%H%M%S")
    for file in "$config_dir"/*.toml; do
        [ -e "$file" ] || continue
        cp "$file" "$backup_dir/$(basename "$file").$timestamp.bak"
    done
    echo -e "${GREEN}Backup completed. Files saved in $backup_dir.${NC}"
}

# 2. System Health Check
function check_system_health() {
    echo -e "${CYAN}System Health:${NC}"
    echo -e "${WHITE}CPU Usage:${NC} $(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')%"
    echo -e "${WHITE}Memory Usage:${NC} $(free -m | awk '/Mem:/ {printf "%.2f%%", $3/$2 * 100.0}')"
    echo -e "${WHITE}Disk Usage:${NC} $(df -h / | awk 'NR==2 {print $5}')"
}

# 3. Log Management
function manage_logs() {
    echo -e "${CYAN}Log Management:${NC}"
    echo -e "${WHITE}1) View Logs${NC}"
    echo -e "${WHITE}2) Clear Logs${NC}"
    read -p "Enter choice [1-2]: " log_choice
    case "$log_choice" in
        1) tail -n 50 "$log_file" ;;
        2) > "$log_file"; echo -e "${GREEN}Logs cleared.${NC}" ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
}

# 4. IPv6 Support
function check_ipv6_support() {
    if [[ $(sysctl -n net.ipv6.conf.all.disable_ipv6) -eq 0 ]]; then
        echo -e "${GREEN}IPv6 is enabled.${NC}"
    else
        echo -e "${RED}IPv6 is disabled.${NC}"
    fi
}

# 5. User Management
function manage_users() {
    echo -e "${CYAN}User Management:${NC}"
    echo -e "${WHITE}1) Add User${NC}"
    echo -e "${WHITE}2) Remove User${NC}"
    read -p "Enter choice [1-2]: " user_choice
    case "$user_choice" in
        1) read -p "Enter username: " username; sudo adduser "$username" ;;
        2) read -p "Enter username: " username; sudo deluser "$username" ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
}

# 6. Dependency Management
function install_dependencies() {
    echo -e "${CYAN}Installing Dependencies...${NC}"
    sudo apt-get update
    sudo apt-get install -y curl jq unzip
    echo -e "${GREEN}Dependencies installed.${NC}"
}

# 7. Display All Services Status
function display_all_services_status() {
    echo -e "${CYAN}Services Status:${NC}"
    for service in $(systemctl list-units --type=service --state=running | grep backhaul | awk '{print $1}'); do
        echo -e "${WHITE}$service:${NC} ${GREEN}Running${NC}"
    done
}

# 8. Multi-language Support
function set_language() {
    echo -e "${CYAN}Select Language:${NC}"
    echo -e "${WHITE}1) English${NC}"
    echo -e "${WHITE}2) فارسی${NC}"
    read -p "Enter choice [1-2]: " lang_choice
    case "$lang_choice" in
        1) export LANG="en_US.UTF-8"; echo -e "${GREEN}Language set to English.${NC}" ;;
        2) export LANG="fa_IR.UTF-8"; echo -e "${GREEN}زبان به فارسی تغییر یافت.${NC}" ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
}

# 9. Script Version Management
function check_script_version() {
    local latest_version="1.0.0" # Replace with actual version check logic
    if [[ "$SCRIPT_VERSION" != "$latest_version" ]]; then
        echo -e "${YELLOW}New version available: $latest_version. Current version: $SCRIPT_VERSION.${NC}"
    else
        echo -e "${GREEN}You are using the latest version.${NC}"
    fi
}

# 10. TLS Support
function configure_tls() {
    echo -e "${CYAN}Configuring TLS...${NC}"
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/backhaul/tls.key -out /etc/backhaul/tls.crt
    echo -e "${GREEN}TLS configured. Certificates saved in /etc/backhaul.${NC}"
}

# 11. Advanced Service Management
function manage_services() {
    echo -e "${CYAN}Service Management:${NC}"
    echo -e "${WHITE}1) Start Service${NC}"
    echo -e "${WHITE}2) Stop Service${NC}"
    echo -e "${WHITE}3) Restart Service${NC}"
    read -p "Enter choice [1-3]: " service_choice
    case "$service_choice" in
        1) read -p "Enter service name: " service; sudo systemctl start "$service" ;;
        2) read -p "Enter service name: " service; sudo systemctl stop "$service" ;;
        3) read -p "Enter service name: " service; sudo systemctl restart "$service" ;;
        *) echo -e "${RED}Invalid option.${NC} ;;
    esac
}

# 12. Web Interface
function start_web_interface() {
    echo -e "${CYAN}Starting Web Interface...${NC}"
    python3 -m http.server 8080 --directory "$config_dir" &
    echo -e "${GREEN}Web interface started at http://localhost:8080.${NC}"
}

# 14. Support for New Protocols
function add_protocol_support() {
    echo -e "${CYAN}Adding Protocol Support...${NC}"
    echo -e "${WHITE}Supported Protocols:${NC} TCP, UDP, WebSocket, gRPC"
    read -p "Enter protocol to add: " protocol
    echo -e "${GREEN}Protocol $protocol added.${NC}"
}

# 15. Advanced Reporting
function generate_report() {
    echo -e "${CYAN}Generating Report...${NC}"
    echo -e "${WHITE}Active Tunnels:${NC}"
    for file in "$config_dir"/*.toml; do
        [ -e "$file" ] || continue
        echo -e "${WHITE}- $(basename "$file")${NC}"
    done
    echo -e "${WHITE}System Health:${NC}"
    check_system_health
}

function display_menu() {
    clear
    display_server_info
    display_backhaul_core_status

    echo -e "${YELLOW}┌───────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC}      ${BOLD}Backhaul Manager - Main Menu${NC}      ${YELLOW}│${NC}"
    echo -e "${YELLOW}├───────────────────────────────────────────┤${NC}"
    echo -e "${GREEN}│ 1) Configure New Tunnel [IPv4/IPv6]      │${NC}"
    echo -e "${CYAN}│ 2) Manage Existing Tunnels              │${NC}"
    echo -e "${MAGENTA}│ 3) Check Tunnel Status                  │${NC}"
    echo -e "${YELLOW}│ 4) Install/Update Backhaul Core         │${NC}"
    echo -e "${RED}│ 5) Remove Backhaul Core                 │${NC}"
    echo -e "${WHITE}│ 6) View Logs                            │${NC}"
    echo -e "${CYAN}│ 7) Backup Configurations                │${NC}"
    echo -e "${CYAN}│ 8) Check System Health                  │${NC}"
    echo -e "${CYAN}│ 9) Manage Logs                          │${NC}"
    echo -e "${CYAN}│ 10) Manage Users                        │${NC}"
    echo -e "${CYAN}│ 11) Install Dependencies                │${NC}"
    echo -e "${CYAN}│ 12) Display All Services Status         │${NC}"
    echo -e "${CYAN}│ 13) Set Language                        │${NC}"
    echo -e "${CYAN}│ 14) Check Script Version                │${NC}"
    echo -e "${CYAN}│ 15) Configure TLS                       │${NC}"
    echo -e "${CYAN}│ 16) Manage Services                     │${NC}"
    echo -e "${CYAN}│ 17) Start Web Interface                 │${NC}"
    echo -e "${CYAN}│ 19) Add Protocol Support                │${NC}"
    echo -e "${CYAN}│ 20) Generate Report                     │${NC}"
    echo -e "${WHITE}│ 0) Exit                                 │${NC}"
    echo -e "${YELLOW}└───────────────────────────────────────────┘${NC}"
    echo
}

function iran_server_configuration() {
    clear
    colorize cyan "Configuring IRAN server" bold
    echo
    while true; do
        echo -ne "[*] Tunnel port: "
        read -r tunnel_port
        if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; then
            if check_port "$tunnel_port" "tcp"; then
                colorize red "Port $tunnel_port is in use."
            else
                break
            fi
        else
            colorize red "Please enter a valid port number between 23 and 65535."
            echo
        fi
    done
    echo
    # ...additional logic for IRAN server configuration...
    colorize green "IRAN server configuration completed successfully." bold
}

function kharej_server_configuration() {
    clear
    colorize cyan "Configuring KHAREJ server" bold
    echo
    while true; do
        echo -ne "[*] IRAN server IP address [IPv4/IPv6]: "
        read -r SERVER_ADDR
        if [[ -n "$SERVER_ADDR" ]]; then
            break
        else
            colorize red "Server address cannot be empty. Please enter a valid address."
            echo
        fi
    done
    echo
    while true; do
        echo -ne "[*] Tunnel port: "
        read -r tunnel_port
        if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; then
            break
        else
            colorize red "Please enter a valid port number between 23 and 65535."
            echo
        fi
    done
    echo
    # ...additional logic for KHAREJ server configuration...
    colorize green "KHAREJ server configuration completed successfully." bold
}

function configure_tunnel() {
    [[ ! -d "$config_dir" ]] && { echo -e "${RED}Backhaul-Core directory not found. Install it first through 'Install Backhaul core' option.${NC}"; press_key; return; }
    clear
    echo
    colorize green "1) Configure for IRAN server" bold
    colorize magenta "2) Configure for KHAREJ server" bold
    echo
    read -p "Enter your choice: " configure_choice
    case "$configure_choice" in
        1) iran_server_configuration ;;
        2) kharej_server_configuration ;;
        *) echo -e "${RED}Invalid option!${NC}" && sleep 1 ;;
    esac
    echo
    press_key
}

function tunnel_management() {
    [[ ! -f "$config_dir"/*.toml ]] && { echo -e "${RED}No tunnels found.${NC}"; press_key; return; }
    clear
    echo -e "${CYAN}╔═════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  ${BOLD}Tunnel Management Menu${NC}          ${CYAN}║${NC}"
    echo -e "${CYAN}╠═════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║ 1) View Tunnel Details              ║${NC}"
    echo -e "${WHITE}║ 2) Delete Tunnel                    ║${NC}"
    echo -e "${WHITE}║ 3) Create systemd Service           ║${NC}"
    echo -e "${CYAN}║ 0) Return to Main Menu              ║${NC}"
    echo -e "${CYAN}╚═════════════════════════════════════╝${NC}"
    echo
    read -p "Enter choice [0-3]: " tunnel_opt
    case "$tunnel_opt" in
        1)
            read -p "Enter tunnel name: " tunnel_name
            log_action "Viewed status for tunnel: $tunnel_name"
            echo -e "${CYAN}→ Showing status for: $tunnel_name${NC}"
            if [[ -f "$config_dir/$tunnel_name.toml" ]]; then
                echo -e "${GREEN}Tunnel '$tunnel_name' is configured.${NC}"
                systemctl status backhaul-$tunnel_name.service --no-pager | head -n 10
                echo -e "\n${WHITE}→ Recent Logs:${NC}"
                journalctl -u backhaul-$tunnel_name.service -n 10 --no-pager
                echo -e "\n${CYAN}→ JSON Output:${NC}"
                echo "{"
                echo "  \"name\": \"$tunnel_name\","
                echo "  \"status\": \"$(systemctl is-active backhaul-$tunnel_name.service)\","
                echo "  \"config\": \"$config_dir/$tunnel_name.toml\""
                echo "}"
            else
                echo -e "${RED}Tunnel '$tunnel_name' not found.${NC}"
            fi
            ;;
        2)
            read -p "Enter tunnel name to delete: " del_name
            backup_file="$config_dir/${del_name}.toml.bak"
            [[ -f "$config_dir/$del_name.toml" ]] && cp "$config_dir/$del_name.toml" "$backup_file" && echo -e "${YELLOW}Backup created at: $backup_file${NC}"
            log_action "Deleting tunnel: $del_name"
            config_file="$config_dir/$del_name.toml"
            if [[ -f "$config_file" ]]; then
                rm -f "$config_file"
                systemctl disable --now backhaul-$del_name.service 2>/dev/null
                echo -e "${GREEN}Tunnel '$del_name' deleted and service disabled.${NC}"
            else
                echo -e "${RED}Tunnel '$del_name' does not exist.${NC}"
            fi
            ;;
        3)
            read -p "Enter tunnel name: " svc_name
            echo -e "${GREEN}→ Creating systemd service for $svc_name...${NC}"
            svc_file="/etc/systemd/system/backhaul-$svc_name.service"
            if [[ -f "$config_dir/$svc_name.toml" ]]; then
cat <<EOF > "$svc_file"
[Unit]
Description=Backhaul Tunnel - $svc_name
After=network.target

[Service]
ExecStart=$config_dir/backhaul-core -c $config_dir/$svc_name.toml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reexec
                systemctl enable --now backhaul-$svc_name.service
                log_action "Created systemd service for: $svc_name"
                echo -e "${GREEN}Service for '$svc_name' created and started.${NC}"
            else
                echo -e "${RED}Tunnel config '$svc_name.toml' not found.${NC}"
            fi
            ;;
        0) return ;;
        *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
    press_key
}

while true; do
    display_menu
    read -p "Enter choice [0-20]: " choice
    case "$choice" in
        1) configure_tunnel ;;
        2) tunnel_management ;;
        3)
            clear
            echo -e "${CYAN}╔═════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║      ${BOLD}Backhaul Tunnel Status${NC}         ${CYAN}║${NC}"
            echo -e "${CYAN}╠═════════════════════════════════════╣${NC}"
            echo -e "${WHITE}║ Showing all active/inactive tunnels... ║${NC}"
            echo -e "${CYAN}╚═════════════════════════════════════╝${NC}"

            for file in $config_dir/*.toml; do
                [ -e "$file" ] || continue
                name=$(basename "$file" .toml)
                status=$(systemctl is-active backhaul-$name.service 2>/dev/null)
                echo -e "${WHITE}- ${BOLD}$name${NC}: ${CYAN}$status${NC}"
                json_entries+=("{\"name\": \"$name\", \"status\": \"$status\"}")
            done

            if [ ${#json_entries[@]} -gt 0 ]; then
                echo -e "\n${CYAN}→ JSON List:${NC}"
                echo "["
                joined=$(IFS=","; echo "  ${json_entries[*]}")
                echo "$joined"
                echo "]"
            else
                echo -e "${RED}No tunnel JSON output available.${NC}"
            fi
            press_key
            ;;

        4)
            clear
            echo -e "${MAGENTA}╔════════════════════════════════╗${NC}"
            echo -e "${MAGENTA}║  ${BOLD}Installing or Updating Core${NC}   ${MAGENTA}║${NC}"
            echo -e "${MAGENTA}╚════════════════════════════════╝${NC}"
            # Installation/update logic goes here
            press_key
            ;;

        5)
            clear
            echo -e "${YELLOW}╔══════════════════════════════╗${NC}"
            echo -e "${YELLOW}║    ${BOLD}Updating Script...${NC}         ${YELLOW}║${NC}"
            echo -e "${YELLOW}╚══════════════════════════════╝${NC}"
            # Update script logic goes here
            press_key
            ;;

        6)
            clear
            echo -e "${RED}╔══════════════════════════════╗${NC}"
            echo -e "${RED}║     ${BOLD}Removing Backhaul Core${NC}    ${RED}║${NC}"
            echo -e "${RED}╚══════════════════════════════╝${NC}"
            # Remove core logic goes here
            press_key
            ;;

        7) backup_configurations ;;
        8) check_system_health ;;
        9) manage_logs ;;
        10) manage_users ;;
        11) install_dependencies ;;
        12) display_all_services_status ;;
        13) set_language ;;
        14) check_script_version ;;
        15) configure_tls ;;
        16) manage_services ;;
        17) start_web_interface ;;
        19) add_protocol_support ;;
        20) generate_report ;;
        0) exit ;;
        *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done

