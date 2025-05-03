#!/bin/bash

# =====================[ Global Variables & Colors ]=====================
SCRIPT_VERSION="v2.1.2"
CONFIG_DIR="/root/backhaul-core"
SERVICE_DIR="/etc/systemd/system"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# =====================[ Helper Functions ]=====================
colorize() {
    local color="$1"
    local text="$2"
    echo -e "${!color}${text}${NC}"
}

press_key() {
    read -p "Press any key to continue..." -n1 -s
    echo
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        exit 1
    fi
}
# =====================[ JSON Output Mode ]=====================
if [[ "$1" == "--json" ]]; then
    echo "["
    first=true
    for file in ${CONFIG_DIR}/*.toml; do
        name=$(basename "$file" .toml)
        port=$(grep '^port *= *' "$file" | awk -F '"' '{print $2}')
        type=$(grep '^type *= *' "$file" | awk -F '"' '{print $2}')
        service="backhaul-${name}.service"
        status="inactive"
        systemctl is-active --quiet "$service" && status="running"

        [[ "$first" = true ]] && first=false || echo ","
        echo "  {
    \"name\": \"$name\",
    \"port\": \"$port\",
    \"type\": \"$type\",
    \"path\": \"$file\",
    \"status\": \"$status\"
  }"
    done
    echo "]"
    exit 0
fi

check_binary() {
    local binary=$1
    local install_cmd=$2
    if ! command -v "$binary" &>/dev/null; then
        echo -e "${YELLOW}$binary not found. Installing...${NC}"
        eval "$install_cmd"
    fi
}

# =====================[ System Checks ]=====================
check_dependencies() {
    check_binary unzip "apt-get update && apt-get install -y unzip"
    check_binary jq "apt-get update && apt-get install -y jq"
}

get_server_info() {
    SERVER_IP=$(hostname -I | awk '{print $1}')
    SERVER_COUNTRY=$(curl -sS --max-time 2 "http://ipwhois.app/json/$SERVER_IP" | jq -r '.country')
    SERVER_ISP=$(curl -sS --max-time 2 "http://ipwhois.app/json/$SERVER_IP" | jq -r '.isp')
}

# =====================[ UI ]=====================
display_logo() {
    echo -e "${CYAN}"
    cat << 'EOF'
  ____________________________________________________________________________
      ____                             _     _
 ,   /    )                           /|   /                                 
-----/____/---_--_----__---)__--_/_---/-| -/-----__--_/_-----------__---)__--
 /   /        / /  ) /   ) /   ) /    /  | /    /___) /   | /| /  /   ) /   ) 
_/___/________/_/__/_(___(_/_____(_ __/___|/____(___ _(_ __|/_|/__(___/_/____

             Lightning-fast reverse tunneling solution
EOF
    echo -e "${NC}${GREEN}Script Version: ${YELLOW}${SCRIPT_VERSION}${GREEN}"
    if [[ -f "${CONFIG_DIR}/backhaul_premium" ]]; then
        echo -e "Core Version: ${YELLOW}$(${CONFIG_DIR}/backhaul_premium -v)${GREEN}"
    fi
    echo -e "Telegram Channel: ${YELLOW}@anony_identity${NC}"
}

display_server_info() {
    echo -e "${YELLOW}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}IP Address:${NC} $SERVER_IP"
    echo -e "${CYAN}Location:${NC} $SERVER_COUNTRY"
    echo -e "${CYAN}Datacenter:${NC} $SERVER_ISP"
}

display_menu() {
    clear
    display_logo
    display_server_info
    echo
    colorize GREEN   " 1. Configure a new tunnel [IPv4/IPv6]"
    colorize RED     " 2. Tunnel management menu"
    colorize CYAN    " 3. Check tunnels status"
    echo -e " 5. Update & Install Backhaul Core"
    echo -e " 6. Update & install script"
    echo -e " 7. Remove Backhaul Core"
    echo -e " 0. Exit"
    echo
    echo "-------------------------------"
}

# =====================[ Tunnel Configuration & Management ]=====================
configure_tunnel() {
    echo -e "${GREEN}Creating a new tunnel...${NC}"
    read -p "Enter tunnel name: " tunnel_name
    read -p "Enter tunnel port: " tunnel_port
    read -p "Enter tunnel mode (iran/kharej): " tunnel_mode

    echo -e "\nSelect tunnel type:"
    echo "1) TCP"
    echo "2) UDP"
    echo "3) MUX"
    echo "4) WSS"
    read -p "Tunnel type (1-4): " tunnel_type_num

    case $tunnel_type_num in
        1) tunnel_type="tcp";;
        2) tunnel_type="udp";;
        3) tunnel_type="mux";;
        4) tunnel_type="wss";;
        *) echo -e "${RED}Invalid type.${NC}"; return ;;
    esac

    read -p "Enter domain (or leave blank): " tunnel_domain
    read -p "Enter token (or leave blank for 'none'): " tunnel_token
    tunnel_token=${tunnel_token:-none}
read -p "Enter tunnel direction (direct/reverse): " tunnel_direction

    config_file="${CONFIG_DIR}/${tunnel_mode}${tunnel_port}.toml"

    cat << EOF > "$config_file"
[${tunnel_name}]
name = "$tunnel_name"
port = "$tunnel_port"
mode = "$tunnel_mode"
type = "$tunnel_type"
token = "$tunnel_token"
direction = "$tunnel_direction"
EOF

    if [[ -n "$tunnel_domain" ]]; then
        echo "domain = \"$tunnel_domain\"" >> "$config_file"
    fi

    service_file="${SERVICE_DIR}/backhaul-${tunnel_mode}${tunnel_port}.service"
    cat << SERVICE_EOF > "$service_file"
[Unit]
Description=Backhaul Tunnel: ${tunnel_name}
After=network.target

[Service]
ExecStart=${CONFIG_DIR}/backhaul_premium -c $config_file
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    systemctl daemon-reload
    systemctl enable --now "backhaul-${tunnel_mode}${tunnel_port}.service"
    echo -e "${GREEN}Tunnel created and started. Type: ${YELLOW}${tunnel_type}${NC}"
    press_key
}

tunnel_management() {
    echo -e "${CYAN}Available Tunnels:${NC}"
    index=1
    declare -a tunnels
    for file in ${CONFIG_DIR}/*.toml; do
        name=$(basename "$file")
        echo "$index) $name"
        tunnels+=("$name")
        ((index++))
    done
    echo "0) Cancel"
    read -p "Select a tunnel to manage: " choice
    [[ "$choice" == "0" ]] && return

    selected="${tunnels[$((choice-1))]}"
    echo -e "
${YELLOW}Selected tunnel: $selected${NC}"
    echo "1) Restart"
    echo "2) Stop"
    echo "3) Delete"
    echo "4) Edit"
    echo "5) Change tunnel type"
    echo "6) Disable temporarily"
    echo "7) Enable back"
    echo "8) View tunnel logs"
    echo "9) View tunnel config details"
echo "10) Ping test"
read -p "Choose action: " action

    service_name="backhaul-${selected%.toml}.service"
    file_path="${CONFIG_DIR}/$selected"

    case $action in
        1) systemctl restart "$service_name" && colorize GREEN "Tunnel restarted.";;
        2) systemctl stop "$service_name" && colorize YELLOW "Tunnel stopped.";;
        3)
            systemctl stop "$service_name"
            systemctl disable "$service_name"
            rm -f "$file_path"
            rm -f "$SERVICE_DIR/$service_name"
            systemctl daemon-reload
            colorize RED "Tunnel deleted."
            ;;
        4)
            nano "$file_path"
            systemctl restart "$service_name"
            colorize GREEN "Tunnel edited and restarted."
            ;;
        5)
            current_type=$(grep '^type *= *' "$file_path" | awk -F '"' '{print $2}')
            echo -e "
Current tunnel type: ${YELLOW}$current_type${NC}"
            echo "1) TCP"
            echo "2) UDP"
            echo "3) MUX"
            echo "4) WSS"
            read -p "New tunnel type (1-4): " new_type_num
            case $new_type_num in
                1) new_type="tcp";;
                2) new_type="udp";;
                3) new_type="mux";;
                4) new_type="wss";;
                *) echo -e "${RED}Invalid type.${NC}"; return ;;
            esac
            sed -i "s/^type *= *\".*\"/type = \"$new_type\"/" "$file_path"
            systemctl restart "$service_name"
            colorize GREEN "Tunnel type changed to $new_type and restarted."
            ;;
        6) systemctl disable --now "$service_name"; colorize YELLOW "Tunnel disabled temporarily.";;
        7) systemctl enable --now "$service_name"; colorize GREEN "Tunnel enabled and started.";;
        8) journalctl -u "$service_name" --no-pager | tee "/var/log/backhaul/${service_name}.log";;
        *) echo "Invalid action.";;
        9) cat "$file_path" && press_key;;
    10)
        ping_target=$(grep '^domain *= *' "$file_path" | awk -F '"' '{print $2}')
        [[ -z "$ping_target" ]] && ping_target=$(grep '^ip *= *' "$file_path" | awk -F '"' '{print $2}')
        if [[ -n "$ping_target" ]]; then
            ping -c 4 "$ping_target"
        else
            echo -e "${RED}No target found in config.${NC}"
        fi
        press_key;;
esac
    press_key
}

check_tunnel_status() {
    echo -e "${GREEN}Tunnel service statuses:${NC}"
    for file in ${CONFIG_DIR}/*.toml; do
        name=$(basename "$file")
        service="backhaul-${name%.toml}.service"
        if systemctl is-active --quiet "$service"; then
            colorize GREEN "$service is running"
        else
            colorize RED "$service is not running"
        fi
    done
    press_key
}

update_backhaul_core() {
    echo -e "${GREEN}Downloading latest Backhaul Core...${NC}"
    press_key
}

update_script() {
    echo -e "${GREEN}Updating script from remote...${NC}"
    press_key
}

remove_core() {
    echo -e "${YELLOW}Removing all Backhaul Core data...${NC}"
    rm -rf "$CONFIG_DIR"
    press_key
}

# =====================[ Menu Logic ]=====================
read_option() {
    read -p "Enter your choice [0,1,2,3,5,6,7]: " choice
    case $choice in
        1) configure_tunnel ;;
        2) tunnel_management ;;
        3) check_tunnel_status ;;
        5) update_backhaul_core ;;
        6) update_script ;;
        7) remove_core ;;
        0) exit 0 ;;
        *) echo -e "${RED} Invalid option!${NC}" && sleep 1 ;;
    esac
}

# =====================[ Main Script Start ]=====================
check_root
mkdir -p /var/log/backhaul
check_dependencies
get_server_info

while true; do
    display_menu
    read_option
done

# =====================[ API Mode ]=====================
if [[ "$1" == "--api" ]]; then
    API_PORT=22490
    AUTH_TOKEN="my_secret_token"

    handle_request() {
        REQUEST=$(cat)
        METHOD=$(echo "$REQUEST" | head -n1 | awk '{print $1}')
        PATH=$(echo "$REQUEST" | head -n1 | awk '{print $2}')
        HEADER_AUTH=$(echo "$REQUEST" | grep -i "Authorization: Bearer" | awk '{print $3}')

        if [[ "$HEADER_AUTH" != "$AUTH_TOKEN" ]]; then
            echo -e "HTTP/1.1 403 Forbidden\r\nContent-Type: application/json\r\n\r\n{\"error\":\"Unauthorized\"}"
            return
        fi

        if [[ "$METHOD" == "GET" && "$PATH" =~ ^/status/ ]]; then
            name=$(echo "$PATH" | awk -F '/' '{print $3}')
            file="${CONFIG_DIR}/${name}.toml"
            service="backhaul-${name}.service"
            if [[ -f "$file" ]]; then
                if systemctl is-active --quiet "$service"; then
                    status="running"
                else
                    status="inactive"
                fi
                echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"name\":\"$name\",\"status\":\"$status\"}"
            else
                echo -e "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\n\r\n{\"error\":\"Tunnel not found\"}"
            fi
        elif [[ "$METHOD" == "GET" && "$PATH" == "/list" ]]; then
            echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"
            echo "["
            first=true
            for file in ${CONFIG_DIR}/*.toml; do
                name=$(basename "$file" .toml)
                port=$(grep '^port *= *' "$file" | awk -F '"' '{print $2}')
                type=$(grep '^type *= *' "$file" | awk -F '"' '{print $2}')
                service="backhaul-${name}.service"
                status="inactive"
                systemctl is-active --quiet "$service" && status="running"
                [[ "$first" = true ]] && first=false || echo ","
                echo "  {\"name\":\"$name\",\"port\":\"$port\",\"type\":\"$type\",\"status\":\"$status\"}"
            done
            echo "]"
        elif [[ "$METHOD" == "POST" && "$PATH" =~ ^/delete/ ]]; then
            name=$(echo "$PATH" | awk -F '/' '{print $3}')
            service="backhaul-${name}.service"
            file="${CONFIG_DIR}/${name}.toml"
            if [[ -f "$file" ]]; then
                systemctl stop "$service"
                systemctl disable "$service"
                rm -f "$file"
                rm -f "$SERVICE_DIR/$service"
                systemctl daemon-reload
                echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"deleted\"}"
            else
                echo -e "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\n\r\n{\"error\":\"Tunnel not found\"}"
            fi
        elif [[ "$METHOD" == "POST" && "$PATH" == "/create" ]]; then
            JSON=$(echo "$REQUEST" | awk '/^\r?$/{f=1;next}f')
            name=$(echo "$JSON" | jq -r '.name')
            port=$(echo "$JSON" | jq -r '.port')
            mode=$(echo "$JSON" | jq -r '.mode')
            type=$(echo "$JSON" | jq -r '.type')
            token=$(echo "$JSON" | jq -r '.token // "none"')
            domain=$(echo "$JSON" | jq -r '.domain // empty')
            direction=$(echo "$JSON" | jq -r '.direction // "reverse"')

            config_file="${CONFIG_DIR}/${name}.toml"
            echo "[${name}]" > "$config_file"
            echo "name = \"$name\"" >> "$config_file"
            echo "port = \"$port\"" >> "$config_file"
            echo "mode = \"$mode\"" >> "$config_file"
            echo "type = \"$type\"" >> "$config_file"
            echo "token = \"$token\"" >> "$config_file"
            echo "direction = \"$direction\"" >> "$config_file"
            [[ -n "$domain" ]] && echo "domain = \"$domain\"" >> "$config_file"

            service_file="${SERVICE_DIR}/backhaul-${name}.service"
            cat << SERVICE_EOF > "$service_file"
[Unit]
Description=Backhaul Tunnel: ${name}
After=network.target

[Service]
ExecStart=${CONFIG_DIR}/backhaul_premium -c $config_file
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE_EOF

            systemctl daemon-reload
            systemctl enable --now "backhaul-${name}.service"
            echo -e "HTTP/1.1 201 Created\r\nContent-Type: application/json\r\n\r\n{\"status\":\"created\"}"
        else
            echo -e "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\n\r\n{\"error\":\"Invalid endpoint\"}"
        fi
    }

    echo "Starting Backhaul API on port $API_PORT..."
    while true; do
        nc -l -p "$API_PORT" -q 1 | handle_request
    done
    exit 0
fi
