#!/bin/bash

# Define script version
SCRIPT_VERSION="v1.7.0"

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   sleep 1
   exit 1
fi

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
    local red="\033[31m"
    local green="\033[32m"
    local yellow="\033[33m"
    local blue="\033[34m"
    local magenta="\033[35m"
    local cyan="\033[36m"
    local white="\033[37m"
    local reset="\033[0m"
    
    # Define ANSI style codes
    local normal="\033[0m"
    local bold="\033[1m"
    local underline="\033[4m"
    
    # Fix: Validate color input
    local color_code
    case $color in
        black) color_code=$black ;;
        red) color_code=$red ;;
        green) color_code=$green ;;
        yellow) color_code=$yellow ;;
        blue) color_code=$blue ;;
        magenta) color_code=$magenta ;;
        cyan) color_code=$cyan ;;
        white) color_code=$white ;;
        *) color_code=$reset ;;  # Default case, no color
    esac

    # Fix: Validate style input
    local style_code
    case $style in
        bold) style_code=$bold ;;
        underline) style_code=$underline ;;
        normal | *) style_code=$normal ;;  # Default case, normal text
    esac

    # Print the colored and styled text
    echo -e "${style_code}${color_code}${text}${reset}"
}


# Function to install unzip if not already installed
install_unzip() {
    if ! command -v unzip &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            echo -e "${RED}unzip is not installed. Installing...${NC}"
            sleep 1
            sudo apt-get update
            sudo apt-get install -y unzip
        else
            echo -e "${RED}Error: Unsupported package manager. Please install unzip manually.${NC}\n"
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
            echo -e "${RED}jq is not installed. Installing...${NC}"
            sleep 1
            sudo apt-get update
            sudo apt-get install -y jq
        else
            echo -e "${RED}Error: Unsupported package manager. Please install jq manually.${NC}\n"
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
        colorize cyan "Restart all services after updating to new core" bold
        sleep 2
    fi
    
    # Check if Backhaul Core is already installed
    if [[ -f "${config_dir}/backhaul" ]]; then
        return 1
    fi

    # Check operating system
    if [[ $(uname) != "Linux" ]]; then
        echo -e "${RED}Unsupported operating system.${NC}"
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
            echo -e "${RED}Unsupported architecture: $ARCH.${NC}"
            sleep 1
            exit 1
            ;;
    esac

    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${RED}Failed to retrieve download URL.${NC}"
        sleep 1
        exit 1
    fi

    # Ensure the config directory exists
    mkdir -p "$config_dir"

    DOWNLOAD_DIR=$(mktemp -d)
    echo -e "Downloading Backhaul from $DOWNLOAD_URL...\n"
    sleep 1
    if ! curl -sSL -o "$DOWNLOAD_DIR/backhaul.tar.gz" "$DOWNLOAD_URL"; then
        colorize red "Failed to download Backhaul Core. Please check your internet connection or the URL."
        exit 1
    fi

    echo -e "Extracting Backhaul...\n"
    sleep 1
    if ! tar -xzf "$DOWNLOAD_DIR/backhaul.tar.gz" -C "$config_dir"; then
        colorize red "Failed to extract Backhaul Core. Please check the downloaded file."
        exit 1
    fi
    echo -e "${GREEN}Backhaul installation completed.${NC}\n"
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
if [[ -z "$SERVER_COUNTRY" || "$SERVER_COUNTRY" == "null" ]]; then
    SERVER_COUNTRY="Unknown"
fi

# Fetch server isp 
SERVER_ISP=$(curl -sS --max-time 2 "http://ipwhois.app/json/$SERVER_IP" | jq -r '.isp')
if [[ -z "$SERVER_ISP" || "$SERVER_ISP" == "null" ]]; then
    SERVER_ISP="Unknown"
fi


# Function to display ASCII logo
display_logo() {   
    echo -e "${CYAN}"
    cat << "EOF"
  ____________________________________________________________________________
      ____                             _     _
 ,   /    )                           /|   /                                 
-----/____/---_--_----__---)__--_/_---/-| -/-----__--_/_-----------__---)__--
 /   /        / /  ) /   ) /   ) /    /  | /    /___) /   | /| /  /   ) /   ) 
_/___/________/_/__/_(___(_/_____(_ __/___|/____(___ _(_ __|/_|/__(___/_/____

             Lightning-fast reverse tunneling solution
EOF
    echo -e "${NC}${GREEN}"
    echo -e "Script Version: ${YELLOW}${SCRIPT_VERSION}${GREEN}"
    if [[ -f "${config_dir}/backhaul" ]]; then
    	echo -e "Core Version: ${YELLOW}$($config_dir/backhaul -v)${GREEN}"
    fi
    echo -e "Telegram Channel: ${YELLOW}@iPmartCh${NC}"
}

# Function to display server location and IP
display_server_info() {
    echo -e "\e[93m═══════════════════════════════════════════\e[0m"  
 
    echo -e "${CYAN}IP Address:${NC} $SERVER_IP"
    echo -e "${CYAN}Location:${NC} $SERVER_COUNTRY "
    echo -e "${CYAN}Datacenter:${NC} $SERVER_ISP"
}

# Function to display Backhaul Core installation status
display_backhaul_core_status() {
    if [[ -f "${config_dir}/backhaul" ]]; then
        echo -e "${CYAN}Backhaul Core:${NC} ${GREEN}Installed${NC}"
    else
        echo -e "${CYAN}Backhaul Core:${NC} ${RED}Not installed${NC}"
    fi
    echo -e "\e[93m═══════════════════════════════════════════\e[0m"  
}

# Enhanced check_ipv6 function to handle edge cases
check_ipv6() {
    local ip=$1
    # Define the IPv6 regex pattern
    ipv6_pattern="^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|::|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$"

    # Remove brackets if present
    ip="${ip#[}"
    ip="${ip%]}"

    if [[ $ip =~ $ipv6_pattern ]]; then
        return 0  # Valid IPv6 address
    else
        return 1  # Invalid IPv6 address
    fi
}

check_port() {
    local PORT=$1
    local TRANSPORT=$2

    if [[ -z "$PORT" || ! "$PORT" =~ ^[0-9]+$ || "$PORT" -lt 1 || "$PORT" -gt 65535 ]]; then
        echo "Invalid port: $PORT. Please provide a valid port number between 1 and 65535."
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
        echo "Invalid transport: $TRANSPORT. Please specify 'tcp' or 'udp'."
        return 1
    fi
}

# Helper function to validate input with a regex
validate_input() {
    local prompt="$1"
    local default="$2"
    local regex="$3"
    local error_message="$4"
    local input

    while true; do
        echo
        colorize cyan "$prompt (default: $default):" bold
        read -r input

        # Set default if input is empty
        input="${input:-$default}"

        # Validate input
        if [[ "$input" =~ $regex ]]; then
            echo "$input"
            return
        else
            colorize red "[ERROR] $error_message" bold
        fi
    done
}

# Helper function to validate CIDR notation
validate_cidr() {
    local prompt="$1"
    local default="$2"
    local error_message="$3"
    local input

    while true; do
        echo
        colorize cyan "$prompt (default: $default):" bold
        read -r input

        # Set default if input is empty
        input="${input:-$default}"

        # Validate CIDR notation
        if [[ "$input" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then
            IFS='/' read -r ip subnet <<< "$input"
            if [[ "$subnet" -le 32 && "$subnet" -ge 1 ]]; then
                IFS='.' read -r a b c d <<< "$ip"
                if [[ "$a" -le 255 && "$b" -le 255 && "$c" -le 255 && "$d" -le 255 ]]; then
                    echo "$input"
                    return
                fi
            fi
        fi
        colorize red "[ERROR] $error_message" bold
    done
}

# Function for configuring tunnel
configure_tunnel() {

# check if the Backhaul-core installed or not
if [[ ! -d "$config_dir" ]]; then
    echo -e "\n${RED}Backhaul-Core directory not found. Install it first through 'Install Backhaul core' option.${NC}\n"
    read -p "Press Enter to continue..."
    return 1
fi

    clear

    echo
    colorize green "1) Configure for IRAN server" bold
    colorize magenta "2) Configure for KHAREJ server" bold
    colorize red "0) Back to Main Menu" bold
    echo
    read -p "Enter your choice: " configure_choice
    case "$configure_choice" in
        1) iran_server_configuration ;;
        2) kharej_server_configuration ;;
        0) return ;;
        *) echo -e "${RED}Invalid option!${NC}" && sleep 1 ;;
    esac
    echo
    read -p "Press Enter to continue..."
}

#Global Variables
service_dir="/etc/systemd/system"


iran_server_configuration() {  
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

    # Initialize transport variable
    local transport=""
    while true; do
        echo -e "[*] Select Transport Type:"
        echo -e "  1) tcp"
        echo -e "  2) tcpmux"
        echo -e "  3) utcpmux"
        echo -e "  4) ws"
        echo -e "  5) wsmux"
        echo -e "  6) uwsmux"
        echo -e "  7) udp"
        echo -e "  8) tcptun"
        echo -e "  9) faketcptun"
        echo -ne "Enter your choice [1-9]: "
        read -r transport_choice

        case "$transport_choice" in
            1) transport="tcp" ;;
            2) transport="tcpmux" ;;
            3) transport="utcpmux" ;;
            4) transport="ws" ;;
            5) transport="wsmux" ;;
            6) transport="uwsmux" ;;
            7) transport="udp" ;;
            8) transport="tcptun" ;;
            9) transport="faketcptun" ;;
            *) colorize red "Invalid choice. Please select a valid transport type." && continue ;;
        esac
        break
    done

    echo

    # TUN Device Name 
    local tun_name="backhaul"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
        tun_name=$(validate_input "TUN Device Name" "backhaul" "^[a-zA-Z0-9]+$" "Invalid TUN device name. Please use alphanumeric characters only.")
    fi

    # TUN Subnet
    local tun_subnet="10.10.10.0/24"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
        tun_subnet=$(validate_cidr "TUN Subnet" "10.10.10.0/24" "Invalid subnet. Please use CIDR notation (e.g., 10.10.10.0/24).")
    fi

    echo

    # TUN MTU
    local mtu="1500"    
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
        mtu=$(validate_input "TUN MTU" "1500" "^[0-9]+$" "Invalid MTU value. Please enter a number between 576 and 9000.")
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
	            colorize red "Invalid input. Please enter 'true' or 'false'."
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
                colorize red "Please enter a valid channel size between 64 and 8192."
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
                colorize red "Invalid input. Please enter 'true' or 'false'."
                echo
            fi
        done
    fi
    
    echo 
    
    # HeartBeat
    local heartbeat=40
    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then
        while true; do
            echo -ne "[-] Heartbeat (in seconds, default 40): "
            read -r heartbeat

            if [[ -z "$heartbeat" ]]; then
                heartbeat=40
            fi
                
            if [[ "$heartbeat" =~ ^[0-9]+$ ]] && [ "$heartbeat" -gt 1 ] && [ "$heartbeat" -le 240 ]; then
                break
            else
                colorize red "Please enter a valid heartbeat between 1 and 240."
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
                colorize red "Please enter a valid concurrency between 0 and 1000"
                echo
            fi
        done
    else
        mux=8
    fi
    
    	
    # Mux Version
    if [[ "$transport" =~ ^(tcpmux|wsmux|utcpmux|uwsmux)$ ]]; then
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
                colorize red "Please enter a valid mux version: 1 or 2."
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
            colorize red "Invalid input. Please enter 'true' or 'false'."
            echo
        fi
    done
	
	echo 
	
	# Get Web Port
	local web_port=""
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
	            colorize red "Port $web_port is already in use. Please choose a different port."
	            echo
	        else
	            break
	        fi
	    else
	        colorize red "Invalid port. Please enter a number between 22 and 65535, or 0 to disable."
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
                colorize red "Invalid input. Please enter 'true' or 'false'."
                echo
            fi
        done
    else
	    # Automatically set proxy_protocol to false for ws and udp
	    proxy_protocol="false"
	fi

        
	echo

    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then
        echo
        echo -ne "[*] Enter your ports (comma-separated): "
        read -r input_ports
        input_ports=$(echo "$input_ports" | tr -d ' ')
        IFS=',' read -r -a ports <<< "$input_ports"
    fi

    # Generate configuration
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
	    echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	done
	
	echo "]" >> "${config_dir}/iran${tunnel_port}.toml"
	
	echo
	
	colorize green "Configuration generated successfully!"

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
User=backhaul
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

    # Reload and enable service
    systemctl daemon-reload >/dev/null 2>&1
    if systemctl enable --now "${service_dir}/backhaul-iran${tunnel_port}.service" >/dev/null 2>&1; then
        colorize green "Iran service with port $tunnel_port enabled to start on boot and started."
    else
        colorize red "Failed to enable service with port $tunnel_port. Please check your system configuration."
        return 1
    fi

    echo
    colorize green "IRAN server configuration completed successfully." bold
}

# Function for configuring Kharej server
kharej_server_configuration() {
    clear
    colorize cyan "Configuring Kharej server" bold
    
    echo

    # Prompt for IRAN server IP address
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

    # Read the tunnel port
    while true; do
        echo -ne "[*] Tunnel port: "
        read -r tunnel_port

        if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; then
            break
        else
            colorize red "Please enter a valid port number between 23 and 65535"
            echo
        fi
    done

    echo


    # Initialize transport variable
    local transport=""
    while true; do
        echo -e "[*] Select Transport Type:"
        echo -e "  1) tcp"
        echo -e "  2) tcpmux"
        echo -e "  3) utcpmux"
        echo -e "  4) ws"
        echo -e "  5) wsmux"
        echo -e "  6) uwsmux"
        echo -e "  7) udp"
        echo -e "  8) tcptun"
        echo -e "  9) faketcptun"
        echo -ne "Enter your choice [1-9]: "
        read -r transport_choice

        case "$transport_choice" in
            1) transport="tcp" ;;
            2) transport="tcpmux" ;;
            3) transport="utcpmux" ;;
            4) transport="ws" ;;
            5) transport="wsmux" ;;
            6) transport="uwsmux" ;;
            7) transport="udp" ;;
            8) transport="tcptun" ;;
            9) transport="faketcptun" ;;
            *) colorize red "Invalid choice. Please select a valid transport type." && continue ;;
        esac
        break
    done

    # TUN Device Name 
    local tun_name="backhaul"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
        tun_name=$(validate_input "TUN Device Name" "backhaul" "^[a-zA-Z0-9]+$" "Invalid TUN device name. Please use alphanumeric characters only.")
    fi

    # TUN Subnet
    local tun_subnet="10.10.10.0/24"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
        tun_subnet=$(validate_cidr "TUN Subnet" "10.10.10.0/24" "Invalid subnet. Please use CIDR notation (e.g., 10.10.10.0/24).")
    fi

    echo

    # TUN MTU
    local mtu="1500"    
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
        mtu=$(validate_input "TUN MTU" "1500" "^[0-9]+$" "Invalid MTU value. Please enter a number between 576 and 9000.")
    fi
    

    # Edge IP
    if [[ "$transport" =~ ^(ws|wsmux|uwsmux)$ ]]; then
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
        while [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; do
            echo -ne "[-] Enable TCP_NODELAY (true/false)(default true): "
            read -r nodelay
            
            if [[ -z "$nodelay" ]]; then
                nodelay=true
            fi
        
        
            if [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; then
                colorize red "Invalid input. Please enter 'true' or 'false'."
                echo
            fi
        done
    fi

	    
    # Connection Pool
    local pool=8
    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then
    	echo 
        while true; do
            echo -ne "[-] Connection Pool (default 8): "
            read -r pool

            if [[ -z "$pool" ]]; then
                pool=8
            fi
            
            
            if [[ "$pool" =~ ^[0-9]+$ ]] && [ "$pool" -gt 1 ] && [ "$pool" -le 1024 ]; then
                break
            else
                colorize red "Please enter a valid connection pool between 1 and 1024."
                echo
            fi
        done
    fi


    # Mux Version
    if [[ "$transport" =~ ^(tcpmux|wsmux|utcpmux|uwsmux)$ ]]; then
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
                colorize red "Please enter a valid mux version: 1 or 2."
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
            colorize red "Invalid input. Please enter 'true' or 'false'."
            echo
        fi
    done
	
	echo 
	
    # Get Web Port
	local web_port=""
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
	            colorize red "Port $web_port is already in use. Please choose a different port."
	            echo
	        else
	            break
	        fi
	    else
	        colorize red "Invalid port. Please enter a number between 22 and 65535, or 0 to disable."
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
                colorize red "Invalid input. Please enter 'true' or 'false'."
                echo
            fi
        done
    else
	    # Automatically set proxy_protocol to false for ws and udp
	    ip_limit="false"
	fi


    # Generate client configuration file
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
User=backhaul
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd to apply new service
    systemctl daemon-reload >/dev/null 2>&1

    # Enable and start the service
    if systemctl enable --now "${service_dir}/backhaul-kharej${tunnel_port}.service" >/dev/null 2>&1; then
        colorize green "Kharej service with port $tunnel_port enabled to start on boot and started."
    else
        colorize red "Failed to enable service with port $tunnel_port. Please check your system configuration."
        return 1
    fi

    echo
    colorize green "Kharej server configuration completed successfully." bold
}



remove_core(){
	echo
	# If user try to remove core and still a service is running, we should prohibit this.	
	# Check if any .toml file exists
	if find "$config_dir" -type f -name "*.toml" | grep -q .; then
	    colorize red "You should delete all services first and then delete the Backhaul-Core."
	    sleep 3
	    return 1
	else
	    colorize cyan "No .toml file found in the directory."
	fi

	echo
	
	# Prompt to confirm before removing Backhaul-core directory
	colorize yellow "Do you want to remove Backhaul-Core? (y/n)"
    read -r confirm
	echo     
	if [[ $confirm == [yY] ]]; then
	    if [[ -d "$config_dir" ]]; then
	        rm -rf "$config_dir" >/dev/null 2>&1
	        colorize green "Backhaul-Core directory removed." bold
	    else
	        colorize red "Backhaul-Core directory not found." bold
	    fi
	else
	    colorize yellow "Backhaul-Core removal canceled."
	fi
	
	echo
	press_key
}

# Function for checking tunnel status
check_tunnel_status() {
    echo

    # Check for .toml files
    if ! ls "$config_dir"/*.toml 1> /dev/null 2>&1; then
        colorize red "No config files found in the Backhaul directory." bold
        echo
        press_key
        return 1
    fi

    clear
    colorize yellow "Checking all services status..." bold
    sleep 1
    echo
    for config_path in "$config_dir"/iran*.toml "$config_dir"/kharej*.toml; do
        if [ -f "$config_path" ]; then
            # Extract config_name without directory path and change it to service name
            config_name=$(basename "$config_path")
            config_name="${config_name%.toml}"
            service_name="backhaul-${config_name}.service"

            # Check and fix the service
            check_and_fix_tunnel_service "$service_name" "$config_path"
        fi
    done

    echo
    press_key
}

# Function to check and fix tunnel service issues
check_and_fix_tunnel_service() {
    local service_name="$1"
    local config_path="$2"

    # Check if the service exists
    if ! systemctl list-units --type=service | grep -q "$service_name"; then
        colorize red "Service $service_name does not exist. Attempting to recreate it..." bold

        # Recreate the service file
        local tunnel_port=$(basename "$config_path" | sed -E 's/(iran|kharej)([0-9]+)\.toml/\2/')
        local service_type=$(basename "$config_path" | sed -E 's/(iran|kharej)[0-9]+\.toml/\1/')
        cat << EOF > "/etc/systemd/system/$service_name"
[Unit]
Description=Backhaul $service_type Port $tunnel_port ($service_type)
After=network.target

[Service]
Type=simple
ExecStart=${config_dir}/backhaul -c $config_path
Restart=always
RestartSec=3
User=backhaul
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

        # Reload systemd and enable the service
        systemctl daemon-reload
        systemctl enable --now "$service_name"
    fi

    # Check if the service is running
    if ! systemctl is-active --quiet "$service_name"; then
        colorize red "Service $service_name is not running. Attempting to restart it..." bold
        systemctl restart "$service_name"

        # Check again after restart
        if systemctl is-active --quiet "$service_name"; then
            colorize green "Service $service_name restarted successfully." bold
        else
            colorize red "Failed to restart service $service_name. Please check the logs." bold
            journalctl -u "$service_name" --no-pager | tail -n 20
        fi
    else
        colorize green "Service $service_name is running." bold
    fi
}

# Function for destroying tunnel
tunnel_management() {
	echo
	# Check for .toml files
	if ! ls "$config_dir"/*.toml 1> /dev/null 2>&1; then
	    colorize red "No config files found in the Backhaul directory." bold
	    echo 
	    press_key
	    return 1
	fi
	
	clear
	colorize cyan "List of existing services to manage:" bold
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
            echo -e "${MAGENTA}${index}${NC}) ${GREEN}Iran${NC} service, Tunnel port: ${YELLOW}$config_port${NC}"
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
            echo -e "${MAGENTA}${index}${NC}) ${GREEN}Kharej${NC} service, Tunnel port: ${YELLOW}$config_port${NC}"
            ((index++))
        fi
    done
    
    echo
    colorize cyan "Additional options:" bold
    colorize yellow "R) Restore a backup" bold
    echo
	echo -ne "Enter your choice (0 to return): "
    read choice 
	
	# Check if the user chose to return
	if (( choice == 0 )); then
	    return
	fi
	#  validation
	while ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 0 || choice > ${#configs[@]} )); do
	    colorize red "Invalid choice. Please enter a number between 1 and ${#configs[@]}." bold
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
	colorize cyan "List of available commands for $config_name:" bold
	echo 
	colorize red "1) Remove this tunnel"
	colorize yellow "2) Restart this tunnel"
	colorize reset "3) View service logs"
    colorize reset "4) View service status"
	colorize red "0) Back to Main Menu" bold
	echo 
	read -p "Enter your choice (0 to return): " choice
	
    case $choice in
        1) destroy_tunnel "$selected_config" ;;
        2) restart_service "$service_name" ;;
        3) view_service_logs "$service_name" ;;
        4) view_service_status "$service_name" ;;
        R|r) restore_backup ;;
        0) return 1 ;;
        *) echo -e "${RED}Invalid option!${NC}" && sleep 1 && return 1;;
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
        echo -e "${RED}Failed to reload systemd daemon. Please check your system configuration.${NC}"
    fi
    
    colorize green "Tunnel destroyed successfully!" bold
    echo
    press_key
}


#Function to restart services
restart_service() {
    echo
    service_name="$1"
    colorize yellow "Restarting $service_name" bold
    echo

    # Check if service exists
    if systemctl list-units --type=service | grep -q "$service_name"; then
        if systemctl restart "$service_name"; then
            colorize green "Service restarted successfully" bold
        else
            colorize red "Failed to restart the service. Please check the service logs."
        fi
    else
        colorize red "Service $service_name does not exist."
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

check_core_version() {
    local url=$1
    local tmp_file=$(mktemp)

    # Download the file to a temporary location
    curl -s -o "$tmp_file" "$url"

    # Check if the download was successful
    if [ $? -ne 0 ]; then
        colorize red "Failed to check latest core version"
        return 1
    fi

    # Read the version from the downloaded file (assumes the version is stored on the first line)
    local file_version=$(head -n 1 "$tmp_file")

    # Get the version from the backhaul binary using the -v flag
    local backhaul_version=$($config_dir/backhaul -v)

    # Compare the file version with the version from backhaul
    if [ "$file_version" != "$backhaul_version" ]; then
        colorize cyan "New Core version available: $backhaul_version => $file_version" bold
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
        colorize red "Failed to check latest script version"
        return 1
    fi

    # Read the version from the downloaded file (assumes the version is stored on the first line)
    local file_version=$(head -n 1 "$tmp_file")

    # Compare the file version with the version from backhaul
    if [ "$file_version" != "$SCRIPT_VERSION" ]; then
        colorize cyan "New script version available: $SCRIPT_VERSION => $file_version" bold
    fi

    # Clean up the temporary file
    rm "$tmp_file"
}


update_script(){
# Define the destination path
DEST_DIR="/usr/bin/"
BACKHAUL_SCRIPT="backhaul"
SCRIPT_URL="https://raw.githubusercontent.com/iPmartNetwork/Backhaul/refs/heads/master/backhaul.sh"

echo
# Check if backhaul.sh exists in /bin/bash
if [ -f "$DEST_DIR/$BACKHAUL_SCRIPT" ]; then
    # Remove the existing rathole
    rm "$DEST_DIR/$BACKHAUL_SCRIPT"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Existing $BACKHAUL_SCRIPT has been successfully removed from $DEST_DIR.${NC}"
    else
        echo -e "${RED}Failed to remove existing $BACKHAUL_SCRIPT from $DEST_DIR.${NC}"
        sleep 1
        return 1
    fi
else
    echo -e "${YELLOW}$BACKHAUL_SCRIPT does not exist in $DEST_DIR. No need to remove.${NC}"
fi

# Download the new backhaul.sh from the GitHub URL
curl -s -L -o "$DEST_DIR/$BACKHAUL_SCRIPT" "$SCRIPT_URL"

echo
if [ $? -eq 0 ]; then
    chmod +x "$DEST_DIR/$BACKHAUL_SCRIPT"
    colorize yellow "Type 'backhaul' to run the script.\n" bold
    colorize yellow "For removing script type: rm -rf /usr/bin/backhaul\n" bold
    press_key
    exit 0
else
    echo -e "${RED}Failed to download $BACKHAUL_SCRIPT from $SCRIPT_URL.${NC}"
    sleep 1
    return 1
fi

}

# Function to create a backup of a TOML file
backup_toml() {
    local file_path="$1"
    local backup_dir="${config_dir}/backups"
    local timestamp=$(date +"%Y%m%d%H%M%S")
    local backup_file="${backup_dir}/$(basename "$file_path").${timestamp}.bak"

    mkdir -p "$backup_dir"
    cp "$file_path" "$backup_file"
    colorize green "Backup created: $backup_file" bold
}

# Function to restore a backup
restore_backup() {
    local backup_dir="${config_dir}/backups"
    if [[ ! -d "$backup_dir" ]]; then
        colorize red "No backups found." bold
        return 1
    fi

    echo
    colorize cyan "Available backups:" bold
    ls -1 "$backup_dir" | nl
    echo
    read -p "Enter the number of the backup to restore (or 0 to cancel): " choice

    if [[ "$choice" -eq 0 ]]; then
        colorize yellow "Restore canceled." bold
        return 0
    fi

    local selected_backup=$(ls -1 "$backup_dir" | sed -n "${choice}p")
    if [[ -z "$selected_backup" ]]; then
        colorize red "Invalid choice." bold
        return 1
    fi

    local original_file="${config_dir}/$(basename "$selected_backup" | sed 's/\.[0-9]\{14\}\.bak$//')"
    cp "${backup_dir}/${selected_backup}" "$original_file"
    colorize green "Backup restored: $original_file" bold
}

# Function to handle core manager menu
core_manager_menu() {
    clear
    colorize cyan "Core Manager Menu" bold
    echo
    colorize cyan " 1. Install Backhaul Core" bold
    colorize cyan " 2. Update Backhaul Core" bold
    colorize cyan " 3. Remove Backhaul Core" bold
    colorize red " 0. Back to Main Menu" bold
    echo
    echo "-------------------------------"
    read -p "Enter your choice [0-3]: " core_choice
    case $core_choice in
        1) install_core ;;
        2) update_core ;;
        3) remove_core ;;
        0) return ;;
        *) echo -e "${RED} Invalid option!${NC}" && sleep 1 ;;
    esac
}

# Function to install Backhaul Core
install_core() {
    clear
    colorize cyan "Installing Backhaul Core..." bold
    echo
    download_and_extract_backhaul
    if [[ -f "${config_dir}/backhaul" ]]; then
        colorize green "Backhaul Core installed successfully." bold
    else
        colorize red "Failed to install Backhaul Core. Please check the logs." bold
    fi
    press_key
}

# Function to update Backhaul Core
update_core() {
    clear
    colorize cyan "Updating Backhaul Core..." bold
    echo
    download_and_extract_backhaul "menu"
    if [[ -f "${config_dir}/backhaul" ]]; then
        colorize green "Backhaul Core updated successfully." bold
    else
        colorize red "Failed to update Backhaul Core. Please check the logs." bold
    fi
    press_key
}

# Function to remove Backhaul Core
remove_core() {
    clear
    colorize cyan "Removing Backhaul Core..." bold
    echo
    if [[ -d "$config_dir" ]]; then
        rm -rf "$config_dir"
        colorize green "Backhaul Core removed successfully." bold
    else
        colorize red "Backhaul Core is not installed." bold
    fi
    press_key
}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\e[36m'
MAGENTA="\e[95m"
NC='\033[0m' # No Color

# Add a function to display the script version
display_script_version() {
    echo
    colorize cyan "Backhaul Script Version: ${SCRIPT_VERSION}" bold
    echo
}

# Function to display menu
display_menu() {
    clear
    display_logo
    display_server_info
    display_backhaul_core_status
    display_script_version  # Added to display the script version
    echo
    colorize cyan " 1. Configure a new tunnel [IPv4/IPv6]" bold
    colorize cyan " 2. Tunnel management menu" bold
    colorize cyan " 3. Check tunnels status" bold
    colorize cyan " 4. Core Manager" bold  # Added Core Manager option
    colorize cyan " 5. Web Panel" bold
    colorize red " 0. Exit" bold
    echo
    echo "-------------------------------"
}

# Function to handle web panel
web_panel() {
    clear
    colorize cyan "Web Panel Menu" bold
    echo
    colorize cyan " 1. Install Web Panel" bold
    colorize cyan " 2. Remove Web Panel" bold
    colorize red " 0. Back to Main Menu" bold
    echo
    echo "-------------------------------"
    read -p "Enter your choice [0-2]: " web_choice
    case $web_choice in
        1) install_web_panel ;;
        2) remove_web_panel ;;
        0) return ;;
        *) echo -e "${RED} Invalid option!${NC}" && sleep 1 ;;
    esac
}

# Function to install web panel
install_web_panel() {
    clear
    colorize cyan "Installing Advanced Web Panel with Authentication, TLS, and Real-Time Updates..." bold
    echo

    # Install necessary packages
    if ! command -v python3 &> /dev/null; then
        colorize yellow "Installing Python3..." bold
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip
    fi

    # Install Flask, Flask-Cors, Flask-HTTPAuth, Flask-SocketIO, and psutil
    if ! python3 -m pip show flask &> /dev/null; then
        colorize yellow "Installing Flask, Flask-Cors, Flask-HTTPAuth, Flask-SocketIO, and psutil..." bold
        python3 -m pip install flask flask-cors flask-httpauth flask-socketio psutil
    fi

    # Create web panel directory
    local web_panel_dir="/var/www/backhaul-panel"
    sudo mkdir -p "$web_panel_dir"

    # Generate self-signed TLS certificate
    local cert_dir="/etc/backhaul-panel"
    sudo mkdir -p "$cert_dir"
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$cert_dir/server.key" \
        -out "$cert_dir/server.crt" \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost"

    # Create HTML and API files
    echo "Creating Advanced Web Panel files..."
    sudo bash -c "cat > $web_panel_dir/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Backhaul Advanced Web Panel</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f4f4f9; color: #333; }
        h1 { color: #4CAF50; text-align: center; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; background: #fff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); }
        button { padding: 10px 20px; background-color: #4CAF50; color: white; border: none; cursor: pointer; border-radius: 4px; }
        button:hover { background-color: #45a049; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        pre { background: #f4f4f9; padding: 10px; border-radius: 4px; overflow-x: auto; }
        .metrics, .logs { margin-top: 20px; }
    </style>
    <script src="https://cdn.socket.io/4.0.0/socket.io.min.js"></script>
</head>
<body>
    <div class="container">
        <h1>Backhaul Advanced Web Panel</h1>
        <button onclick="fetchStatus()">Check Tunnel Status</button>
        <button onclick="fetchMetrics()">View Metrics</button>
        <button onclick="fetchLogs()">View Logs</button>
        <table id="tunnelTable">
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Port</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody></tbody>
        </table>
        <div class="metrics">
            <h2>Metrics</h2>
            <pre id="metricsOutput"></pre>
        </div>
        <div class="logs">
            <h2>Logs</h2>
            <pre id="logsOutput"></pre>
        </div>
    </div>
    <script>
        const username = prompt("Enter username:");
        const password = prompt("Enter password:");
        const headers = new Headers({
            "Authorization": "Basic " + btoa(`${username}:${password}`)
        });

        async function fetchStatus() {
            const response = await fetch('/api/status', { headers });
            const data = await response.json();
            const tableBody = document.querySelector('#tunnelTable tbody');
            tableBody.innerHTML = '';
            data.tunnels.forEach(tunnel => {
                const row = document.createElement('tr');
                row.innerHTML = `<td>${tunnel.name}</td><td>${tunnel.port}</td><td>${tunnel.status}</td>`;
                tableBody.appendChild(row);
            });
        }

        async function fetchMetrics() {
            const response = await fetch('/api/metrics', { headers });
            const data = await response.json();
            document.getElementById('metricsOutput').textContent = JSON.stringify(data, null, 2);
        }

        async function fetchLogs() {
            const response = await fetch('/api/logs', { headers });
            const data = await response.json();
            document.getElementById('logsOutput').textContent = data.logs.join('\n');
        }

        const socket = io();
        socket.on('log_update', (log) => {
            const logsOutput = document.getElementById('logsOutput');
            logsOutput.textContent += `\n${log}`;
        });
    </script>
</body>
</html>
EOF

    sudo bash -c "cat > $web_panel_dir/api.py" << 'EOF'
from flask import Flask, jsonify
from flask_cors import CORS
from flask_httpauth import HTTPBasicAuth
from werkzeug.security import generate_password_hash, check_password_hash
from flask_socketio import SocketIO, emit
import psutil
import threading
import time

app = Flask(__name__)
CORS(app)
auth = HTTPBasicAuth()
socketio = SocketIO(app)

# User credentials
users = {
    "admin": generate_password_hash("password123")
}

@auth.verify_password
def verify_password(username, password):
    if username in users and check_password_hash(users.get(username), password):
        return username

@app.route('/api/status', methods=['GET'])
@auth.login_required
def status():
    return jsonify({
        "status": "running",
        "tunnels": [
            {"name": "Tunnel 1", "port": 8080, "status": "active"},
            {"name": "Tunnel 2", "port": 9090, "status": "inactive"}
        ]
    })

@app.route('/api/metrics', methods=['GET'])
@auth.login_required
def metrics():
    metrics_data = {
        "cpu_usage": psutil.cpu_percent(interval=1),
        "memory": psutil.virtual_memory()._asdict(),
        "disk": psutil.disk_usage('/')._asdict(),
        "network": psutil.net_io_counters()._asdict()
    }
    return jsonify(metrics_data)

@app.route('/api/logs', methods=['GET'])
@auth.login_required
def logs():
    return jsonify({"logs": log_buffer})

log_buffer = []

def generate_logs():
    while True:
        log = f"Log entry at {time.strftime('%Y-%m-%d %H:%M:%S')}"
        log_buffer.append(log)
        if len(log_buffer) > 100:
            log_buffer.pop(0)
        socketio.emit('log_update', log)
        time.sleep(5)

if __name__ == '__main__':
    threading.Thread(target=generate_logs, daemon=True).start()
    socketio.run(app, host='0.0.0.0', port=22490, ssl_context=('/etc/backhaul-panel/server.crt', '/etc/backhaul-panel/server.key'))
EOF

    # Create systemd service for the web panel
    echo "Creating systemd service for Advanced Web Panel..."
    sudo bash -c "cat > /etc/systemd/system/backhaul-web-panel.service" << EOF
[Unit]
Description=Backhaul Advanced Web Panel
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $web_panel_dir/api.py
Restart=always
User=backhaul
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

    # Start and enable the web panel service
    sudo systemctl daemon-reload
    sudo systemctl enable --now backhaul-web-panel.service

    colorize green "Advanced Web Panel installed with TLS, authentication, and real-time updates. Access it at: https://localhost:22490" bold
    press_key
}

# Function to remove web panel
remove_web_panel() {
    clear
    colorize cyan "Removing Web Panel..." bold
    echo

    # Stop and disable the web panel service
    sudo systemctl stop backhaul-web-panel.service
    sudo systemctl disable backhaul-web-panel.service

    # Remove files and service
    sudo rm -rf /var/www/backhaul-panel
    sudo rm -f /etc/systemd/system/backhaul-web-panel.service

    # Reload systemd
    sudo systemctl daemon-reload

    colorize green "Web Panel removed successfully." bold
    press_key
}

# Function to read user input
read_option() {
    read -p "Enter your choice [0-5]: " choice
    case $choice in
        1) configure_tunnel ;;
        2) tunnel_management ;;
        3) check_tunnel_status ;;
        4) core_manager_menu ;;
        5) web_panel ;;
        0) exit 0 ;;
        *) echo -e "${RED} Invalid option!${NC}" && sleep 1 ;;
    esac
}

# Main script loop
while true; do
    display_menu
    read_option
done
