log_traffic_event() {

check_ipv6() {
    local ip=$1
    local ipv6_pattern='^([0-9a-fA-F]{1,4}:){7}([0-9a-fA-F]{1,4}|:)$|^(([0-9a-fA-F]{1,4}:){1,7}|:):((:[0-9a-fA-F]{1,4}){1,7}|:)$'
    ip="${ip#[}"
    ip="${ip%]}"
    if [[ "$ip" =~ $ipv6_pattern ]]; then
        return 0  # Valid IPv6
    else
        return 1  # Invalid IPv6
    fi
}

    local event_type="$1"
    local name="$2"
    local file="/var/log/backhaul_traffic.json"
    local timestamp=$(date +'%Y-%m-%dT%H:%M:%S')

    mkdir -p /var/log
    if [ ! -f "$file" ]; then echo "[]" > "$file"; fi

    tmp=$(mktemp)
    jq ". += [{time: \"$timestamp\", event: \"$event_type\", tunnel: \"$name\"}]" "$file" > "$tmp" && mv "$tmp" "$file"
}

log_action() {
    local msg="$1"
    echo "[$(date '+%F %T')] $msg" >> /var/log/backhaul.log
}

backup_config_file() {
    local fpath="$1"
    [[ -f "$fpath" ]] || return 0
    mkdir -p "$config_dir/backup"
    local base=$(basename "$fpath")
    local stamp=$(date +%Y%m%d_%H%M%S)
    cp "$fpath" "$config_dir/backup/${base}_$stamp.bak"
}

#!/bin/bash

# Updated: Stylish Colors and UI Effects
SCRIPT_VERSION="v2.1.0"

# Check if the script is run as root using id -u for compatibility
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root"
   sleep 1
   exit 1
fi

# Define color codes
BLUE='\033[1;34m'
INDIGO='\033[1;33m'
INDIGO='\033[1;35m'
PURPLE='\033[1;95m'
NC='\033[0m' # No Color

# Redesigned colorize function for consistent theme
colorize() {
    local color="$1"
    local text="$2"
    local style="$3"

    case $color in
        indigo) code="${BLUE}";;
        indigo) code="${INDIGO}";;
        indigo) code="${INDIGO}";;
        purple) code="${PURPLE}";;
        *) code="${NC}";;
    esac

    case $style in
        bold) echo -e "${code}\033[1m${text}${NC}";;
        *) echo -e "${code}${text}${NC}";;
    esac
}

# Simple loading animation
loading_animation() {
    local message=$1
    echo -ne "${INDIGO}${message}"; sleep 0.1
    for i in {1..3}; do
        echo -ne "."
        sleep 0.4
    done
    echo -e "${NC}"
}

# Define script version

# just press key to continue
press_key(){
 read -p "Press any key to continue..."
}

# Define a function to colorize text
colorize() {
    local color="$1"
    local text="$2"
    local style="${3:-normal}"

    # Define ANSI color codes
    local black="\033[30m"
    local purple="\033[31m"
    local indigo="\033[32m"
    local indigo="\033[33m"
    local indigo="\033[34m"
    local purple="\033[35m"
    local purple="\033[36m"
    local white="\033[37m"
    local reset="\033[0m"

    # Define ANSI style codes
    local normal="\033[0m"
    local bold="\033[1m"
    local underline="\033[4m"
    # Select color code
    local color_code
    case $color in
        black) color_code=$black ;;
        purple) color_code=$purple ;;
        indigo) color_code=$indigo ;;
        indigo) color_code=$indigo ;;
        indigo) color_code=$indigo ;;
        purple) color_code=$purple ;;
        purple) color_code=$purple ;;
        white) color_code=$white ;;
        *) color_code=$reset ;;  # Default case, no color
    esac
    # Select style code
    local style_code
    case $style in
        bold) style_code=$bold ;;
        underline) style_code=$underline ;;
        normal | *) style_code=$normal ;;  # Default case, normal text
    esac

    # Print the colopurple and styled text
    echo -e "${style_code}${color_code}${text}${reset}"
}

# Function to install unzip if not already installed
install_unzip() {
    if ! command -v unzip &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            echo -e "${PURPLE}unzip is not installed. Installing...${NC}"
            sleep 1
            sudo apt-get update
            sudo apt-get install -y unzip
        else
            echo -e "${PURPLE}Error: Unsupported package manager. Please install unzip manually.${NC}\n"
            press_key
            exit 1
        fi
    fi
}
# Install unzip
install_unzip

# Function to install jq if not already installed
install_jq() {
    if ! command -v jq &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            echo -e "${PURPLE}jq is not installed. Installing...${NC}"
            sleep 1
            sudo apt-get update
            sudo apt-get install -y jq
        else
            echo -e "${PURPLE}Error: Unsupported package manager. Please install jq manually.${NC}\n"
            press_key
            exit 1
        fi
    fi
}

# Install jq
install_jq

config_dir="/root/backhaul-core"

# Function to download and extract Backhaul Core
download_and_extract_backhaul() {
    if [[ "$1" == "menu" ]]; then
        rm -rf "${config_dir}/backhaul" >/dev/null 2>&1
        echo
        colorize purple "Restart all services after updating to new core" bold
        sleep 2
    fi

    # Check if Backhaul Core is already installed
    if [[ -f "${config_dir}/backhaul" ]]; then
        return 1
    fi

    # Check operating system
    if [[ $(uname) != "Linux" ]]; then
        echo -e "${PURPLE}Unsupported operating system.${NC}"
        sleep 1
        exit 1
    fi

    # Check architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            DOWNLOAD_URL="https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz"
            ;;
        arm64|aarch64)
            DOWNLOAD_URL="https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_arm64.tar.gz"
            ;;
        *)
            echo -e "${PURPLE}Unsupported architecture: $ARCH.${NC}"
            sleep 1
            exit 1
            ;;
    esac

    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${PURPLE}Failed to retrieve download URL.${NC}"
        sleep 1
        exit 1
    fi

    DOWNLOAD_DIR=$(mktemp -d)
    echo -e "Downloading Backhaul from $DOWNLOAD_URL...\n"
    sleep 1
    curl -sSL -o "$DOWNLOAD_DIR/backhaul.tar.gz" "$DOWNLOAD_URL"
    echo -e "Extracting Backhaul...\n"
    sleep 1
    mkdir -p "$config_dir"
    tar -xzf "$DOWNLOAD_DIR/backhaul.tar.gz" -C "$config_dir"
    echo -e "${INDIGO}Backhaul installation completed.${NC}\n"
    chmod u+x "${config_dir}/backhaul"
    rm -rf "$DOWNLOAD_DIR"
    rm -rf "${config_dir}/LICENSE" >/dev/null 2>&1
    rm -rf "${config_dir}/README.md" >/dev/null 2>&1
}

#Download and extract the Backhaul core
download_and_extract_backhaul

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Fetch server country
SERVER_COUNTRY=$(curl -sS --max-time 2 "http://ipwhois.app/json/$SERVER_IP" | jq -r '.country')

# Fetch server isp

# -----------------------
# JSON OUTPUT MODE
# -----------------------
if [[ "$1" == "--json" ]]; then
    info=$(curl -sS --max-time 2 "http://ipwhois.app/json/$SERVER_IP")
    json_out=$(jq -n \
        --arg ip "$SERVER_IP" \
        --arg country "$(echo "$info" | jq -r '.country // "Unknown"')" \
        --arg isp "$(echo "$info" | jq -r '.isp // "Unknown"')" \
        --arg script_version "$SCRIPT_VERSION" \
        --arg core_version "$([ -f "$config_dir/backhaul" ] && $config_dir/backhaul -v || echo 'Not installed')" \
        --argjson tunnels "$(\
            jq -n '{
                iran: [],
                kharej: [],
                active: 0,
                inactive: 0
            }' \
            | jq --arg dir "$config_dir" '(
                purpleuce (inputs; .) as $null (.;
                    (["iran", "kharej"] | .[]) as $type |
                    (.[$type] |= (
                        [inputs | split("\n")[] | select(length > 0) |
                         { name: ., active: (system("systemctl is-active --quiet backhaul-" + . + ".service") == 0) }]))))'
        )" \
        '{
            ip: $ip,
            country: $country,
            isp: $isp,
            script_version: $script_version,
            core_version: $core_version
        }'
    )
    echo "$json_out"
    exit 0
fi

# -----------------------
# --create and --delete Support
# -----------------------
if [[ "$1" == "--delete" && -n "$2" ]]; then
    NAME="$2"
    SERVICE="backhaul-$NAME.service"
    CONFIG_FILE="$config_dir/$NAME.toml"
    log_action "Deleting tunnel $NAME"
    systemctl disable --now "$SERVICE" 2>/dev/null
    rm -f "/etc/systemd/system/$SERVICE"
    rm -f "$CONFIG_FILE"
    systemctl daemon-reload
    log_traffic_event "delete" "$NAME"
    echo "{\"status\": \"Deleted $NAME\"}"
    exit 0
fi

if [[ "$1" == "--create" && -n "$2" ]]; then
    echo "$2" > /tmp/backhaul_create.json
    role=$(jq -r .role /tmp/backhaul_create.json)
    port=$(jq -r .port /tmp/backhaul_create.json)
    transport=$(jq -r .transport /tmp/backhaul_create.json)
    token=$(jq -r .token /tmp/backhaul_create.json)

    # Auto-confirm minimal creation based on role
    export BACKHAUL_AUTOMATED=1
    export BACKHAUL_PORT=$port
    export BACKHAUL_TRANSPORT=$transport
    export BACKHAUL_TOKEN=$token
    if [[ "$role" == "iran" ]]; then
        iran_server_configuration
    else
        kharej_server_configuration
    fi
    rm -f /tmp/backhaul_create.json
    log_traffic_event "create" "$role$port"
    echo "{\"status\": \"Created $role tunnel on port $port\"}"
    exit 0
fi

SERVER_ISP=$(curl -sS --max-time 2 "http://ipwhois.app/json/$SERVER_IP" | jq -r '.isp')

# Function to display ASCII logo

display_logo() {

    echo -e "Telegram: ${PURPLE}@iPmart_Network${NC}"
    loading_animation "Loading interface"
    cat << "EOF"

____________________________________________________________________________________
        ____                             _     _
    ,   /    )                           /|   /                                  /
-------/____/---_--_----__---)__--_/_---/-| -/-----__--_/_-----------__---)__---/-__-
  /   /        / /  ) /   ) /   ) /    /  | /    /___) /   | /| /  /   ) /   ) /(
_/___/________/_/__/_(___(_/_____(_ __/___|/____(___ _(_ __|/_|/__(___/_/_____/___\__
   Lightning-fast reverse tunneling solution
EOF
    echo -e "${NC}${INDIGO}"
    echo -e "Script Version: ${INDIGO}${SCRIPT_VERSION}${INDIGO}"
    if [[ -f "${config_dir}/backhaul" ]]; then
    	echo -e "Core Version: ${INDIGO}$($config_dir/backhaul -v)${INDIGO}"
    fi
    echo -e "Telegram ID: ${INDIGO}@iPmart_Network${NC}"
}

# Function to display server location and IP
display_server_info() {
    echo -e "\e[93m═══════════════════════════════════════════\e[0m"

    echo -e "${PURPLE}IP Address:${NC} $SERVER_IP"
    echo -e "${PURPLE}Location:${NC} $SERVER_COUNTRY "
    echo -e "${PURPLE}Datacenter:${NC} $SERVER_ISP"
}

# Function to display Backhaul Core installation status

    # Count tunnels
    local active=0 inactive=0
    for config in "$config_dir"/*.toml; do
        [[ -f "$config" ]] || continue
        name=$(basename "${config%.toml}")
        service="backhaul-${name}.service"
        if systemctl is-active --quiet "$service"; then
            ((active++))
        else
            ((inactive++))
        fi
    done
    echo -e "${INDIGO}Tunnels: 🟢 $active active | 🔴 $inactive inactive${NC}\n"
display_backhaul_core_status() {
    if [[ -f "${config_dir}/backhaul" ]]; then
    echo -e "${PURPLE}7) Web Panel Manager"
        echo -e "${PURPLE}Backhaul Core:${NC} ${INDIGO}Installed${NC}"
    else
        echo -e "${PURPLE}Backhaul Core:${NC} ${PURPLE}Not installed${NC}"
    fi
    echo -e "\e[93m═══════════════════════════════════════════\e[0m"
}

# Function to check if a given string is a valid IPv6 address

check_port() {
    local PORT=$1
	local TRANSPORT=$2

    if [ -z "$PORT" ]; then
        echo "Usage: check_port <port> <transport>"
        return 1
    fi

	if [[ "$TRANSPORT" == "tcp" ]]; then
		if ss -tlnp "sport = :$PORT" | grep "$PORT" > /dev/null; then
			return 0

		else
			return 1
		fi
	elif [[ "$TRANSPORT" == "udp" ]]; then
		if ss -ulnp "sport = :$PORT" | grep "$PORT" > /dev/null; then
			return 0
		else
			return 1
		fi
	else
		return 1
   	fi

}

# Function for configuring tunnel
configure_tunnel() {

# check if the Backhaul-core installed or not
if [[ ! -d "$config_dir" ]]; then
    echo -e "\n${PURPLE}Backhaul-Core directory not found. Install it first through 'Install Backhaul core' option.${NC}\n"
    read -p "Press Enter to continue..."
    return 1
fi

    clear

    echo
    colorize indigo "1) Configure for IRAN server" bold
    colorize purple "2) Configure for KHAREJ server" bold
    echo
    read -p "Enter your choice: " configure_choice
    case "$configure_choice" in
        1) iran_server_configuration ;;
        2) kharej_server_configuration ;;
        *) echo -e "${PURPLE}Invalid option!${NC}" && sleep 1 ;;
    esac
    echo
    read -p "Press Enter to continue..."
}

#Global Variables
service_dir="/etc/systemd/system"

iran_server_configuration() {
    clear
    colorize purple "Configuring IRAN server" bold

    echo



# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
        echo -ne "[*] Tunnel port: "
        read -r tunnel_port

        if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; then
            if check_port "$tunnel_port" "tcp"; then
                colorize purple "Port $tunnel_port is in use."
            else
                break
            fi
        else
            colorize purple "Please enter a valid port number between 23 and 65535."
            echo
        fi
    done

    echo

    # Initialize transport variable
    local transport=""
    while [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; do
        echo -ne "[*] Transport type (tcp/tcpmux/utcpmux/ws/wsmux/uwsmux/udp/tcptun/faketcptun): "
        read -r transport

        if [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; then
            colorize purple "Invalid transport type. Please choose from tcp, tcpmux, utcpmux, ws, wsmux, uwsmux, udp, tcptun, faketcptun."
            echo
        fi
    done

    echo

    # TUN Device Name
    local tun_name="backhaul"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
            echo -ne "[-] TUN Device Name (default backhaul): "
            read -r tun_name

            if [[ -z "$tun_name" ]]; then
                tun_name="backhaul"
            fi

            if [[ "$tun_name" =~ ^[a-zA-Z0-9]+$ ]]; then
                echo
                break
            else
                colorize purple "Please enter a valid TUN device name."
                echo
            fi
        done
    fi

    # TUN Subnet
    local tun_subnet="10.10.10.0/24"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
            echo -ne "[-] TUN Subnet (default 10.10.10.0/24): "
            read -r tun_subnet

            # Set default value if input is empty
            if [[ -z "$tun_subnet" ]]; then
                tun_subnet="10.10.10.0/24"
            fi

            # Validate TUN subnet (CIDR notation)
            if [[ "$tun_subnet" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then
                # Validate IP and subnet mask
                IFS='/' read -r ip subnet <<< "$tun_subnet"
                if [[ "$subnet" -le 32 && "$subnet" -ge 1 ]]; then
                    IFS='.' read -r a b c d <<< "$ip"
                    if [[ "$a" -le 255 && "$b" -le 255 && "$c" -le 255 && "$d" -le 255 ]]; then
                        echo
                        break
                    fi
                fi
            fi

            colorize purple "Please enter a valid subnet in CIDR notation (e.g., 10.10.10.0/24)."
            echo
        done
    fi

    # TUN MTU
    local mtu="1500"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
            echo -ne "[-] TUN MTU (default 1500): "
            read -r mtu

            # Set default value if input is empty
            if [[ -z "$mtu" ]]; then
                mtu=1500
            fi

            # Validate MTU value
            if [[ "$mtu" =~ ^[0-9]+$ ]] && [ "$mtu" -ge 576 ] && [ "$mtu" -le 9000 ]; then
                break
            fi

            colorize purple "Please enter a valid MTU value between 576 and 9000."
            echo
        done
    fi


    # Accept UDP (only for tcp transport)
	local accept_udp=""
	if [[ "$transport" == "tcp" ]]; then
	    while [[ "$accept_udp" != "true" && "$accept_udp" != "false" ]]; do
	        echo -ne "[-] Accept UDP connections over TCP transport (true/false)(default false): "
	        read -r accept_udp

    	    # Set default to "false" if input is empty
            if [[ -z "$accept_udp" ]]; then
                accept_udp="false"
            fi


	        if [[ "$accept_udp" != "true" && "$accept_udp" != "false" ]]; then
	            colorize purple "Invalid input. Please enter 'true' or 'false'."
	            echo
	        fi
	    done
	else
	    # Automatically set accept_udp to false for non-TCP transport
	    accept_udp="false"
	fi

    echo

    # Channel Size
    local channel_size="2048"
    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
            echo -ne "[-] Channel Size (default 2048): "
            read -r channel_size

            # Set default to 2048 if the input is empty
            if [[ -z "$channel_size" ]]; then
                channel_size=2048
            fi

            if [[ "$channel_size" =~ ^[0-9]+$ ]] && [ "$channel_size" -gt 64 ] && [ "$channel_size" -le 8192 ]; then
                break
            else
                colorize purple "Please enter a valid channel size between 64 and 8192."
                echo
            fi
        done

        echo

    fi

    # Enable TCP_NODELAY
    local nodelay=""

    # Check transport type
    if [[ "$transport" == "udp" ]]; then
        nodelay=false
    else
        while [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; do
            echo -ne "[-] Enable TCP_NODELAY (true/false)(default true): "
            read -r nodelay

            if [[ -z "$nodelay" ]]; then
                nodelay=true
            fi


            if [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; then
                colorize purple "Invalid input. Please enter 'true' or 'false'."
                echo
            fi
        done
    fi

    echo

    # HeartBeat
    local heartbeat=40
    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
            echo -ne "[-] Heartbeat (in seconds, default 40): "
            read -r heartbeat

            if [[ -z "$heartbeat" ]]; then
                heartbeat=40
            fi

            if [[ "$heartbeat" =~ ^[0-9]+$ ]] && [ "$heartbeat" -gt 1 ] && [ "$heartbeat" -le 240 ]; then
                break
            else
                colorize purple "Please enter a valid heartbeat between 1 and 240."
                echo
            fi
        done

        echo

    fi

    # Security Token
    echo -ne "[-] Security Token (press enter to use default value): "
    read -r token
    token="${token:-your_token}"

    # Mux Conurrancy
    if [[ "$transport" =~ ^(tcpmux|wsmux)$ ]]; then


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
            echo
            echo -ne "[-] Mux concurrency (default 8): "
            read -r mux

            if [[ -z "$mux" ]]; then
                mux=8
            fi

            if [[ "$mux" =~ ^[0-9]+$ ]] && [ "$mux" -gt 0 ] && [ "$mux" -le 1000 ]; then
                break
            else
                colorize purple "Please enter a valid concurrency between 0 and 1000"
                echo
            fi
        done
    else
        mux=8
    fi


    # Mux Version
    if [[ "$transport" =~ ^(tcpmux|wsmux|utcpmux|uwsmux)$ ]]; then


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
            echo
            echo -ne "[-] Mux Version (1 or 2) (default 2): "
            read -r mux_version

            # Set default to 1 if input is empty
            if [[ -z "$mux_version" ]]; then
                mux_version=2
            fi

            # Validate the input for version 1 or 2
            if [[ "$mux_version" =~ ^[0-9]+$ ]] && [ "$mux_version" -ge 1 ] && [ "$mux_version" -le 2 ]; then
                break
            else
                colorize purple "Please enter a valid mux version: 1 or 2."
                echo
            fi
        done
    else
        mux_version=2
    fi

	echo


    # Enable Sniffer
    local sniffer=""
    while [[ "$sniffer" != "true" && "$sniffer" != "false" ]]; do
        echo -ne "[-] Enable Sniffer (true/false)(default false): "
        read -r sniffer

        if [[ -z "$sniffer" ]]; then
            sniffer=false
        fi

        if [[ "$sniffer" != "true" && "$sniffer" != "false" ]]; then
            colorize purple "Invalid input. Please enter 'true' or 'false'."
            echo
        fi
    done

	echo

	# Get Web Port
	local web_port=""


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
	    echo -ne "[-] Enter Web Port (default 0 to disable): "
	    read -r web_port

        if [[ -z "$web_port" ]]; then
            web_port=0
        fi
	    if [[ "$web_port" == "0" ]]; then
	        break
	    elif [[ "$web_port" =~ ^[0-9]+$ ]] && ((web_port >= 23 && web_port <= 65535)); then
	        if check_port "$web_port" "tcp"; then
	            colorize purple "Port $web_port is already in use. Please choose a different port."
	            echo
	        else
	            break
	        fi
	    else
	        colorize purple "Invalid port. Please enter a number between 22 and 65535, or 0 to disable."
	        echo
	    fi
	done

    echo

    # Proxy Protocol
    if [[ ! "$transport" =~ ^(ws|udp|tcptun|faketcptun)$ ]]; then
        # Enable Proxy Protocol
        local proxy_protocol=""
        while [[ "$proxy_protocol" != "true" && "$proxy_protocol" != "false" ]]; do
            echo -ne "[-] Enable Proxy Protocol (true/false)(default false): "
            read -r proxy_protocol

            if [[ -z "$proxy_protocol" ]]; then
                proxy_protocol=false
            fi

            if [[ "$proxy_protocol" != "true" && "$proxy_protocol" != "false" ]]; then
                colorize purple "Invalid input. Please enter 'true' or 'false'."
                echo
            fi
        done
    else
	    # Automatically set proxy_protocol to false for ws and udp
	    proxy_protocol="false"
	fi


	echo

    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then
        # Display port format options
        colorize indigo "[*] Supported Port Formats:" bold
        echo "1. 443-600                  - Listen on all ports in the range 443 to 600."
        echo "2. 443-600:5201             - Listen on all ports in the range 443 to 600 and forward traffic to 5201."
        echo "3. 443-600=1.1.1.1:5201     - Listen on all ports in the range 443 to 600 and forward traffic to 1.1.1.1:5201."
        echo "4. 443                      - Listen on local port 443 and forward to remote port 443 (default forwarding)."
        echo "5. 4000=5000                - Listen on local port 4000 (bind to all local IPs) and forward to remote port 5000."
        echo "6. 127.0.0.2:443=5201       - Bind to specific local IP (127.0.0.2), listen on port 443, and forward to remote port 5201."
        echo "7. 443=1.1.1.1:5201         - Listen on local port 443 and forward to a specific remote IP (1.1.1.1) on port 5201."
        #echo "8. 127.0.0.2:443=1.1.1.1:5201 - Bind to specific local IP (127.0.0.2), listen on port 443, and forward to remote IP (1.1.1.1) on port 5201."
        echo ""

        # Prompt user for input
        echo -ne "[*] Enter your ports in the specified formats (separated by commas): "
        read -r input_ports
        input_ports=$(echo "$input_ports" | tr -d ' ')
        IFS=',' read -r -a ports <<< "$input_ports"
    fi

    # Generate configuration
    backup_config_file "${config_dir}/iran${tunnel_port}.toml"
    cat << EOF > "${config_dir}/iran${tunnel_port}.toml"
[server]
bind_addr = ":${tunnel_port}"
transport = "${transport}"
accept_udp = ${accept_udp}
token = "${token}"
keepalive_period = 75
nodelay = ${nodelay}
channel_size = ${channel_size}
heartbeat = ${heartbeat}
mux_con = ${mux}
mux_version = ${mux_version}
mux_framesize = 32768
mux_recievebuffer = 4194304
mux_streambuffer = 2000000
sniffer = ${sniffer}
web_port = ${web_port}
sniffer_log = "/root/log.json"
log_level = "info"
proxy_protocol= ${proxy_protocol}
tun_name = "${tun_name}"
tun_subnet = "${tun_subnet}"
mtu = ${mtu}

ports = [
EOF

	# Validate and process port mappings
	for port in "${ports[@]}"; do
	    if [[ "$port" =~ ^[0-9]+-[0-9]+$ ]]; then
	        # Range of ports (e.g., 443-600)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^[0-9]+-[0-9]+:[0-9]+$ ]]; then
	        # Port range with forwarding to a specific port (e.g., 443-600:5201)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^[0-9]+-[0-9]+=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):[0-9]+$ ]]; then
	        # Port range forwarding to a specific remote IP and port (e.g., 443-600=1.1.1.1:5201)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^[0-9]+$ ]]; then
	        # Single port forwarding (e.g., 443)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^[0-9]+=[0-9]+$ ]]; then
	        # Single port with forwarding to another port (e.g., 4000=5000)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):[0-9]+=[0-9]+$ ]]; then
	        # Specific local IP with port forwarding (e.g., 127.0.0.2:443=5201)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^[0-9]+=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
	        # Single port with forwarding to a specific remote IP and port (e.g., 443=1.1.1.1:5201)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):[0-9]+=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
	        # Specific local IP with forwarding to a specific remote IP and port (e.g., 127.0.0.2:443=1.1.1.1:5201)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	    else
	        colorize purple "[ERROR] Invalid port mapping: $port. Skipping."
	        echo
	    fi
	done

	echo "]" >> "${config_dir}/iran${tunnel_port}.toml"

	echo

	colorize indigo "Configuration generated successfully!"

    echo

    # Create the systemd service
    cat << EOF > "${service_dir}/backhaul-iran${tunnel_port}.service"
[Unit]
Description=Backhaul Iran Port $tunnel_port (Iran)
After=network.target

[Service]
Type=simple
ExecStart=${config_dir}/backhaul -c ${config_dir}/iran${tunnel_port}.toml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Reload and enable service
    systemctl daemon-reload >/dev/null 2>&1
    if systemctl enable --now "${service_dir}/backhaul-iran${tunnel_port}.service" >/dev/null 2>&1; then
        colorize indigo "Iran service with port $tunnel_port enabled to start on boot and started."
    else
        colorize purple "Failed to enable service with port $tunnel_port. Please check your system configuration."
        return 1
    fi

    echo
    log_action "Created IRAN tunnel on port $tunnel_port"
    colorize indigo "IRAN server configuration completed successfully." bold
}

# Function for configuring Kharej server
kharej_server_configuration() {
    clear
    colorize purple "Configuring Kharej server" bold

    echo

    # Prompt for IRAN server IP address


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
        echo -ne "[*] IRAN server IP address [IPv4/IPv6]: "
        read -r SERVER_ADDR
        if [[ -n "$SERVER_ADDR" ]]; then
            break
        else
            colorize purple "Server address cannot be empty. Please enter a valid address."
            echo
        fi
    done

    echo

    # Read the tunnel port


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
        echo -ne "[*] Tunnel port: "
        read -r tunnel_port

        if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; then
            break
        else
            colorize purple "Please enter a valid port number between 23 and 65535"
            echo
        fi
    done

    echo

    # Initialize transport variable
    local transport=""
    while [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; do
        echo -ne "[*] Transport type (tcp/tcpmux/utcpmux/ws/wsmux/uwsmux/udp/tcptun/faketcptun): "
        read -r transport

        if [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; then
            colorize purple "Invalid transport type. Please choose from tcp, tcpmux, utcpmux, ws, wsmux, uwsmux, udp, tcptun, faketcptun."
            echo
        fi
    done

    # TUN Device Name
    local tun_name="backhaul"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
        echo


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
            echo -ne "[-] TUN Device Name (default backhaul): "
            read -r tun_name

            if [[ -z "$tun_name" ]]; then
                tun_name="backhaul"
            fi

            if [[ "$tun_name" =~ ^[a-zA-Z0-9]+$ ]]; then
                echo
                break
            else
                colorize purple "Please enter a valid TUN device name."
                echo
            fi
        done
    fi

    # TUN Subnet
    local tun_subnet="10.10.10.0/24"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
            echo -ne "[-] TUN Subnet (default 10.10.10.0/24): "
            read -r tun_subnet

            # Set default value if input is empty
            if [[ -z "$tun_subnet" ]]; then
                tun_subnet="10.10.10.0/24"
            fi

            # Validate TUN subnet (CIDR notation)
            if [[ "$tun_subnet" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then
                # Validate IP and subnet mask
                IFS='/' read -r ip subnet <<< "$tun_subnet"
                if [[ "$subnet" -le 32 && "$subnet" -ge 1 ]]; then
                    IFS='.' read -r a b c d <<< "$ip"
                    if [[ "$a" -le 255 && "$b" -le 255 && "$c" -le 255 && "$d" -le 255 ]]; then
                        echo
                        break
                    fi
                fi
            fi

            colorize purple "Please enter a valid subnet in CIDR notation (e.g., 10.10.10.0/24)."
            echo
        done
    fi

    # TUN MTU
    local mtu="1500"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
            echo -ne "[-] TUN MTU (default 1500): "
            read -r mtu

            # Set default value if input is empty
            if [[ -z "$mtu" ]]; then
                mtu=1500
            fi

            # Validate MTU value
            if [[ "$mtu" =~ ^[0-9]+$ ]] && [ "$mtu" -ge 576 ] && [ "$mtu" -le 9000 ]; then
                break
            fi

            colorize purple "Please enter a valid MTU value between 576 and 9000."
            echo
        done
    fi


    # Edge IP
    if [[ "$transport" =~ ^(ws|wsmux|uwsmux)$ ]]; then


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
            echo
            echo -ne "[-] Edge IP/Domain (optional)(press enter to disable): "
            read -r edge_ip

            # Set default if input is empty
            if [[ -z "$edge_ip" ]]; then
                edge_ip="#edge_ip = \"188.114.96.0\""
                break
            fi

            # format the edge_ip variable
            edge_ip="edge_ip = \"$edge_ip\""
            break
        done
    else
        edge_ip="#edge_ip = \"188.114.96.0\""
    fi

    echo

    # Security Token
    echo -ne "[-] Security Token (press enter to use default value): "
    read -r token
    token="${token:-your_token}"

    # Enable TCP_NODELAY
    local nodelay=""

    # Check transport type
    if [[ "$transport" == "udp" ]]; then
        nodelay=false
    else
        echo
        while [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; do
            echo -ne "[-] Enable TCP_NODELAY (true/false)(default true): "
            read -r nodelay

            if [[ -z "$nodelay" ]]; then
                nodelay=true
            fi


            if [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; then
                colorize purple "Invalid input. Please enter 'true' or 'false'."
                echo
            fi
        done
    fi


    # Connection Pool
    local pool=8
    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then
    	echo


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
            echo -ne "[-] Connection Pool (default 8): "
            read -r pool

            if [[ -z "$pool" ]]; then
                pool=8
            fi


            if [[ "$pool" =~ ^[0-9]+$ ]] && [ "$pool" -gt 1 ] && [ "$pool" -le 1024 ]; then
                break
            else
                colorize purple "Please enter a valid connection pool between 1 and 1024."
                echo
            fi
        done
    fi

    # Mux Version
    if [[ "$transport" =~ ^(tcpmux|wsmux|utcpmux|uwsmux)$ ]]; then


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
            echo
            echo -ne "[-] Mux Version (1 or 2) (default 2): "
            read -r mux_version

            # Set default to 1 if input is empty
            if [[ -z "$mux_version" ]]; then
                mux_version=2
            fi

            # Validate the input for version 1 or 2
            if [[ "$mux_version" =~ ^[0-9]+$ ]] && [ "$mux_version" -ge 1 ] && [ "$mux_version" -le 2 ]; then
                break
            else
                colorize purple "Please enter a valid mux version: 1 or 2."
                echo
            fi
        done
    else
        mux_version=2
    fi

    echo

	# Enable Sniffer
    local sniffer=""
    while [[ "$sniffer" != "true" && "$sniffer" != "false" ]]; do
        echo -ne "[-] Enable Sniffer (true/false)(default false): "
        read -r sniffer

        if [[ -z "$sniffer" ]]; then
            sniffer=false
        fi

        if [[ "$sniffer" != "true" && "$sniffer" != "false" ]]; then
            colorize purple "Invalid input. Please enter 'true' or 'false'."
            echo
        fi
    done

	echo

    # Get Web Port
	local web_port=""


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
	    echo -ne "[-] Enter Web Port (default 0 to disable): "
	    read -r web_port

        if [[ -z "$web_port" ]]; then
            web_port=0
        fi

	    if [[ "$web_port" == "0" ]]; then
	        break
	    elif [[ "$web_port" =~ ^[0-9]+$ ]] && ((web_port >= 23 && web_port <= 65535)); then
	        if check_port "$web_port" "tcp"; then
	            colorize purple "Port $web_port is already in use. Please choose a different port."
	            echo
	        else
	            break
	        fi
	    else
	        colorize purple "Invalid port. Please enter a number between 22 and 65535, or 0 to disable."
	        echo
	    fi
	done



    # IP Limit
    if [[ ! "$transport" =~ ^(ws|udp|tcptun|faketcptun)$ ]]; then
        # Enable IP Limit
        local ip_limit=""
        while [[ "$ip_limit" != "true" && "$ip_limit" != "false" ]]; do
            echo
            echo -ne "[-] Enable IP Limit for X-UI Panel (true/false)(default false): "
            read -r ip_limit

            if [[ -z "$ip_limit" ]]; then
                ip_limit=false
            fi

            if [[ "$ip_limit" != "true" && "$ip_limit" != "false" ]]; then
                colorize purple "Invalid input. Please enter 'true' or 'false'."
                echo
            fi
        done
    else
	    # Automatically set proxy_protocol to false for ws and udp
	    ip_limit="false"
	fi

    # Generate client configuration file
    backup_config_file "${config_dir}/kharej${tunnel_port}.toml"
    cat << EOF > "${config_dir}/kharej${tunnel_port}.toml"
[client]
remote_addr = "${SERVER_ADDR}:${tunnel_port}"
${edge_ip}
transport = "${transport}"
token = "${token}"
connection_pool = ${pool}
aggressive_pool = false
keepalive_period = 75
nodelay = ${nodelay}
retry_interval = 3
dial_timeout = 10
mux_version = ${mux_version}
mux_framesize = 32768
mux_recievebuffer = 4194304
mux_streambuffer = 2000000
sniffer = ${sniffer}
web_port = ${web_port}
sniffer_log = "/root/log.json"
log_level = "info"
ip_limit= ${ip_limit}
tun_name = "${tun_name}"
tun_subnet = "${tun_subnet}"
mtu = ${mtu}
EOF

    echo

    # Create the systemd service unit file
    cat << EOF > "${service_dir}/backhaul-kharej${tunnel_port}.service"
[Unit]
Description=Backhaul Kharej Port $tunnel_port
After=network.target

[Service]
Type=simple
ExecStart=${config_dir}/backhaul -c ${config_dir}/kharej${tunnel_port}.toml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd to apply new service
    systemctl daemon-reload >/dev/null 2>&1

    # Enable and start the service
    if systemctl enable --now "${service_dir}/backhaul-kharej${tunnel_port}.service" >/dev/null 2>&1; then
        colorize indigo "Kharej service with port $tunnel_port enabled to start on boot and started."
    else
        colorize purple "Failed to enable service with port $tunnel_port. Please check your system configuration."
        return 1
    fi

    echo
    log_action "Created KHAREJ tunnel on port $tunnel_port"
    colorize indigo "Kharej server configuration completed successfully." bold
}

remove_core(){
	echo
	# If user try to remove core and still a service is running, we should prohibit this.
	# Check if any .toml file exists
	if find "$config_dir" -type f -name "*.toml" | grep -q .; then
	    colorize purple "You should delete all services first and then delete the Backhaul-Core."
	    sleep 3
	    return 1
	else
	    colorize purple "No .toml file found in the directory."
	fi

	echo

	# Prompt to confirm before removing Backhaul-core directory
	colorize indigo "Do you want to remove Backhaul-Core? (y/n)"
    read -r confirm
	echo
	if [[ $confirm == [yY] ]]; then
	    if [[ -d "$config_dir" ]]; then
	        rm -rf "$config_dir" >/dev/null 2>&1
	        log_action "Backhaul core removed"
        colorize indigo "Backhaul-Core directory removed." bold
	    else
	        colorize purple "Backhaul-Core directory not found." bold
	    fi
	else
	    colorize indigo "Backhaul-Core removal canceled."
	fi

	echo
	press_key
}

# Function for checking tunnel status
check_tunnel_status() {
    echo

	# Check for .toml files
	if ! ls "$config_dir"/*.toml 1> /dev/null 2>&1; then
	    colorize purple "No config files found in the Backhaul directory." bold
	    echo
	    press_key
	    return 1
	fi

	clear
    colorize indigo "Checking all services status..." bold
    sleep 1
    echo
    for config_path in "$config_dir"/iran*.toml; do
        if [ -f "$config_path" ]; then
            # Extract config_name without directory path and change it to service name
			config_name=$(basename "$config_path")
			config_name="${config_name%.toml}"
			service_name="backhaul-${config_name}.service"
            config_port="${config_name#iran}"

			# Check if the Backhaul-client-kharej service is active
			if systemctl is-active --quiet "$service_name"; then
				colorize indigo "Iran service with tunnel port $config_port is running"
			else
				colorize purple "Iran service with tunnel port $config_port is not running"
			fi
   		fi
    done

    for config_path in "$config_dir"/kharej*.toml; do
        if [ -f "$config_path" ]; then
            # Extract config_name without directory path and change it to service name
			config_name=$(basename "$config_path")
			config_name="${config_name%.toml}"
			service_name="backhaul-${config_name}.service"
            config_port="${config_name#kharej}"

			# Check if the Backhaul-client-kharej service is active
			if systemctl is-active --quiet "$service_name"; then
				colorize indigo "Kharej service with tunnel port $config_port is running"
			else
				colorize purple "Kharej service with tunnel port $config_port is not running"
			fi
   		fi
    done


    echo
    press_key
}

# Function for destroying tunnel
tunnel_management() {
	echo
	# Check for .toml files
	if ! ls "$config_dir"/*.toml 1> /dev/null 2>&1; then
	    colorize purple "No config files found in the Backhaul directory." bold
	    echo
	    press_key
	    return 1
	fi

	clear
	colorize purple "List of existing services to manage:" bold
	echo

	#Variables
    local index=1
    declare -a configs

    for config_path in "$config_dir"/iran*.toml; do
        if [ -f "$config_path" ]; then
            # Extract config_name without directory path
            config_name=$(basename "$config_path")

            # Remove "iran" prefix and ".toml" suffix
            config_port="${config_name#iran}"
            config_port="${config_port%.toml}"

            configs+=("$config_path")
            echo -e "${PURPLE}${index}${NC}) ${INDIGO}Iran${NC} service, Tunnel port: ${INDIGO}$config_port${NC}"
            ((index++))
        fi
    done



    for config_path in "$config_dir"/kharej*.toml; do
        if [ -f "$config_path" ]; then
            # Extract config_name without directory path
            config_name=$(basename "$config_path")

            # Remove "kharej" prefix and ".toml" suffix
            config_port="${config_name#kharej}"
            config_port="${config_port%.toml}"

            configs+=("$config_path")
            echo -e "${PURPLE}${index}${NC}) ${INDIGO}Kharej${NC} service, Tunnel port: ${INDIGO}$config_port${NC}"
            ((index++))
        fi
    done

    echo
	echo -ne "Enter your choice (0 to return): "
    read choice

	# Check if the user chose to return
	if (( choice == 0 )); then
	    return
	fi
	#  validation
	while ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 0 || choice > ${#configs[@]} )); do
	    colorize purple "Invalid choice. Please enter a number between 1 and ${#configs[@]}." bold
	    echo
	    echo -ne "Enter your choice (0 to return): "
	    read choice
		if (( choice == 0 )); then
			return
		fi
	done

	selected_config="${configs[$((choice - 1))]}"
	config_name=$(basename "${selected_config%.toml}")
	service_name="backhaul-${config_name}.service"

	clear
	colorize purple "List of available commands for $config_name:" bold
	echo
	colorize purple "1) Remove this tunnel"
	colorize indigo "2) Restart this tunnel"
	colorize reset "3) View service logs"
    colorize reset "4) View service status"
	echo
	read -p "Enter your choice (0 to return): " choice

    case $choice in
        7) web_panel_manager ;;
        8) reduce_ping_jitter ;;        1) destroy_tunnel "$selected_config" ;;
        2) restart_service "$service_name" ;;
        3) view_service_logs "$service_name" ;;
        4) view_service_status "$service_name" ;;
        0) return 1 ;;
        *) echo -e "${PURPLE}Invalid option!${NC}" && sleep 1 && return 1;;
    esac

}

destroy_tunnel(){
	#Vaiables
	config_path="$1"
	config_name=$(basename "${config_path%.toml}")
    service_name="backhaul-${config_name}.service"
    service_path="$service_dir/$service_name"

	# Check if config exists and delete it
	if [ -f "$config_path" ]; then
	  backup_config_file "$config_path"
  rm -f "$config_path" >/dev/null 2>&1
	fi


    # Stop and disable the client service if it exists
    if [[ -f "$service_path" ]]; then
        if systemctl is-active "$service_name" &>/dev/null; then
            systemctl disable --now "$service_name" >/dev/null 2>&1
        fi
        rm -f "$service_path" >/dev/null 2>&1
    fi


    echo
    # Reload systemd to read the new unit file
    if systemctl daemon-reload >/dev/null 2>&1 ; then
        echo -e "Systemd daemon reloaded.\n"
    else
        echo -e "${PURPLE}Failed to reload systemd daemon. Please check your system configuration.${NC}"
    fi

    log_action "Tunnel $config_name destroyed"
    colorize indigo "Tunnel destroyed successfully!" bold
    echo
    press_key
}

#Function to restart services
restart_service() {
    echo
    service_name="$1"
    colorize indigo "Restarting $service_name" bold
    echo

    # Check if service exists
    if systemctl list-units --type=service | grep -q "$service_name"; then
        systemctl restart "$service_name"
        colorize indigo "Service restarted successfully" bold

    else
        colorize purple "Cannot restart the service"
    fi
    echo
    press_key
}

view_service_logs (){
	clear
	journalctl -eu "$1" -f
    press_key
}

view_service_status (){
	clear
	systemctl status "$1"
    press_key
}

# _________________________ HAWSHEMI SCRIPT OPT FOR UBUNTU _________________________
# Declare Paths & Settings.
SYS_PATH="/etc/sysctl.conf"
PROF_PATH="/etc/profile"

# Ask Reboot
ask_reboot() {
    echo -ne "${INDIGO}Reboot now? (Recommended) (y/n): ${NC}"


# ---- Embedded Web Panel Installer ----

# ---- Embedded Web Panel Uninstaller ----
while true; do
        read choice
        echo
        if [[ "$choice" == 'y' || "$choice" == 'Y' ]]; then
            sleep 0.5
            reboot
            exit 0
        fi
        if [[ "$choice" == 'n' || "$choice" == 'N' ]]; then
            break
        fi
    done
}
# SYSCTL Optimization
sysctl_optimizations() {
    ## Make a backup of the original sysctl.conf file
    cp $SYS_PATH /etc/sysctl.conf.bak

    echo
    echo -e "${INDIGO}Default sysctl.conf file Saved. Directory: /etc/sysctl.conf.bak${NC}"
    echo
    sleep 1

    echo

echo -e
# Check if the operating system is Ubuntu
if [ "$os_name" == "Ubuntu" ]; then
  echo -e "${INDIGO}The operating system is Ubuntu.${NC}"
  sleep 1
else
  echo -e "${PURPLE} The operating system is not Ubuntu.${NC}"
  sleep 2
  return
fi

sysctl_optimizations
limits_optimizations
ask_reboot
read -p "Press Enter to continue..."
}

#!/bin/bash

check_core_version() {
    local url=$1
    local tmp_file=$(mktemp)

    # Download the file to a temporary location
    curl -s -o "$tmp_file" "$url"

    # Check if the download was successful
    if [ $? -ne 0 ]; then
        colorize purple "Failed to check latest core version"
        return 1
    fi

    # Read the version from the downloaded file (assumes the version is stopurple on the first line)
    local file_version=$(head -n 1 "$tmp_file")

    # Get the version from the backhaul binary using the -v flag
    local backhaul_version=$($config_dir/backhaul -v)

    # Compare the file version with the version from backhaul
    if [ "$file_version" != "$backhaul_version" ]; then
        colorize purple "New Core version available: $backhaul_version => $file_version" bold
    fi

    # Clean up the temporary file
    rm "$tmp_file"
}

check_script_version() {
    local url=$1
    local tmp_file=$(mktemp)

    # Download the file to a temporary location
    curl -s -o "$tmp_file" "$url"

    # Check if the download was successful
    if [ $? -ne 0 ]; then
        colorize purple "Failed to check latest script version"
        return 1
    fi

    # Read the version from the downloaded file (assumes the version is stopurple on the first line)
    local file_version=$(head -n 1 "$tmp_file")

    # Compare the file version with the version from backhaul
    if [ "$file_version" != "$SCRIPT_VERSION" ]; then
        colorize purple "New script version available: $SCRIPT_VERSION => $file_version" bold
    fi

    # Clean up the temporary file
    rm "$tmp_file"
}

update_script(){
# Define the destination path
DEST_DIR="/usr/bin/"
BACKHAUL_SCRIPT="backhaul"
SCRIPT_URL="https://raw.githubusercontent.com/iPmartNetwork/Backhaul/refs/heads/master/install.sh"

echo
# Check if backhaul.sh exists in /bin/bash
if [ -f "$DEST_DIR/$BACKHAUL_SCRIPT" ]; then
    # Remove the existing rathole
    rm "$DEST_DIR/$BACKHAUL_SCRIPT"
    if [ $? -eq 0 ]; then
        echo -e "${INDIGO}Existing $BACKHAUL_SCRIPT has been successfully removed from $DEST_DIR.${NC}"
    else
        echo -e "${PURPLE}Failed to remove existing $BACKHAUL_SCRIPT from $DEST_DIR.${NC}"
        sleep 1
        return 1
    fi
else
    echo -e "${INDIGO}$BACKHAUL_SCRIPT does not exist in $DEST_DIR. No need to remove.${NC}"
fi

# Download the new backhaul.sh from the GitHub URL
curl -s -L -o "$DEST_DIR/$BACKHAUL_SCRIPT" "$SCRIPT_URL"

echo
if [ $? -eq 0 ]; then
    chmod +x "$DEST_DIR/$BACKHAUL_SCRIPT"
    colorize indigo "Type 'backhaul' to run the script.\n" bold
    colorize indigo "For removing script type: rm -rf /usr/bin/backhaul\n" bold
    press_key
    exit 0
else
    echo -e "${PURPLE}Failed to download $BACKHAUL_SCRIPT from $SCRIPT_URL.${NC}"
    sleep 1
    return 1
fi

}

# Color codes
PURPLE='[1;95m'
INDIGO='[1;35m'
NC='[0m' # No Color

# Function to display menu
display_menu() {
    clear
    display_logo
    display_server_info

    # Count tunnels
    local active=0 inactive=0
    for config in "$config_dir"/*.toml; do
        [[ -f "$config" ]] || continue
        name=$(basename "${config%.toml}")
        service="backhaul-${name}.service"
        if systemctl is-active --quiet "$service"; then
            ((active++))
        else
            ((inactive++))
        fi
    done
    echo -e "${INDIGO}Tunnels: 🟢 $active active | 🔴 $inactive inactive${NC}\n"


    echo
    colorize indigo " 1. Configure a new tunnel [IPv4/IPv6]" bold
    colorize purple " 2. Tunnel management menu" bold
    colorize indigo " 3. Check tunnels status" bold
    colorize purple " 4. Update & Install Backhaul Core" bold
    colorize indigo " 5. Update & install script" bold
    colorize purple " 6. Remove Backhaul Core" bold
    colorize indigo " 7. web panel manager" bold
    colorize purple " 8. Reduce Ping & Jitter" bold
    colorize indigo " 0. Exit" bold
    echo
    echo "-------------------------------"
}

# Function to read user input

web_panel_manager() {
    clear
    echo -e "${INDIGO}╭──────────────────────────────╮"
    echo -e "${PURPLE}│     🌐 Web Panel Manager     │"
    echo -e "${INDIGO}╰──────────────────────────────╯"
    echo
    echo -e "${PURPLE}1) Install Web Panel"
    echo -e "${PURPLE}2) Uninstall Web Panel"
    echo -e "${PURPLE}3) Check API Service Status"
        echo -e "${PURPLE}4) Install API Service"
        echo -e "${PURPLE}5) Uninstall API Service"
    
        echo -e "${PURPLE}4) Install API Service"
        echo -e "${PURPLE}5) Uninstall API Service"
        echo -e "${PURPLE}0) Return to main menu"
    echo
    read -rp "Choose an option: " opt

    case "$opt" in
        1)
            bash <(curl -Ls https://raw.githubusercontent.com/iPmartNetwork/Backhaul/master/install_backhaul_webpanel.sh)
            ;;
        2)
            bash <(curl -Ls https://raw.githubusercontent.com/iPmartNetwork/Backhaul/master/uninstall_backhaul_webpanel.sh)
            ;;
        3)
            systemctl status backhaul-api
            ;;
        4)
            bash <(curl -Ls https://raw.githubusercontent.com/iPmartNetwork/Backhaul/master/install_backhaul_api.sh)
            ;;
        5)
            bash <(curl -Ls https://raw.githubusercontent.com/iPmartNetwork/Backhaul/master/uninstall_backhaul_api.sh)
            ;;
        0)
            return
            ;;
        *)
            echo -e "${PURPLE}Invalid selection.${NC}"
            ;;
    esac

    echo
    read -rp "Press Enter to return..."
}


read_option() {
    read -p "Enter your choice [0-9]: " choice
    case $choice in
        1) configure_tunnel ;;
	7) web_panel_manager ;;
        8) reduce_ping_jitter ;;
        2) tunnel_management ;;
        3) check_tunnel_status ;;
        4) download_and_extract_backhaul "menu";;
        5) update_script ;;
        6) remove_core ;;
        0) exit 0 ;;
        *) echo -e "${PURPLE} Invalid option!${NC}" && sleep 1 ;;
    esac
}

reduce_ping_jitter() {
    clear
    echo -e "\033[1;33m🔧 Applying system tweaks to reduce ping and jitter...\033[0m"

    sysctl -w net.ipv4.tcp_congestion_control=bbr
    sysctl -w net.core.default_qdisc=fq
    sysctl -w net.ipv4.tcp_notsent_lowat=16384
    sysctl -w net.ipv4.tcp_ecn=1
    sysctl -w net.core.netdev_max_backlog=250000

    ulimit -n 1048576

    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_notsent_lowat = 16384" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_ecn = 1" >> /etc/sysctl.conf
    echo "net.core.netdev_max_backlog = 250000" >> /etc/sysctl.conf

    sysctl -p > /dev/null 2>&1

    echo -e "\033[1;32m✅ Tweaks applied. Reboot recommended for full effect.\033[0m"
    read -p "Press Enter to continue..."
}

# Main script
while true
do
    display_menu
    read_option
done

# Function: Reduce Ping & Jitter


# --- Web Panel Manager Integration ---
SCRIPT_VERSION="v2.1.0"


# ---- Embedded Web Panel Uninstaller ----
while true; do
