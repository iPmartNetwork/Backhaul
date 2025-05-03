#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

# Define script version
SCRIPT_VERSION="v0.6.0"

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
    # Select color code
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
    # Select style code
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
        rm -rf "${config_dir}/backhaul_premium" >/dev/null 2>&1
        echo
        colorize cyan "Restart all services after updating to new core" bold
        sleep 2
    fi
    
    # Check if Backhaul Core is already installed
    if [[ -f "${config_dir}/backhaul_premium" ]]; then
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
            DOWNLOAD_URL="https://raw.githubusercontent.com/wafflenoodle/zenith-stash/refs/heads/main/backhaul_amd64.tar.gz"
    arm64|aarch64)
            DOWNLOAD_URL="https://raw.githubusercontent.com/wafflenoodle/zenith-stash/refs/heads/main/backhaul_arm64.tar.gz"
    *)
            echo -e "${RED}Unsupported architecture: $ARCH.${NC}"
            sleep 1
            exit 1
esac

    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${RED}Failed to retrieve download URL.${NC}"
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
    echo -e "${GREEN}Backhaul installation completed.${NC}\n"
    chmod u+x "${config_dir}/backhaul_premium"
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
SERVER_ISP=$(curl -sS --max-time 2 "http://ipwhois.app/json/$SERVER_IP" | jq -r '.isp')


# Function to display ASCII logo
display_logo() {   
    echo -e "${CYAN}"
    cat << "EOF"
 ____  ____  ____  _  __ _     ____  _     _    
/  _ \/  _ \/   _\/ |/ // \ /|/  _ \/ \ /\/ \   
| | //| / \||  /  |   / | |_||| / \|| | ||| |   
| |_\\| |-|||  \_ |   \ | | ||| |-||| \_/|| |_/\
\____/\_/ \|\____/\_|\_\\_/ \|\_/ \|\____/\____/
                                                
   Lightning-fast reverse tunneling solution
EOF
    echo -e "${NC}${GREEN}"
    echo -e "Script Version: ${YELLOW}${SCRIPT_VERSION}${GREEN}"
    if [[ -f "${config_dir}/backhaul_premium" ]]; then
    	if [[ -x "${config_dir}/backhaul_premium" ]]; then
    echo -e "Core Version: ${YELLOW}$(${config_dir}/backhaul_premium -v)${GREEN}"
fi
    fi
    echo -e "Telegram Channel: ${YELLOW}@anony_identity${NC}"
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
    if [[ -f "${config_dir}/backhaul_premium" ]]; then
        echo -e "${CYAN}Backhaul Core:${NC} ${GREEN}Installed${NC}"
    else
        echo -e "${CYAN}Backhaul Core:${NC} ${RED}Not installed${NC}"
    fi
    echo -e "\e[93m═══════════════════════════════════════════\e[0m"  
}

# Function to check if a given string is a valid IPv6 address
check_ipv6() {
    local ip=$1
    # Define the IPv6 regex pattern
    ipv6_pattern="^([0-9a-fA-F]{1,4}:){7}([0-9a-fA-F]{1,4}|:)$|^(([0-9a-fA-F]{1,4}:){1,7}|:):((:[0-9a-fA-F]{1,4}){1,7}|:)$"
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
    echo -e "\n${RED}Backhaul-Core directory not found. Install it first through 'Install Backhaul core' option.${NC}\n"
    read -p "Press Enter to continue..."
    return 1
fi

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
    while [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; do
        echo -ne "[*] Transport type (tcp/tcpmux/utcpmux/ws/wsmux/uwsmux/udp/tcptun/faketcptun): "
        read -r transport

        if [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; then
            colorize red "Invalid transport type. Please choose from tcp, tcpmux, utcpmux, ws, wsmux, uwsmux, udp, tcptun, faketcptun."
            echo
        fi
    done

    echo

    # TUN Device Name 
    local tun_name="backhaul"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
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
                colorize red "Please enter a valid TUN device name."
                echo
            fi
        done
    fi

    # TUN Subnet
    local tun_subnet="10.10.10.0/24"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
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

            colorize red "Please enter a valid subnet in CIDR notation (e.g., 10.10.10.0/24)."
            echo
        done
    fi

    # TUN MTU
    local mtu="1500"    
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
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

            colorize red "Please enter a valid MTU value between 576 and 9000."
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
        # Display port format options
        colorize green "[*] Supported Port Formats:" bold
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
	        colorize red "[ERROR] Invalid port mapping: $port. Skipping."
	        echo
	    fi
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
ExecStart=${config_dir}/backhaul_premium -c ${config_dir}/iran${tunnel_port}.toml
Restart=always
RestartSec=3

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
    while [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; do
        echo -ne "[*] Transport type (tcp/tcpmux/utcpmux/ws/wsmux/uwsmux/udp/tcptun/faketcptun): "
        read -r transport

        if [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; then
            colorize red "Invalid transport type. Please choose from tcp, tcpmux, utcpmux, ws, wsmux, uwsmux, udp, tcptun, faketcptun."
            echo
        fi
    done

    # TUN Device Name 
    local tun_name="backhaul"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
        echo
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
                colorize red "Please enter a valid TUN device name."
                echo
            fi
        done
    fi

    # TUN Subnet
    local tun_subnet="10.10.10.0/24"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
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

            colorize red "Please enter a valid subnet in CIDR notation (e.g., 10.10.10.0/24)."
            echo
        done
    fi

    # TUN MTU
    local mtu="1500"    
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
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

            colorize red "Please enter a valid MTU value between 576 and 9000."
            echo
        done
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
        echo
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
ExecStart=${config_dir}/backhaul_premium -c ${config_dir}/kharej${tunnel_port}.toml
Restart=always
RestartSec=3

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
    for config_path in "$config_dir"/iran*.toml; do
        if [ -f "$config_path" ]; then
            # Extract config_name without directory path and change it to service name
			config_name=$(basename "$config_path")
			config_name="${config_name%.toml}"
			service_name="backhaul-${config_name}.service"
            config_port="${config_name#iran}"
            
			# Check if the Backhaul-client-kharej service is active
			if systemctl is-active --quiet "$service_name"; then
				colorize green "Iran service with tunnel port $config_port is running"
			else
				colorize red "Iran service with tunnel port $config_port is not running"
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
				colorize green "Kharej service with tunnel port $config_port is running"
			else
				colorize red "Kharej service with tunnel port $config_port is not running"
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
	echo -ne "Enter your choice (0 to return): "
    read -r choice 
	
	# Check if the user chose to return
	if (( choice == 0 )); then
	    return
	fi
	#  validation
	while ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 0 || choice > ${#configs[@]} )); do
	    colorize red "Invalid choice. Please enter a number between 1 and ${#configs[@]}." bold
	    echo
	    echo -ne "Enter your choice (0 to return): "
	    read -r choice
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
	colorize white "3) View service logs"
    colorize white "4) View service status"
	echo 
	read -p "Enter your choice (0 to return): " choice
	
    case $choice in
        1) destroy_tunnel "$selected_config" ;;
        2) restart_service "$service_name" ;;
        3) view_service_logs "$service_name" ;;
        4) view_service_status "$service_name" ;;
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
    # Reload systemd to read -r the new unit file
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
        systemctl restart "$service_name"
        colorize green "Service restarted successfully" bold

    else
        colorize red "Cannot restart the service" 
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




}

#!/bin/bash



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

    # Get the version from the backhaul_premium binary using the -v flag
    local backhaul_version=$($config_dir/backhaul_premium -v)

    # Compare the file version with the version from backhaul_premium
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

    # Compare the file version with the version from backhaul_premium
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
SCRIPT_URL="https://raw.githubusercontent.com/wafflenoodle/zenith-stash/refs/heads/main/backhaul.sh"

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

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

display_menu() {
    colorize cyan " 1 ) Core manager"
    colorize cyan " 2) Configure a new tunnel [IPv4/IPv6]" bold
    colorize cyan   " 3) Tunnel management menu" bold
    colorize cyan  " 4) Check tunnels status" bold
    colorize cyan " 5) Web Service"
    colorize cyan " 6) Update Script"
    colorize YELLOW " 0. Exit"
    echo
    echo "-------------------------------"
}

read_option() {
    read -p "Enter your choice [0-6]: " choice
    case $choice in
        2) configure_tunnel ;;
        3) tunnel_management ;;
        4) check_tunnel_status ;;
        1) download_and_extract_backhaul "menu";;
        6) update_script ;;
        0) exit 0 ;;
        *) echo -e "${RED} Invalid option!${NC}" && sleep 1 ;;
    esac
}

# Main script
while true
do
    display_menu
    read_option
done
