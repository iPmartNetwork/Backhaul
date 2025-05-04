#!/bin/bash

# Define script version
SCRIPT_VERSION="v2.2.4"

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   sleep 1
   exit 1
fi

# just press key to continue
press_key() {
    echo -n "Press any key to continue..."
    read -r -n 1
    echo
}

# Define a function to colorize text
colorize() {
    local color="$1"
    local text="$2"
    local style="${3:-normal}"
    
    # Define ANSI color codes
    local turquoise="\033[36m"  # Updated to turquoise
    local reset="\033[0m"
    
    # Define ANSI style codes
    local normal="\033[0m"
    local bold="\033[1m"
    local underline="\033[4m"
    # Select color code
    local color_code
    case $color in
        turquoise) color_code=$turquoise ;;  # Updated to turquoise
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
        colorize turquoise "Restart all services after updating to new core" bold
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
            ;;
        arm64|aarch64)
            DOWNLOAD_URL="https://raw.githubusercontent.com/wafflenoodle/zenith-stash/refs/heads/main/backhaul_arm64.tar.gz"
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
fetch_data() {
    local url=$1
    local output
    output=$(curl -sS --max-time 5 "$url")
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url"
        return 1
    fi
    echo "$output"
}

SERVER_COUNTRY=$(fetch_data "http://ipwhois.app/json/$SERVER_IP" | jq -r '.country')

# Fetch server isp 
SERVER_ISP=$(fetch_data "http://ipwhois.app/json/$SERVER_IP" | jq -r '.isp')


# Function to display ASCII logo
display_logo() {   
    echo -e "\033[36m"  # Updated to turquoise
    cat << "EOF"
____________________________________________________________________________________
        ____                             _     _                                     
    ,   /    )                           /|   /                                  /   
-------/____/---_--_----__---)__--_/_---/-| -/-----__--_/_-----------__---)__---/-__-
  /   /        / /  ) /   ) /   ) /    /  | /    /___) /   | /| /  /   ) /   ) /(    
_/___/________/_/__/_(___(_/_____(_ __/___|/____(___ _(_ __|/_|/__(___/_/_____/___\__
____________________________________________________________________________________                                                                                     

             Lightning-fast reverse tunneling solution
EOF
    echo -e "\033[0m\033[36m"  # Updated to turquoise
    echo -e "Script Version: \033[36m${SCRIPT_VERSION}\033[36m"  # Updated to turquoise
    if [[ -f "${config_dir}/backhaul_premium" ]]; then
    	echo -e "Core Version: \033[36m$($config_dir/backhaul_premium -v)\033[36m"  # Updated to turquoise
    fi
    echo -e "Telegram Channel: \033[36m@iPmartch\033[0m"  # Updated to turquoise
}

# Function to display server location and IP
display_server_info() {
    echo -e "\033[36m═══════════════════════════════════════════\033[0m"  # Updated to turquoise
 
    echo -e "\033[36mIP Address:\033[0m $SERVER_IP"  # Updated to turquoise
    echo -e "\033[36mLocation:\033[0m $SERVER_COUNTRY "  # Updated to turquoise
    echo -e "\033[36mDatacenter:\033[0m $SERVER_ISP"  # Updated to turquoise
}

# Function to display Backhaul Core installation status
display_backhaul_core_status() {
    if [[ -f "${config_dir}/backhaul_premium" ]]; then
        echo -e "\033[36mBackhaul Core:\033[0m \033[36mInstalled\033[0m"  # Updated to turquoise
    else
        echo -e "\033[36mBackhaul Core:\033[0m \033[36mNot installed\033[0m"  # Updated to turquoise
    fi
    echo -e "\033[36m═══════════════════════════════════════════\033[0m"  # Updated to turquoise
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
        ss -tln | grep -q ":$PORT"
    elif [[ "$TRANSPORT" == "udp" ]]; then
        ss -uln | grep -q ":$PORT"
    else
        echo "Invalid transport type: $TRANSPORT"
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
    colorize turquoise "1) Configure for IRAN server" bold
    colorize turquoise "2) Configure for KHAREJ server" bold
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
    colorize turquoise "Configuring IRAN server" bold

    echo

    # Tunnel Port
    while true; do
        echo -ne "[*] Tunnel port: "
        read -r tunnel_port
        if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; then
            if check_port "$tunnel_port" "tcp"; then
                colorize turquoise "Port $tunnel_port is in use."
            else
                break
            fi
        else
            colorize turquoise "Please enter a valid port number between 23 and 65535."
        fi
    done

    echo

    # Transport Type
    local transport=""
    while [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; do
        echo -ne "[*] Transport type (tcp/tcpmux/utcpmux/ws/wsmux/uwsmux/udp/tcptun/faketcptun): "
        read -r transport
        if [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; then
            colorize turquoise "Invalid transport type. Please choose a valid option."
        fi
    done

    echo

    # TUN Device Name
    local tun_name="backhaul"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
        while true; do
            echo -ne "[-] TUN Device Name (default backhaul): "
            read -r tun_name
            tun_name="${tun_name:-backhaul}"
            if [[ "$tun_name" =~ ^[a-zA-Z0-9]+$ ]]; then
                break
            else
                colorize turquoise "Please enter a valid TUN device name."
            fi
        done
    fi

    # TUN Subnet
    local tun_subnet="10.10.10.0/24"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
        while true; do
            echo -ne "[-] TUN Subnet (default 10.10.10.0/24): "
            read -r tun_subnet
            tun_subnet="${tun_subnet:-10.10.10.0/24}"
            if [[ "$tun_subnet" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then
                break
            else
                colorize turquoise "Please enter a valid subnet in CIDR notation (e.g., 10.10.10.0/24)."
            fi
        done
    fi

    # TUN MTU
    local mtu="1500"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
        while true; do
            echo -ne "[-] TUN MTU (default 1500): "
            read -r mtu
            mtu="${mtu:-1500}"
            if [[ "$mtu" =~ ^[0-9]+$ ]] && [ "$mtu" -ge 576 ] && [ "$mtu" -le 9000 ]; then
                break
            else
                colorize turquoise "Please enter a valid MTU value between 576 and 9000."
            fi
        done
    fi

    # Accept UDP
    local accept_udp="false"
    if [[ "$transport" == "tcp" ]]; then
        while [[ "$accept_udp" != "true" && "$accept_udp" != "false" ]]; do
            echo -ne "[-] Accept UDP connections over TCP transport (true/false)(default false): "
            read -r accept_udp
            accept_udp="${accept_udp:-false}"
        done
    fi

    # Channel Size
    local channel_size="2048"
    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then
        while true; do
            echo -ne "[-] Channel Size (default 2048): "
            read -r channel_size
            channel_size="${channel_size:-2048}"
            if [[ "$channel_size" =~ ^[0-9]+$ ]] && [ "$channel_size" -gt 64 ] && [ "$channel_size" -le 8192 ]; then
                break
            else
                colorize turquoise "Please enter a valid channel size between 64 and 8192."
            fi
        done
    fi

    # Generate Configuration
    cat << EOF > "${config_dir}/iran${tunnel_port}.toml"
[server]
bind_addr = ":${tunnel_port}"
transport = "${transport}"
accept_udp = ${accept_udp}
token = "your_token"
keepalive_period = 75
nodelay = true
channel_size = ${channel_size}
heartbeat = 40
mux_con = 8
mux_version = 2
mux_framesize = 32768
mux_recievebuffer = 4194304
mux_streambuffer = 2000000
tun_name = "${tun_name}"
tun_subnet = "${tun_subnet}"
mtu = ${mtu}
EOF

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
    colorize cyan "Additional options:" bold
    colorize yellow "R) Restore a backup" bold
    colorize red "0) Back to Main Menu" bold
    echo
    echo -ne "Enter your choice (0 to return): "
    read choice 
	
	# Check if the user chose to return
	if [[ "$choice" == "0" ]]; then
	    return
	fi
	#  validation
	while ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 0 || choice > ${#configs[@]} )); do
	    colorize red "Invalid choice. Please enter a number between 1 and ${#configs[@]}." bold
	    echo
	    echo -ne "Enter your choice (0 to return): "
	    read choice
		if [[ "$choice" == "0" ]]; then
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
        0) return ;;
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

# Function to start the web panel
start_web_panel() {
    local dashboard_dir="/var/www/backhaul-dashboard"
    mkdir -p "$dashboard_dir"
    cat << EOF > "$dashboard_dir/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Backhaul Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; border: 1px solid #ddd; text-align: left; }
        th { background-color: #f4f4f4; }
    </style>
</head>
<body>
    <h1>Backhaul Dashboard</h1>
    <p>Welcome to the Backhaul Web Panel. Use the menu below to manage tunnels.</p>
    <table>
        <thead>
            <tr>
                <th>Action</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><button onclick="alert('Start Tunnel')">Start Tunnel</button></td>
                <td>Start a new tunnel configuration.</td>
            </tr>
            <tr>
                <td><button onclick="alert('Stop Tunnel')">Stop Tunnel</button></td>
                <td>Stop an existing tunnel.</td>
            </tr>
        </tbody>
    </table>
</body>
</html>
EOF

    echo -e "\nStarting web panel on port 8080..."
    python3 -m http.server 8080 --directory "$dashboard_dir" >/dev/null 2>&1 &
    echo "Web panel started. Access it at http://localhost:8080"
}

# Function to stop the web panel
stop_web_panel() {
    local pid
    pid=$(ps aux | grep "[h]ttp.server" | awk '{print $2}')
    if [[ -n "$pid" ]]; then
        kill "$pid"
        echo "Web panel stopped."
    else
        echo "Web panel is not running."
    fi
}

# Function to install the web panel
install_web_panel() {
    local dashboard_dir="/var/www/backhaul-dashboard"
    local service_file="/etc/systemd/system/backhaul-web-panel.service"
    local port=22490

    # Prompt user for custom port
    echo -ne "Enter the port for the web panel (default is 22490): "
    read -r input_port
    if [[ "$input_port" =~ ^[0-9]+$ ]] && [ "$input_port" -ge 1024 ] && [ "$input_port" -le 65535 ]; then
        port="$input_port"
    else
        echo "Using default port: $port"
    fi

    # Prompt user for custom directory
    echo -ne "Enter the directory for the web panel files (default is /var/www/backhaul-dashboard): "
    read -r input_dir
    if [[ -n "$input_dir" ]]; then
        dashboard_dir="$input_dir"
    fi

    # Create the dashboard directory
    mkdir -p "$dashboard_dir"

    # Create a simple HTML file for the web panel
    cat << EOF > "$dashboard_dir/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Backhaul Web Panel</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        p { color: #555; }
    </style>
</head>
<body>
    <h1>Welcome to Backhaul Web Panel</h1>
    <p>Manage your tunnels and configurations from this web interface.</p>
</body>
</html>
EOF

    # Create a systemd service file for the web panel
    cat << EOF > "$service_file"
[Unit]
Description=Backhaul Web Panel
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server $port --directory $dashboard_dir
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd, enable, and start the web panel service
    systemctl daemon-reload
    systemctl enable --now backhaul-web-panel.service

    echo "Web panel installed and started. Access it at http://<your-server-ip>:$port"
}

# Function to manage the web panel service
manage_web_panel() {
    echo -e "\n\e[1;36mWeb Panel Management Options:\e[0m"
    echo -e " \e[1;32m[1]\e[0m Start Web Panel"
    echo -e " \e[1;31m[2]\e[0m Stop Web Panel"
    echo -e " \e[1;33m[3]\e[0m Restart Web Panel"
    echo -e " \e[1;34m[4]\e[0m View Web Panel Status"
    echo -e " \e[1;31m[0]\e[0m Back to Main Menu"
    read -p "Enter your choice [0-4]: " panel_choice
    case $panel_choice in
        1) systemctl start backhaul-web-panel.service && echo "Web panel started." ;;
        2) systemctl stop backhaul-web-panel.service && echo "Web panel stopped." ;;
        3) systemctl restart backhaul-web-panel.service && echo "Web panel restarted." ;;
        4) systemctl status backhaul-web-panel.service ;;
        0) return ;;
        *) echo -e "\e[1;31mInvalid option! Please try again.\e[0m" && sleep 1 ;;
    esac
}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\e[36m'
MAGENTA="\e[95m"
NC='\033[0m' # No Color

# Function to display menu
display_menu() {
    clear
    display_logo
    display_server_info
    display_backhaul_core_status
    
    echo
    echo -e "\e[93m═══════════════════════════════════════════════════════════════════════\e[0m"
    echo -e " \e[1;36mMAIN MENU\e[0m"
    echo -e "\e[93m═══════════════════════════════════════════════════════════════════════\e[0m"
    echo -e " \e[1;32m[1]\e[0m \e[1;37mConfigure a new tunnel [IPv4/IPv6]\e[0m"
    echo -e " \e[1;33m[2]\e[0m \e[1;37mConfigure multiple tunnels\e[0m"
    echo -e " \e[1;31m[3]\e[0m \e[1;37mTunnel management menu\e[0m"
    echo -e " \e[1;36m[4]\e[0m \e[1;37mCheck tunnels status\e[0m"
    echo -e " \e[1;33m[5]\e[0m \e[1;37mAdvanced Options\e[0m"
    echo -e " \e[1;35m[6]\e[0m \e[1;37mCore Manager\e[0m"
    echo -e " \e[1;34m[7]\e[0m \e[1;37mUpdate & Install Script\e[0m"
    echo -e " \e[1;36m[8]\e[0m \e[1;37mWeb Panel Manager\e[0m"
    echo -e " \e[1;31m[0]\e[0m \e[1;37mExit\e[0m"
    echo -e "\e[93m═══════════════════════════════════════════════════════════════════════\e[0m"
}

# Function to handle core manager options
handle_core_manager() {
    while true; do
        echo -e "\n\e[1;36mCore Manager Options:\e[0m"
        echo -e " \e[1;32m[1]\e[0m Install/Update Backhaul Core"
        echo -e " \e[1;31m[2]\e[0m Remove Backhaul Core"
        echo -e " \e[1;31m[0]\e[0m Back to Main Menu"
        read -p "Enter your choice [0-2]: " core_choice
        case $core_choice in
            1) download_and_extract_backhaul "menu" ;;
            2) remove_core ;;
            0) return ;;
            *) echo -e "\e[1;31mInvalid option! Please try again.\e[0m" && sleep 1 ;;
        esac
    done
}

# Function to read user input
read_option() {
    read -p "Enter your choice [0-8]: " choice
    case $choice in
        1) configure_tunnel ;;
        2) configure_multi_tunnel ;;
        3) tunnel_management ;;
        4) check_tunnel_status ;;
        5) handle_advanced_options ;;
        6) handle_core_manager ;;
        7) update_script ;;
        8) 
            echo -e "\n\e[1;36mWeb Panel Manager Options:\e[0m"
            echo -e " \e[1;32m[1]\e[0m Start Web Panel"
            echo -e " \e[1;31m[2]\e[0m Stop Web Panel"
            echo -e " \e[1;33m[3]\e[0m Restart Web Panel"
            echo -e " \e[1;34m[4]\e[0m View Web Panel Status"
            echo -e " \e[1;31m[5]\e[0m Install Web Panel"
            echo -e " \e[1;31m[0]\e[0m Back to Main Menu"
            read -p "Enter your choice [0-5]: " panel_choice
            case $panel_choice in
                1) start_web_panel ;;
                2) stop_web_panel ;;
                3) systemctl restart backhaul-web-panel.service && echo "Web panel restarted." ;;
                4) systemctl status backhaul-web-panel.service ;;
                5) install_web_panel ;;
                0) return ;;
                *) echo -e "\e[1;31mInvalid option! Please try again.\e[0m" && sleep 1 ;;
            esac
            ;;
        0) exit 0 ;;
        *) echo -e "\e[1;31mInvalid option! Please try again.\e[0m" && sleep 1 ;;
    esac
}

# Function to handle advanced options
handle_advanced_options() {
    while true; do
        display_advanced_menu
        read -p "Enter your choice [0-4]: " advanced_choice
        case $advanced_choice in
            1) 
                echo -e "\n\e[1;36mEnter the service name to view logs:\e[0m"
                read -p "Service Name: " service_name
                view_service_logs "$service_name"
                ;;
            2) 
                echo -e "\n\e[1;36mEnter the service name to view status:\e[0m"
                read -p "Service Name: " service_name
                view_service_status "$service_name"
                ;;
            3) 
                echo -e "\n\e[1;36mChecking Core Version...\e[0m"
                check_core_version "https://example.com/core_version.txt"
                press_key
                ;;
            4) 
                echo -e "\n\e[1;36mChecking Script Version...\e[0m"
                check_script_version "https://example.com/script_version.txt"
                press_key
                ;;
            0) 
                return
                ;;
            *) 
                echo -e "\e[1;31mInvalid option! Please try again.\e[0m"
                sleep 1
                ;;
        esac
    done
}

# Function to configure multiple tunnels
configure_multi_tunnel() {
    clear
    colorize turquoise "Configuring Multiple Tunnels" bold
    echo

    # Prompt for the number of tunnels
    local num_tunnels
    while true; do
        echo -ne "Enter the number of tunnels to configure: "
        read -r num_tunnels
        if [[ "$num_tunnels" =~ ^[0-9]+$ ]] && [ "$num_tunnels" -gt 0 ]; then
            break
        else
            colorize red "Please enter a valid positive number."
        fi
    done

    # Loop to configure each tunnel
    for ((i = 1; i <= num_tunnels; i++)); do
        echo
        colorize yellow "Configuring Tunnel $i of $num_tunnels" bold

        # Prompt for tunnel-specific parameters
        local tunnel_port
        while true; do
            echo -ne "[Tunnel $i] Enter Tunnel Port: "
            read -r tunnel_port
            if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; then
                if check_port "$tunnel_port" "tcp"; then
                    colorize red "Port $tunnel_port is already in use. Please choose another port."
                else
                    break
                fi
            else
                colorize red "Please enter a valid port number between 23 and 65535."
            fi
        done

        local transport
        while [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; do
            echo -ne "[Tunnel $i] Enter Transport Type (tcp/tcpmux/ws/etc.): "
            read -r transport
            if [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; then
                colorize red "Invalid transport type. Please choose a valid option."
            fi
        done

        local token
        echo -ne "[Tunnel $i] Enter Security Token (default: your_token): "
        read -r token
        token="${token:-your_token}"

        # Generate configuration for the tunnel
        local config_file="${config_dir}/multi_tunnel_${tunnel_port}.toml"
        cat << EOF > "$config_file"
[server]
bind_addr = ":${tunnel_port}"
transport = "${transport}"
token = "${token}"
keepalive_period = 75
nodelay = true
channel_size = 2048
heartbeat = 40
mux_con = 8
mux_version = 2
mux_framesize = 32768
mux_recievebuffer = 4194304
mux_streambuffer = 2000000
EOF

        # Create systemd service for the tunnel
        local service_file="${service_dir}/multi_tunnel_${tunnel_port}.service"
        cat << EOF > "$service_file"
[Unit]
Description=Backhaul Multi-Tunnel Port $tunnel_port
After=network.target

[Service]
Type=simple
ExecStart=${config_dir}/backhaul_premium -c $config_file
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

        # Enable and start the service
        systemctl daemon-reload
        systemctl enable --now "multi_tunnel_${tunnel_port}.service" >/dev/null 2>&1
        if systemctl is-active --quiet "multi_tunnel_${tunnel_port}.service"; then
            colorize green "Tunnel $i with port $tunnel_port configured and started successfully."
        else
            colorize red "Failed to start Tunnel $i with port $tunnel_port."
        fi
    done

    echo
    colorize green "All $num_tunnels tunnels configured successfully." bold
    press_key
}

# Main script
while true
do
    display_menu
    read_option
done
