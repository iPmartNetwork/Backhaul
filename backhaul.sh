#!/bin/bash

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
            echo -e "${red}unzip is not installed. Installing...${nc}"
            sleep 1
            sudo apt-get update
            sudo apt-get install -y unzip
        else
            echo -e "${red}Error: Unsupported package manager. Please install unzip manually.${nc}\n"
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
SERVER_COUNTRY=$(curl -sS --max-time 2 "http://ipwhois.app/json/$SERVER_IP" | jq -r '.country')

# Fetch server isp 
SERVER_ISP=$(curl -sS --max-time 2 "http://ipwhois.app/json/$SERVER_IP" | jq -r '.isp')


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
    if [[ -f "${config_dir}/backhaul_premium" ]]; then
    	echo -e "Core Version: ${YELLOW}$($config_dir/backhaul_premium -v)${GREEN}"
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
    
	if ([[ "$TRANSPORT" == "tcp" ]] && ss -tlnp "sport = :$PORT" | grep "$PORT" > /dev/null) || ([[ "$TRANSPORT" == "udp" ]] && ss -ulnp "sport = :$PORT" | grep "$PORT" > /dev/null); then
		return 0
	else
		return 1
   	fi
}

# Function for configuring tunnel (rewritten for clarity and robustness)
configure_tunnel() {
    # Check if the Backhaul-core is installed
    if [[ ! -f "$config_dir/backhaul_premium" ]]; then
        colorize red "Backhaul-Core binary not found. Install it first through 'Update & Install Backhaul Core' option."
        press_key
        return 1
    fi

    clear
    colorize green "1) Configure for IRAN server" bold
    colorize magenta "2) Configure for KHAREJ server" bold
    echo
    read -p "Enter your choice: " configure_choice
    case "$configure_choice" in
        1) tunnel_config "iran" ;;
        2) tunnel_config "kharej" ;;
        *) colorize red "Invalid option!" && sleep 1 ;;
    esac
    echo
    press_key
}

tunnel_config() {
    local mode="$1"
    clear
    colorize cyan "Configuring $mode server" bold
    echo

    # Tunnel port
    local tunnel_port
    while true; do
        read -p "[*] Tunnel port: " tunnel_port
        if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; then
            if ! check_port "$tunnel_port" "tcp"; then
                break
            else
                colorize red "Port $tunnel_port is in use."
            fi
        else
            colorize red "Please enter a valid port number between 23 and 65535."
        fi
    done

    # Transport type
    local transport
    while [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; do
        read -p "[*] Transport type (tcp/tcpmux/utcpmux/ws/wsmux/uwsmux/udp/tcptun/faketcptun): " transport
        [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]] && colorize red "Invalid transport type."
    done

    # TUN Device Name, Subnet, MTU (for tun modes)
    local tun_name="backhaul" tun_subnet="10.10.10.0/24" mtu="1500"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
        read -p "[-] TUN Device Name (default backhaul): " tun_name
        tun_name="${tun_name:-backhaul}"
        while true; do
            read -p "[-] TUN Subnet (default 10.10.10.0/24): " tun_subnet
            tun_subnet="${tun_subnet:-10.10.10.0/24}"
            [[ "$tun_subnet" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]] && break
            colorize red "Please enter a valid subnet in CIDR notation."
        done
        while true; do
            read -p "[-] TUN MTU (default 1500): " mtu
            mtu="${mtu:-1500}"
            [[ "$mtu" =~ ^[0-9]+$ ]] && [ "$mtu" -ge 576 ] && [ "$mtu" -le 9000 ] && break
            colorize red "Please enter a valid MTU value between 576 and 9000."
        done
    fi

    # Accept UDP (only for tcp)
    local accept_udp="false"
    if [[ "$transport" == "tcp" ]]; then
        read -p "[-] Accept UDP over TCP (true/false, default false): " accept_udp
        accept_udp="${accept_udp:-false}"
        [[ "$accept_udp" != "true" && "$accept_udp" != "false" ]] && accept_udp="false"
    fi

    # Channel Size (not for tun)
    local channel_size="2048"
    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then
        read -p "[-] Channel Size (default 2048): " channel_size
        channel_size="${channel_size:-2048}"
    fi

    # TCP_NODELAY
    local nodelay="true"
    if [[ "$transport" == "udp" ]]; then
        nodelay="false"
    else
        read -p "[-] Enable TCP_NODELAY (true/false, default true): " nodelay
        nodelay="${nodelay:-true}"
        [[ "$nodelay" != "true" && "$nodelay" != "false" ]] && nodelay="true"
    fi

    # Heartbeat (not for tun)
    local heartbeat="40"
    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then
        read -p "[-] Heartbeat (seconds, default 40): " heartbeat
        heartbeat="${heartbeat:-40}"
    fi

    # Security Token
    local token
    read -p "[-] Security Token (default your_token): " token
    token="${token:-your_token}"

    # Mux concurrency/version
    local mux="8" mux_version="2"
    if [[ "$transport" =~ ^(tcpmux|wsmux)$ ]]; then
        read -p "[-] Mux concurrency (default 8): " mux
        mux="${mux:-8}"
    fi
    if [[ "$transport" =~ ^(tcpmux|wsmux|utcpmux|uwsmux)$ ]]; then
        read -p "[-] Mux Version (1 or 2, default 2): " mux_version
        mux_version="${mux_version:-2}"
    fi

    # Sniffer
    local sniffer="false"
    read -p "[-] Enable Sniffer (true/false, default false): " sniffer
    sniffer="${sniffer:-false}"

    # Web Port
    local web_port="0"
    read -p "[-] Web Port (default 0 to disable): " web_port
    web_port="${web_port:-0}"

    # Proxy Protocol (not for ws/udp/tun)
    local proxy_protocol="false"
    if [[ ! "$transport" =~ ^(ws|udp|tcptun|faketcptun)$ ]]; then
        read -p "[-] Enable Proxy Protocol (true/false, default false): " proxy_protocol
        proxy_protocol="${proxy_protocol:-false}"
    fi

    # IP Limit (kharej only, not for ws/udp/tun)
    local ip_limit="false"
    if [[ "$mode" == "kharej" && ! "$transport" =~ ^(ws|udp|tcptun|faketcptun)$ ]]; then
        read -p "[-] Enable IP Limit for X-UI Panel (true/false, default false): " ip_limit
        ip_limit="${ip_limit:-false}"
    fi

    # Edge IP (kharej only, ws/wsmux/uwsmux)
    local edge_ip=""
    if [[ "$mode" == "kharej" && "$transport" =~ ^(ws|wsmux|uwsmux)$ ]]; then
        read -p "[-] Edge IP/Domain (optional): " edge_ip
        [[ -n "$edge_ip" ]] && edge_ip="edge_ip = \"$edge_ip\""
    fi

    # Ports (not for tun)
    local ports=()
    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then
        colorize green "[*] Supported Port Formats:" bold
        echo "443-600, 443-600:5201, 443-600=1.1.1.1:5201, 443, 4000=5000, 127.0.0.2:443=5201, 443=1.1.1.1:5201, 127.0.0.2:443=1.1.1.1:5201"
        read -p "[*] Enter your ports (comma-separated): " input_ports
        IFS=',' read -ra ports <<< "$(echo "$input_ports" | tr -d ' ')"
    fi

    # Generate config file
    local config_file="${config_dir}/${mode}${tunnel_port}.toml"
    {
        if [[ "$mode" == "iran" ]]; then
            echo "[server]"
            echo "bind_addr = \":${tunnel_port}\""
        else
            echo "[client]"
            echo "remote_addr = \"${SERVER_ADDR}:${tunnel_port}\""
            [[ -n "$edge_ip" ]] && echo "$edge_ip"
        fi
        echo "transport = \"${transport}\""
        [[ "$mode" == "iran" ]] && echo "accept_udp = ${accept_udp}"
        echo "token = \"${token}\""
        echo "keepalive_period = 75"
        echo "nodelay = ${nodelay}"
        [[ "$mode" == "iran" ]] && echo "channel_size = ${channel_size}"
        [[ "$mode" == "iran" ]] && echo "heartbeat = ${heartbeat}"
        echo "mux_con = ${mux}"
        echo "mux_version = ${mux_version}"
        echo "mux_framesize = 32768"
        echo "mux_recievebuffer = 4194304"
        echo "mux_streambuffer = 2000000"
        echo "sniffer = ${sniffer}"
        echo "web_port = ${web_port}"
        echo "sniffer_log = \"/root/log.json\""
        echo "log_level = \"info\""
        [[ "$mode" == "iran" ]] && echo "proxy_protocol = ${proxy_protocol}"
        [[ "$mode" == "kharej" ]] && echo "ip_limit = ${ip_limit}"
        echo "tun_name = \"${tun_name}\""
        echo "tun_subnet = \"${tun_subnet}\""
        echo "mtu = ${mtu}"
        if [[ "${#ports[@]}" -gt 0 ]]; then
            echo "ports = ["
            for port in "${ports[@]}"; do
                echo "    \"$port\","
            done
            echo "]"
        fi
    } > "$config_file"

    colorize green "Configuration generated: $config_file"

    # Create systemd service
    local service_file="${service_dir}/backhaul-${mode}${tunnel_port}.service"
    {
        echo "[Unit]"
        echo "Description=Backhaul $mode Port $tunnel_port"
        echo "After=network.target"
        echo
        echo "[Service]"
        echo "Type=simple"
        echo "ExecStart=${config_dir}/backhaul_premium -c $config_file"
        echo "Restart=always"
        echo "RestartSec=3"
        echo
        echo "[Install]"
        echo "WantedBy=multi-user.target"
    } > "$service_file"

    systemctl daemon-reload
    if systemctl enable --now "$service_file"; then
        colorize green "$mode service with port $tunnel_port enabled and started."
    else
        colorize red "Failed to enable/start service with port $tunnel_port."
    fi
    echo
    colorize green "$mode server configuration completed successfully." bold
}

#Global Variables
service_dir="/etc/systemd/system"

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

# Function to display menu
display_menu() {
    clear
    display_logo
    display_server_info
    display_backhaul_core_status
    echo
    colorize green " 1. Configure a new tunnel [IPv4/IPv6]" bold
    colorize red " 2. Tunnel management menu" bold
    colorize cyan " 3. Check tunnels status" bold
    echo -e " 4. Update & Install Backhaul Core"
    echo -e " 5. Update & install script"
    echo -e " 6. Remove Backhaul Core"
    echo -e " 0. Exit"
    echo
    echo "-------------------------------"
}

# Function to read user input
read_option() {
    read -p "Enter your choice [0-6]: " choice
    case $choice in
        1) configure_tunnel ;;
        2) tunnel_management ;;
        3) check_tunnel_status ;;
        4) download_and_extract_backhaul "menu";;
        5) update_script ;;
        6) remove_core ;;
        0) exit 0 ;;
        *) echo -e "${RED} Invalid option!${NC}" && sleep 1 ;;
    esac
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
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
cyan='\e[36m'
magenta="\e[95m"
nc='\033[0m' # No Color

# Function to display menu
display_menu() {
    clear
    display_logo
    display_server_info
    display_backhaul_core_status
    
    echo
    colorize green " 1. Configure a new tunnel [IPv4/IPv6]" bold
    colorize red " 2. Tunnel management menu" bold
    colorize cyan " 3. Check tunnels status" bold
 	echo -e " 4. Update & Install Backhaul Core"
 	echo -e " 5. Update & install script"
 	echo -e " 6. Remove Backhaul Core"
    echo -e " 0. Exit"
    echo
    echo "-------------------------------"
}

# Function to read user input
read_option() {
    read -p "Enter your choice [0-6]: " choice
    case $choice in
        1) configure_tunnel ;;
        2) tunnel_management ;;
        3) check_tunnel_status ;;
        4) download_and_extract_backhaul "menu";;
        5) update_script ;;
        6) remove_core ;;
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
