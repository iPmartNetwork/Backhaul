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
SERVER_COUNTRY=$(curl -sS --max-time 2 "http://ipwhois.app/json/$SERVER_IP" | jq -r '.country')

# Fetch server isp 
SERVER_ISP=$(curl -sS --max-time 2 "http://ipwhois.app/json/$SERVER_IP" | jq -r '.isp')


# Function to display ASCII logo
display_logo() {   
    echo -e "\033[36m"  # Updated to turquoise
    cat << "EOF"
 ____  ____  ____  _  __ _     ____  _     _    
/  _ \/  _ \/   _\/ |/ // \ /|/  _ \/ \ /\/ \   
| | //| / \||  /  |   / | |_||| / \|| | ||| |   
| |_\\| |-|||  \_ |   \ | | ||| |-||| \_/|| |_/\
\____/\_/ \|\____/\_|\_\\_/ \|\_/ \|\____/\____/
                                                
   Lightning-fast reverse tunneling solution
EOF
    echo -e "\033[0m\033[36m"  # Updated to turquoise
    echo -e "Script Version: \033[36m${SCRIPT_VERSION}\033[36m"  # Updated to turquoise
    if [[ -f "${config_dir}/backhaul_premium" ]]; then
    	echo -e "Core Version: \033[36m$($config_dir/backhaul_premium -v)\033[36m"  # Updated to turquoise
    fi
    echo -e "Telegram Channel: \033[36m@anony_identity\033[0m"  # Updated to turquoise
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
    
	if ([[ "$TRANSPORT" == "tcp" ]] && ss -tlnp "sport = :$PORT" | grep "$PORT" > /dev/null) || ([[ "$TRANSPORT" == "udp" ]] && ss -ulnp "sport = :$PORT" | grep "$PORT" > /dev/null); thens -tlnp "sport = :$PORT" | grep "$PORT" > /dev/null) || ([[ "$TRANSPORT" == "udp" ]] && ss -ulnp "sport = :$PORT" | grep "$PORT" > /dev/null); thens -tlnp "sport = :$PORT" | grep "$PORT" > /dev/null) || ([[ "$TRANSPORT" == "udp" ]] && ss -ulnp "sport = :$PORT" | grep "$PORT" > /dev/null); then
		return 0
	else
		return 1eturn 1eturn 1
   	fi
}

# Function for configuring tunnel
configure_tunnel() {

# check if the Backhaul-core installed or notk if the Backhaul-core installed or notk if the Backhaul-core installed or not
if [[ ! -d "$config_dir" ]]; then"$config_dir" ]]; then"$config_dir" ]]; then
    echo -e "\n${RED}Backhaul-Core directory not found. Install it first through 'Install Backhaul core' option.${NC}\n"echo -e "\n${RED}Backhaul-Core directory not found. Install it first through 'Install Backhaul core' option.${NC}\n"echo -e "\n${RED}Backhaul-Core directory not found. Install it first through 'Install Backhaul core' option.${NC}\n"
    read -p "Press Enter to continue..."ead -p "Press Enter to continue..."ead -p "Press Enter to continue..."
    return 1 1 1
fi

    clear   clear   clear

    echo
    colorize turquoise "1) Configure for IRAN server" boldse "1) Configure for IRAN server" boldse "1) Configure for IRAN server" bold
    colorize turquoise "2) Configure for KHAREJ server" bold    colorize turquoise "2) Configure for KHAREJ server" bold    colorize turquoise "2) Configure for KHAREJ server" bold
    colorize red "0) Back to Main Menu" bold
    echo
    read -p "Enter your choice: " configure_choice
    case "$configure_choice" in
        1) iran_server_configuration ;;ran_server_configuration ;;ran_server_configuration ;;
        2) kharej_server_configuration ;;      2) kharej_server_configuration ;;      2) kharej_server_configuration ;;
        0) return ;;        0) return ;;        0) return ;;
        *) echo -e "${RED}Invalid option!${NC}" && sleep 1 ;;) echo -e "${RED}Invalid option!${NC}" && sleep 1 ;;) echo -e "${RED}Invalid option!${NC}" && sleep 1 ;;
    esac    esac    esac
    echo
    read -p "Press Enter to continue..."
}

#Global VariablesVariablesVariables
service_dir="/etc/systemd/system"


iran_server_configuration() {  
    clear
    colorize turquoise "Configuring IRAN server" bold

    echo

    while true; do   while true; do   while true; do
        echo -ne "[*] Tunnel port: "        echo -ne "[*] Tunnel port: "        echo -ne "[*] Tunnel port: "
        read -r tunnel_portunnel_portunnel_port

        if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; then        if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; then        if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; then
            if check_port "$tunnel_port" "tcp"; then            if check_port "$tunnel_port" "tcp"; then            if check_port "$tunnel_port" "tcp"; then
                colorize turquoise "Port $tunnel_port is in use."ise "Port $tunnel_port is in use."ise "Port $tunnel_port is in use."
            else   else   else
                break
            fi            fi            fi
        elseelseelse
            colorize turquoise "Please enter a valid port number between 23 and 65535."            colorize turquoise "Please enter a valid port number between 23 and 65535."            colorize turquoise "Please enter a valid port number between 23 and 65535."
            echo
        fi
    done

    echo

    # Initialize transport variable
    local transport=""ort=""ort=""
    while [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; dosport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; dosport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; do
        echo -ne "[*] Transport type (tcp/tcpmux/utcpmux/ws/wsmux/uwsmux/udp/tcptun/faketcptun): "ne "[*] Transport type (tcp/tcpmux/utcpmux/ws/wsmux/uwsmux/udp/tcptun/faketcptun): "ne "[*] Transport type (tcp/tcpmux/utcpmux/ws/wsmux/uwsmux/udp/tcptun/faketcptun): "
        read -r transport -r transport -r transport

        if [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; then"$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; then"$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; then
            colorize turquoise "Invalid transport type. Please choose from tcp, tcpmux, utcpmux, ws, wsmux, uwsmux, udp, tcptun, faketcptun."  colorize turquoise "Invalid transport type. Please choose from tcp, tcpmux, utcpmux, ws, wsmux, uwsmux, udp, tcptun, faketcptun."  colorize turquoise "Invalid transport type. Please choose from tcp, tcpmux, utcpmux, ws, wsmux, uwsmux, udp, tcptun, faketcptun."
            echo    echo    echo
        fi        fi        fi
    done

    echo

    # TUN Device Name 
    local tun_name="backhaul"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then "tcptun" || "$transport" == "faketcptun" ]]; then "tcptun" || "$transport" == "faketcptun" ]]; then
        while true; do        while true; do        while true; do
            echo -ne "[-] TUN Device Name (default backhaul): "
            read -r tun_name

            if [[ -z "$tun_name" ]]; then  if [[ -z "$tun_name" ]]; then  if [[ -z "$tun_name" ]]; then
                tun_name="backhaul"        tun_name="backhaul"        tun_name="backhaul"
            fi            fi            fi

            if [[ "$tun_name" =~ ^[a-zA-Z0-9]+$ ]]; then            if [[ "$tun_name" =~ ^[a-zA-Z0-9]+$ ]]; then            if [[ "$tun_name" =~ ^[a-zA-Z0-9]+$ ]]; then
                echo
                break
            else
                colorize turquoise "Please enter a valid TUN device name."ze turquoise "Please enter a valid TUN device name."ze turquoise "Please enter a valid TUN device name."
                echo
            fi
        done        done        done
    fi

    # TUN Subnetetet
    local tun_subnet="10.10.10.0/24"    local tun_subnet="10.10.10.0/24"    local tun_subnet="10.10.10.0/24"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; thenaketcptun" ]]; thenaketcptun" ]]; then
        while true; dododo
            echo -ne "[-] TUN Subnet (default 10.10.10.0/24): ""[-] TUN Subnet (default 10.10.10.0/24): ""[-] TUN Subnet (default 10.10.10.0/24): "
            read -r tun_subnet -r tun_subnet -r tun_subnet

            # Set default value if input is emptyfault value if input is emptyfault value if input is empty
            if [[ -z "$tun_subnet" ]]; then [[ -z "$tun_subnet" ]]; then [[ -z "$tun_subnet" ]]; then
                tun_subnet="10.10.10.0/24"    tun_subnet="10.10.10.0/24"    tun_subnet="10.10.10.0/24"
            fi      fi      fi

            # Validate TUN subnet (CIDR notation)lidate TUN subnet (CIDR notation)lidate TUN subnet (CIDR notation)
            if [[ "$tun_subnet" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then
                # Validate IP and subnet mask
                IFS='/' read -r ip subnet <<< "$tun_subnet"' read -r ip subnet <<< "$tun_subnet"' read -r ip subnet <<< "$tun_subnet"
                if [[ "$subnet" -le 32 && "$subnet" -ge 1 ]]; thenhenhen
                    IFS='.' read -r a b c d <<< "$ip"ad -r a b c d <<< "$ip"ad -r a b c d <<< "$ip"
                    if [[ "$a" -le 255 && "$b" -le 255 && "$c" -le 255 && "$d" -le 255 ]]; then                    if [[ "$a" -le 255 && "$b" -le 255 && "$c" -le 255 && "$d" -le 255 ]]; then                    if [[ "$a" -le 255 && "$b" -le 255 && "$c" -le 255 && "$d" -le 255 ]]; then
                        echo
                        break
                    fi
                fi  fi  fi
            fi            fi            fi

            colorize turquoise "Please enter a valid subnet in CIDR notation (e.g., 10.10.10.0/24)."10.10.10.0/24)."10.10.10.0/24)."
            echo
        done
    fi

    # TUN MTU
    local mtu="1500"    
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; thenptun" || "$transport" == "faketcptun" ]]; thenptun" || "$transport" == "faketcptun" ]]; then
        while true; do
            echo -ne "[-] TUN MTU (default 1500): "ne "[-] TUN MTU (default 1500): "ne "[-] TUN MTU (default 1500): "
            read -r mtuad -r mtuad -r mtu

            # Set default value if input is empty
            if [[ -z "$mtu" ]]; then[ -z "$mtu" ]]; then[ -z "$mtu" ]]; then
                mtu=1500    mtu=1500    mtu=1500
            fi      fi      fi

            # Validate MTU value Validate MTU value Validate MTU value
            if [[ "$mtu" =~ ^[0-9]+$ ]] && [ "$mtu" -ge 576 ] && [ "$mtu" -le 9000 ]; then =~ ^[0-9]+$ ]] && [ "$mtu" -ge 576 ] && [ "$mtu" -le 9000 ]; then =~ ^[0-9]+$ ]] && [ "$mtu" -ge 576 ] && [ "$mtu" -le 9000 ]; then
                break
            fi

            colorize turquoise "Please enter a valid MTU value between 576 and 9000."rquoise "Please enter a valid MTU value between 576 and 9000."rquoise "Please enter a valid MTU value between 576 and 9000."
            echo            echo            echo
        done
    fi
    

    # Accept UDP (only for tcp transport)    # Accept UDP (only for tcp transport)    # Accept UDP (only for tcp transport)
	local accept_udp="" 
	if [[ "$transport" == "tcp" ]]; then
	    while [[ "$accept_udp" != "true" && "$accept_udp" != "false" ]]; dot_udp" != "true" && "$accept_udp" != "false" ]]; dot_udp" != "true" && "$accept_udp" != "false" ]]; do
	        echo -ne "[-] Accept UDP connections over TCP transport (true/false)(default false): "-ne "[-] Accept UDP connections over TCP transport (true/false)(default false): "-ne "[-] Accept UDP connections over TCP transport (true/false)(default false): "
	        read -r accept_udp	        read -r accept_udp	        read -r accept_udp
	        
    	    # Set default to "false" if input is emptyefault to "false" if input is emptyefault to "false" if input is empty
            if [[ -z "$accept_udp" ]]; thenif [[ -z "$accept_udp" ]]; thenif [[ -z "$accept_udp" ]]; then
                accept_udp="false"          accept_udp="false"          accept_udp="false"
            fi        fi        fi
                        
        
	        if [[ "$accept_udp" != "true" && "$accept_udp" != "false" ]]; thenpt_udp" != "true" && "$accept_udp" != "false" ]]; thenpt_udp" != "true" && "$accept_udp" != "false" ]]; then
	            colorize turquoise "Invalid input. Please enter 'true' or 'false'."lid input. Please enter 'true' or 'false'."lid input. Please enter 'true' or 'false'."
	            echo
	        fi
	    done
	else
	    # Automatically set accept_udp to false for non-TCP transportn-TCP transportn-TCP transport
	    accept_udp="false"
	fi

    echo   

    # Channel Size
    local channel_size="2048"
    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; thenport" != "tcptun" && "$transport" != "faketcptun" ]]; thenport" != "tcptun" && "$transport" != "faketcptun" ]]; then
        while true; dole true; dole true; do
            echo -ne "[-] Channel Size (default 2048): "   echo -ne "[-] Channel Size (default 2048): "   echo -ne "[-] Channel Size (default 2048): "
            read -r channel_size       read -r channel_size       read -r channel_size

            # Set default to 2048 if the input is emptylt to 2048 if the input is emptylt to 2048 if the input is empty
            if [[ -z "$channel_size" ]]; then         if [[ -z "$channel_size" ]]; then         if [[ -z "$channel_size" ]]; then
                channel_size=2048                channel_size=2048                channel_size=2048
            fi   fi   fi
                        
            if [[ "$channel_size" =~ ^[0-9]+$ ]] && [ "$channel_size" -gt 64 ] && [ "$channel_size" -le 8192 ]; then"$channel_size" =~ ^[0-9]+$ ]] && [ "$channel_size" -gt 64 ] && [ "$channel_size" -le 8192 ]; then"$channel_size" =~ ^[0-9]+$ ]] && [ "$channel_size" -gt 64 ] && [ "$channel_size" -le 8192 ]; then
                break
            else
                colorize turquoise "Please enter a valid channel size between 64 and 8192."ze turquoise "Please enter a valid channel size between 64 and 8192."ze turquoise "Please enter a valid channel size between 64 and 8192."
                echo
            fi
        done        done        done

        echo 
    
    fi

    # Enable TCP_NODELAY
    local nodelay=""
    
    # Check transport type
    if [[ "$transport" == "udp" ]]; thent" == "udp" ]]; thent" == "udp" ]]; then
        nodelay=falsey=falsey=false
    else
        while [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; do        while [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; do        while [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; do
            echo -ne "[-] Enable TCP_NODELAY (true/false)(default true): "cho -ne "[-] Enable TCP_NODELAY (true/false)(default true): "cho -ne "[-] Enable TCP_NODELAY (true/false)(default true): "
            read -r nodelay        read -r nodelay        read -r nodelay
                        
            if [[ -z "$nodelay" ]]; then            if [[ -z "$nodelay" ]]; then            if [[ -z "$nodelay" ]]; then
                nodelay=truetruetrue
            fi
                
    
            if [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; then& "$nodelay" != "false" ]]; then& "$nodelay" != "false" ]]; then
                colorize turquoise "Invalid input. Please enter 'true' or 'false'."ize turquoise "Invalid input. Please enter 'true' or 'false'."ize turquoise "Invalid input. Please enter 'true' or 'false'."
                echo        echo        echo
            fi
        done
    fi
    
    echo 
    
    # HeartBeattt
    local heartbeat=40l heartbeat=40l heartbeat=40
    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; thenif [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; thenif [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then
        while true; do
            echo -ne "[-] Heartbeat (in seconds, default 40): "
            read -r heartbeatheartbeatheartbeat

            if [[ -z "$heartbeat" ]]; thenif [[ -z "$heartbeat" ]]; thenif [[ -z "$heartbeat" ]]; then
                heartbeat=40          heartbeat=40          heartbeat=40
            fi        fi        fi
                              
            if [[ "$heartbeat" =~ ^[0-9]+$ ]] && [ "$heartbeat" -gt 1 ] && [ "$heartbeat" -le 240 ]; then        if [[ "$heartbeat" =~ ^[0-9]+$ ]] && [ "$heartbeat" -gt 1 ] && [ "$heartbeat" -le 240 ]; then        if [[ "$heartbeat" =~ ^[0-9]+$ ]] && [ "$heartbeat" -gt 1 ] && [ "$heartbeat" -le 240 ]; then
                break break break
            else
                colorize turquoise "Please enter a valid heartbeat between 1 and 240."1 and 240."1 and 240."
                echo
            fi
        done

        echo

    fi

    # Security Token
    echo -ne "[-] Security Token (press enter to use default value): "urity Token (press enter to use default value): "urity Token (press enter to use default value): "
    read -r tokennn
    token="${token:-your_token}"


    # Mux Conurrancynurrancynurrancy
    if [[ "$transport" =~ ^(tcpmux|wsmux)$ ]]; then    if [[ "$transport" =~ ^(tcpmux|wsmux)$ ]]; then    if [[ "$transport" =~ ^(tcpmux|wsmux)$ ]]; then
        while true; doe true; doe true; do
            echo             echo             echo 
            echo -ne "[-] Mux concurrency (default 8): "      echo -ne "[-] Mux concurrency (default 8): "      echo -ne "[-] Mux concurrency (default 8): "
            read -r mux            read -r mux            read -r mux
    
            if [[ -z "$mux" ]]; then
                mux=8ux=8ux=8
            fi
                        
            if [[ "$mux" =~ ^[0-9]+$ ]] && [ "$mux" -gt 0 ] && [ "$mux" -le 1000 ]; then            if [[ "$mux" =~ ^[0-9]+$ ]] && [ "$mux" -gt 0 ] && [ "$mux" -le 1000 ]; then            if [[ "$mux" =~ ^[0-9]+$ ]] && [ "$mux" -gt 0 ] && [ "$mux" -le 1000 ]; then
                breakkk
            else
                colorize turquoise "Please enter a valid concurrency between 0 and 1000"ze turquoise "Please enter a valid concurrency between 0 and 1000"ze turquoise "Please enter a valid concurrency between 0 and 1000"
                echochocho
            fi
        done
    elseelseelse
        mux=8
    fi
    
    	
    # Mux Version
    if [[ "$transport" =~ ^(tcpmux|wsmux|utcpmux|uwsmux)$ ]]; then" =~ ^(tcpmux|wsmux|utcpmux|uwsmux)$ ]]; then" =~ ^(tcpmux|wsmux|utcpmux|uwsmux)$ ]]; then
        while true; doue; doue; do
            echo 
            echo -ne "[-] Mux Version (1 or 2) (default 2): " "[-] Mux Version (1 or 2) (default 2): " "[-] Mux Version (1 or 2) (default 2): "
            read -r mux_versionad -r mux_versionad -r mux_version
    
            # Set default to 1 if input is empty    # Set default to 1 if input is empty    # Set default to 1 if input is empty
            if [[ -z "$mux_version" ]]; thenf [[ -z "$mux_version" ]]; thenf [[ -z "$mux_version" ]]; then
                mux_version=2          mux_version=2          mux_version=2
            fi        fi        fi
                          
            # Validate the input for version 1 or 2idate the input for version 1 or 2idate the input for version 1 or 2
            if [[ "$mux_version" =~ ^[0-9]+$ ]] && [ "$mux_version" -ge 1 ] && [ "$mux_version" -le 2 ]; then" -ge 1 ] && [ "$mux_version" -le 2 ]; then" -ge 1 ] && [ "$mux_version" -le 2 ]; then
                break
            else
                colorize turquoise "Please enter a valid mux version: 1 or 2."version: 1 or 2."version: 1 or 2."
                echo
            fi        fi        fi
        done
    else
        mux_version=2
    fi
    
	echo
	
	
    # Enable Snifferfferffer
    local sniffer=""
    while [[ "$sniffer" != "true" && "$sniffer" != "false" ]]; doer" != "true" && "$sniffer" != "false" ]]; doer" != "true" && "$sniffer" != "false" ]]; do
        echo -ne "[-] Enable Sniffer (true/false)(default false): "ne "[-] Enable Sniffer (true/false)(default false): "ne "[-] Enable Sniffer (true/false)(default false): "
        read -r sniffer -r sniffer -r sniffer
        
        if [[ -z "$sniffer" ]]; theniffer" ]]; theniffer" ]]; then
            sniffer=false      sniffer=false      sniffer=false
        fi    fi    fi
                          
        if [[ "$sniffer" != "true" && "$sniffer" != "false" ]]; then       if [[ "$sniffer" != "true" && "$sniffer" != "false" ]]; then       if [[ "$sniffer" != "true" && "$sniffer" != "false" ]]; then
            colorize turquoise "Invalid input. Please enter 'true' or 'false'."           colorize turquoise "Invalid input. Please enter 'true' or 'false'."           colorize turquoise "Invalid input. Please enter 'true' or 'false'."
            echo
        fi
    done
	
	echo 
	
	# Get Web Port
	local web_port=""
	while true; doe; doe; do
	    echo -ne "[-] Enter Web Port (default 0 to disable): "e "[-] Enter Web Port (default 0 to disable): "e "[-] Enter Web Port (default 0 to disable): "
	    read -r web_port
	    
        if [[ -z "$web_port" ]]; then "$web_port" ]]; then "$web_port" ]]; then
            web_port=0  web_port=0  web_port=0
            echo    echo    echo
        fi       fi       fi
    donenene
	
	echo 
	
	# Get Web Port
	local web_port=""
	while true; do
	    echo -ne "[-] Enter Web Port (default 0 to disable): "echo -ne "[-] Enter Web Port (default 0 to disable): "echo -ne "[-] Enter Web Port (default 0 to disable): "
	    read -r web_port
	    
        if [[ -z "$web_port" ]]; then "$web_port" ]]; then "$web_port" ]]; then
            web_port=0  web_port=0  web_port=0
        fififi
	    if [[ "$web_port" == "0" ]]; then    if [[ "$web_port" == "0" ]]; then    if [[ "$web_port" == "0" ]]; then
	        break   break   break
	    elif [[ "$web_port" =~ ^[0-9]+$ ]] && ((web_port >= 23 && web_port <= 65535)); then    elif [[ "$web_port" =~ ^[0-9]+$ ]] && ((web_port >= 23 && web_port <= 65535)); then    elif [[ "$web_port" =~ ^[0-9]+$ ]] && ((web_port >= 23 && web_port <= 65535)); then
	        if check_port "$web_port" "tcp"; thenck_port "$web_port" "tcp"; thenck_port "$web_port" "tcp"; then
	            colorize red "Port $web_port is already in use. Please choose a different port."ize red "Port $web_port is already in use. Please choose a different port."ize red "Port $web_port is already in use. Please choose a different port."
	            echohoho
	        else
	            break
	        fi    fi    fi
	    else
	        colorize red "Invalid port. Please enter a number between 22 and 65535, or 0 to disable.""Invalid port. Please enter a number between 22 and 65535, or 0 to disable.""Invalid port. Please enter a number between 22 and 65535, or 0 to disable."
	        echochocho
	    fi
	done
    
    echo

    # Proxy Protocol col col 
    if [[ ! "$transport" =~ ^(ws|udp|tcptun|faketcptun)$ ]]; then$transport" =~ ^(ws|udp|tcptun|faketcptun)$ ]]; then$transport" =~ ^(ws|udp|tcptun|faketcptun)$ ]]; then
        # Enable Proxy Protocolroxy Protocolroxy Protocol
        local proxy_protocol=""al proxy_protocol=""al proxy_protocol=""
        while [[ "$proxy_protocol" != "true" && "$proxy_protocol" != "false" ]]; dohile [[ "$proxy_protocol" != "true" && "$proxy_protocol" != "false" ]]; dohile [[ "$proxy_protocol" != "true" && "$proxy_protocol" != "false" ]]; do
            echo -ne "[-] Enable Proxy Protocol (true/false)(default false): "
            read -r proxy_protocolead -r proxy_protocolead -r proxy_protocol
                      
            if [[ -z "$proxy_protocol" ]]; then       if [[ -z "$proxy_protocol" ]]; then       if [[ -z "$proxy_protocol" ]]; then
                proxy_protocol=false            proxy_protocol=false            proxy_protocol=false
            fi    fi    fi
                                                
            if [[ "$proxy_protocol" != "true" && "$proxy_protocol" != "false" ]]; thenroxy_protocol" != "true" && "$proxy_protocol" != "false" ]]; thenroxy_protocol" != "true" && "$proxy_protocol" != "false" ]]; then
                colorize red "Invalid input. Please enter 'true' or 'false'."or 'false'."or 'false'."
                echo
            fi
        done
    else
	    # Automatically set proxy_protocol to false for ws and udptocol to false for ws and udptocol to false for ws and udp
	    proxy_protocol="false"rotocol="false"rotocol="false"
	fi

        
	echo

    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then
        # Display port format optionsrt format optionsrt format options
        colorize green "[*] Supported Port Formats:" boldze green "[*] Supported Port Formats:" boldze green "[*] Supported Port Formats:" bold
        echo "1. 443-600                  - Listen on all ports in the range 443 to 600." "1. 443-600                  - Listen on all ports in the range 443 to 600." "1. 443-600                  - Listen on all ports in the range 443 to 600."
        echo "2. 443-600:5201             - Listen on all ports in the range 443 to 600 and forward traffic to 5201."echo "2. 443-600:5201             - Listen on all ports in the range 443 to 600 and forward traffic to 5201."echo "2. 443-600:5201             - Listen on all ports in the range 443 to 600 and forward traffic to 5201."
        echo "3. 443-600=1.1.1.1:5201     - Listen on all ports in the range 443 to 600 and forward traffic to 1.1.1.1:5201." in the range 443 to 600 and forward traffic to 1.1.1.1:5201." in the range 443 to 600 and forward traffic to 1.1.1.1:5201."
        echo "4. 443                      - Listen on local port 443 and forward to remote port 443 (default forwarding)."               - Listen on local port 443 and forward to remote port 443 (default forwarding)."               - Listen on local port 443 and forward to remote port 443 (default forwarding)."
        echo "5. 4000=5000                - Listen on local port 4000 (bind to all local IPs) and forward to remote port 5000."     echo "5. 4000=5000                - Listen on local port 4000 (bind to all local IPs) and forward to remote port 5000."     echo "5. 4000=5000                - Listen on local port 4000 (bind to all local IPs) and forward to remote port 5000."
        echo "6. 127.0.0.2:443=5201       - Bind to specific local IP (127.0.0.2), listen on port 443, and forward to remote port 5201."        echo "6. 127.0.0.2:443=5201       - Bind to specific local IP (127.0.0.2), listen on port 443, and forward to remote port 5201."        echo "6. 127.0.0.2:443=5201       - Bind to specific local IP (127.0.0.2), listen on port 443, and forward to remote port 5201."
        echo "7. 443=1.1.1.1:5201         - Listen on local port 443 and forward to a specific remote IP (1.1.1.1) on port 5201."echo "7. 443=1.1.1.1:5201         - Listen on local port 443 and forward to a specific remote IP (1.1.1.1) on port 5201."echo "7. 443=1.1.1.1:5201         - Listen on local port 443 and forward to a specific remote IP (1.1.1.1) on port 5201."
        #echo "8. 127.0.0.2:443=1.1.1.1:5201 - Bind to specific local IP (127.0.0.2), listen on port 443, and forward to remote IP (1.1.1.1) on port 5201."   #echo "8. 127.0.0.2:443=1.1.1.1:5201 - Bind to specific local IP (127.0.0.2), listen on port 443, and forward to remote IP (1.1.1.1) on port 5201."   #echo "8. 127.0.0.2:443=1.1.1.1:5201 - Bind to specific local IP (127.0.0.2), listen on port 443, and forward to remote IP (1.1.1.1) on port 5201."
        echo ""        echo ""        echo ""
        
        # Prompt user for input
        echo -ne "[*] Enter your ports in the specified formats (separated by commas): "ormats (separated by commas): "ormats (separated by commas): "
        read -r input_ports
        input_ports=$(echo "$input_ports" | tr -d ' ')
        IFS=',' read -r -a ports <<< "$input_ports"
    fi

    # Generate configuration
    cat << EOF > "${config_dir}/iran${tunnel_port}.toml"
[server]
bind_addr = ":${tunnel_port}"{tunnel_port}"{tunnel_port}"
transport = "${transport}"t = "${transport}"t = "${transport}"
accept_udp = ${accept_udp}
token = "${token}"
keepalive_period = 75
nodelay = ${nodelay}
channel_size = ${channel_size}
heartbeat = ${heartbeat}eat = ${heartbeat}eat = ${heartbeat}
mux_con = ${mux}mux_con = ${mux}mux_con = ${mux}
mux_version = ${mux_version}
mux_framesize = 32768
mux_recievebuffer = 4194304evebuffer = 4194304evebuffer = 4194304
mux_streambuffer = 2000000
sniffer = ${sniffer}
web_port = ${web_port}
sniffer_log = "/root/log.json"ot/log.json"ot/log.json"
log_level = "info"
proxy_protocol= ${proxy_protocol}oxy_protocol}oxy_protocol}
tun_name = "${tun_name}"
tun_subnet = "${tun_subnet}"et}"et}"
mtu = ${mtu}

ports = [
EOF

	# Validate and process port mappingsess port mappingsess port mappings
	for port in "${ports[@]}"; do@]}"; do@]}"; do
	    if [[ "$port" =~ ^[0-9]+-[0-9]+$ ]]; then[0-9]+$ ]]; then[0-9]+$ ]]; then
	        # Range of ports (e.g., 443-600)f ports (e.g., 443-600)f ports (e.g., 443-600)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml" "${config_dir}/iran${tunnel_port}.toml" "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^[0-9]+-[0-9]+:[0-9]+$ ]]; then^[0-9]+-[0-9]+:[0-9]+$ ]]; then^[0-9]+-[0-9]+:[0-9]+$ ]]; then
	        # Port range with forwarding to a specific port (e.g., 443-600:5201)orwarding to a specific port (e.g., 443-600:5201)orwarding to a specific port (e.g., 443-600:5201)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"o "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"o "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^[0-9]+-[0-9]+=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):[0-9]+$ ]]; then	    elif [[ "$port" =~ ^[0-9]+-[0-9]+=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):[0-9]+$ ]]; then	    elif [[ "$port" =~ ^[0-9]+-[0-9]+=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):[0-9]+$ ]]; then
	        # Port range forwarding to a specific remote IP and port (e.g., 443-600=1.1.1.1:5201)# Port range forwarding to a specific remote IP and port (e.g., 443-600=1.1.1.1:5201)# Port range forwarding to a specific remote IP and port (e.g., 443-600=1.1.1.1:5201)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"      echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"      echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^[0-9]+$ ]]; then	    elif [[ "$port" =~ ^[0-9]+$ ]]; then	    elif [[ "$port" =~ ^[0-9]+$ ]]; then
	        # Single port forwarding (e.g., 443)g., 443)g., 443)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml" >> "${config_dir}/iran${tunnel_port}.toml" >> "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^[0-9]+=[0-9]+$ ]]; thenenen
	        # Single port with forwarding to another port (e.g., 4000=5000) another port (e.g., 4000=5000) another port (e.g., 4000=5000)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):[0-9]+=[0-9]+$ ]]; then+):[0-9]+=[0-9]+$ ]]; then+):[0-9]+=[0-9]+$ ]]; then
	        # Specific local IP with port forwarding (e.g., 127.0.0.2:443=5201)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^[0-9]+=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
	        # Single port with forwarding to a specific remote IP and port (e.g., 443=1.1.1.1:5201)1)1)
	        echo "    \"$port\"," >> "${config_dir}/iran${tunnel_port}.toml"
	    elif [[ "$port" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):[0-9]+=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then.[0-9]+\.[0-9]+):[0-9]+=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then.[0-9]+\.[0-9]+):[0-9]+=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
	        # Specific local IP with forwarding to a specific remote IP and port (e.g., 127.0.0.2:443=1.1.1.1:5201)to a specific remote IP and port (e.g., 127.0.0.2:443=1.1.1.1:5201)to a specific remote IP and port (e.g., 127.0.0.2:443=1.1.1.1:5201)
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

    # Create the systemd servicethe systemd servicethe systemd service
    cat << EOF > "${service_dir}/backhaul-iran${tunnel_port}.service" << EOF > "${service_dir}/backhaul-iran${tunnel_port}.service" << EOF > "${service_dir}/backhaul-iran${tunnel_port}.service"
[Unit]]]
Description=Backhaul Iran Port $tunnel_port (Iran)escription=Backhaul Iran Port $tunnel_port (Iran)escription=Backhaul Iran Port $tunnel_port (Iran)
After=network.target

[Service]ice]ice]
Type=simpleype=simpleype=simple
ExecStart=${config_dir}/backhaul_premium -c ${config_dir}/iran${tunnel_port}.tomlr}/iran${tunnel_port}.tomlr}/iran${tunnel_port}.toml
Restart=alwaysRestart=alwaysRestart=always
RestartSec=3c=3c=3

[Install]
WantedBy=multi-user.target
EOF

    # Reload and enable serviceble serviceble service
    systemctl daemon-reload >/dev/null 2>&1    systemctl daemon-reload >/dev/null 2>&1    systemctl daemon-reload >/dev/null 2>&1
    if systemctl enable --now "${service_dir}/backhaul-iran${tunnel_port}.service" >/dev/null 2>&1; thenstemctl enable --now "${service_dir}/backhaul-iran${tunnel_port}.service" >/dev/null 2>&1; thenstemctl enable --now "${service_dir}/backhaul-iran${tunnel_port}.service" >/dev/null 2>&1; then
        colorize green "Iran service with port $tunnel_port enabled to start on boot and started."orize green "Iran service with port $tunnel_port enabled to start on boot and started."orize green "Iran service with port $tunnel_port enabled to start on boot and started."
    else
        colorize red "Failed to enable service with port $tunnel_port. Please check your system configuration."ze red "Failed to enable service with port $tunnel_port. Please check your system configuration."ze red "Failed to enable service with port $tunnel_port. Please check your system configuration."
        return 1rn 1rn 1
    fi    fi    fi

    echo
    colorize green "IRAN server configuration completed successfully." bold colorize green "IRAN server configuration completed successfully." bold colorize green "IRAN server configuration completed successfully." bold
}}}

# Function for configuring Kharej server
kharej_server_configuration() {
    clear
    colorize cyan "Configuring Kharej server" boldrize cyan "Configuring Kharej server" boldrize cyan "Configuring Kharej server" bold
    
    echo

    # Prompt for IRAN server IP address    # Prompt for IRAN server IP address    # Prompt for IRAN server IP address
    while true; doe true; doe true; do
        echo -ne "[*] IRAN server IP address [IPv4/IPv6]: "
        read -r SERVER_ADDR       read -r SERVER_ADDR       read -r SERVER_ADDR
        if [[ -n "$SERVER_ADDR" ]]; then        if [[ -n "$SERVER_ADDR" ]]; then        if [[ -n "$SERVER_ADDR" ]]; then
            break
        else
            colorize red "Server address cannot be empty. Please enter a valid address."   colorize red "Server address cannot be empty. Please enter a valid address."   colorize red "Server address cannot be empty. Please enter a valid address."
            echo
        fi    fi    fi
    done
            
    echo

    # Read the tunnel port
    while true; do
        echo -ne "[*] Tunnel port: "
        read -r tunnel_portunnel_portunnel_port

        if [[ "$tunnel_port" =~ ^[0-9]+$ ]] && [ "$tunnel_port" -gt 22 ] && [ "$tunnel_port" -le 65535 ]; thenort" -le 65535 ]; thenort" -le 65535 ]; then
            breakkk
        elsesese
            colorize red "Please enter a valid port number between 23 and 65535"    colorize red "Please enter a valid port number between 23 and 65535"    colorize red "Please enter a valid port number between 23 and 65535"
            echo        echo        echo
        fififi
    done    done    done

    echo


    # Initialize transport variable    # Initialize transport variable    # Initialize transport variable
    local transport=""
    while [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; dotransport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; dotransport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; do
        echo -ne "[*] Transport type (tcp/tcpmux/utcpmux/ws/wsmux/uwsmux/udp/tcptun/faketcptun): " -ne "[*] Transport type (tcp/tcpmux/utcpmux/ws/wsmux/uwsmux/udp/tcptun/faketcptun): " -ne "[*] Transport type (tcp/tcpmux/utcpmux/ws/wsmux/uwsmux/udp/tcptun/faketcptun): "
        read -r transport

        if [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; then [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; then [[ ! "$transport" =~ ^(tcp|tcpmux|utcpmux|ws|wsmux|uwsmux|udp|tcptun|faketcptun)$ ]]; then
            colorize red "Invalid transport type. Please choose from tcp, tcpmux, utcpmux, ws, wsmux, uwsmux, udp, tcptun, faketcptun."    colorize red "Invalid transport type. Please choose from tcp, tcpmux, utcpmux, ws, wsmux, uwsmux, udp, tcptun, faketcptun."    colorize red "Invalid transport type. Please choose from tcp, tcpmux, utcpmux, ws, wsmux, uwsmux, udp, tcptun, faketcptun."
            echo            echo            echo
        fififi
    done    done    done

    # TUN Device Name 
    local tun_name="backhaul"ckhaul"ckhaul"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; then
        echo
        while true; do
            echo -ne "[-] TUN Device Name (default backhaul): "            echo -ne "[-] TUN Device Name (default backhaul): "            echo -ne "[-] TUN Device Name (default backhaul): "
            read -r tun_name

            if [[ -z "$tun_name" ]]; then[ -z "$tun_name" ]]; then[ -z "$tun_name" ]]; then
                tun_name="backhaul"      tun_name="backhaul"      tun_name="backhaul"
            fi    fi    fi

            if [[ "$tun_name" =~ ^[a-zA-Z0-9]+$ ]]; thenn_name" =~ ^[a-zA-Z0-9]+$ ]]; thenn_name" =~ ^[a-zA-Z0-9]+$ ]]; then
                echo
                break
            elseelseelse
                colorize red "Please enter a valid TUN device name."ze red "Please enter a valid TUN device name."ze red "Please enter a valid TUN device name."
                echo
            fi
        done        done        done
    fi

    # TUN Subnetetet
    local tun_subnet="10.10.10.0/24"    local tun_subnet="10.10.10.0/24"    local tun_subnet="10.10.10.0/24"
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; thenaketcptun" ]]; thenaketcptun" ]]; then
        while true; dododo
            echo -ne "[-] TUN Subnet (default 10.10.10.0/24): ""[-] TUN Subnet (default 10.10.10.0/24): ""[-] TUN Subnet (default 10.10.10.0/24): "
            read -r tun_subnet -r tun_subnet -r tun_subnet

            # Set default value if input is emptyfault value if input is emptyfault value if input is empty
            if [[ -z "$tun_subnet" ]]; then [[ -z "$tun_subnet" ]]; then [[ -z "$tun_subnet" ]]; then
                tun_subnet="10.10.10.0/24"    tun_subnet="10.10.10.0/24"    tun_subnet="10.10.10.0/24"
            fi      fi      fi

            # Validate TUN subnet (CIDR notation)lidate TUN subnet (CIDR notation)lidate TUN subnet (CIDR notation)
            if [[ "$tun_subnet" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then
                # Validate IP and subnet mask
                IFS='/' read -r ip subnet <<< "$tun_subnet"' read -r ip subnet <<< "$tun_subnet"' read -r ip subnet <<< "$tun_subnet"
                if [[ "$subnet" -le 32 && "$subnet" -ge 1 ]]; thenhenhen
                    IFS='.' read -r a b c d <<< "$ip"ad -r a b c d <<< "$ip"ad -r a b c d <<< "$ip"
                    if [[ "$a" -le 255 && "$b" -le 255 && "$c" -le 255 && "$d" -le 255 ]]; then                    if [[ "$a" -le 255 && "$b" -le 255 && "$c" -le 255 && "$d" -le 255 ]]; then                    if [[ "$a" -le 255 && "$b" -le 255 && "$c" -le 255 && "$d" -le 255 ]]; then
                        echo
                        break
                    fi
                fi  fi  fi
            fi            fi            fi

            colorize red "Please enter a valid subnet in CIDR notation (e.g., 10.10.10.0/24)."10.0/24)."10.0/24)."
            echo
        done
    fi

    # TUN MTU
    local mtu="1500"    
    if [[ "$transport" == "tcptun" || "$transport" == "faketcptun" ]]; thenptun" || "$transport" == "faketcptun" ]]; thenptun" || "$transport" == "faketcptun" ]]; then
        while true; do
            echo -ne "[-] TUN MTU (default 1500): "ne "[-] TUN MTU (default 1500): "ne "[-] TUN MTU (default 1500): "
            read -r mtuad -r mtuad -r mtu

            # Set default value if input is empty
            if [[ -z "$mtu" ]]; then[ -z "$mtu" ]]; then[ -z "$mtu" ]]; then
                mtu=1500    mtu=1500    mtu=1500
            fi      fi      fi

            # Validate MTU value Validate MTU value Validate MTU value
            if [[ "$mtu" =~ ^[0-9]+$ ]] && [ "$mtu" -ge 576 ] && [ "$mtu" -le 9000 ]; then =~ ^[0-9]+$ ]] && [ "$mtu" -ge 576 ] && [ "$mtu" -le 9000 ]; then =~ ^[0-9]+$ ]] && [ "$mtu" -ge 576 ] && [ "$mtu" -le 9000 ]; then
                break
            fi

            colorize red "Please enter a valid MTU value between 576 and 9000."d "Please enter a valid MTU value between 576 and 9000."d "Please enter a valid MTU value between 576 and 9000."
            echo            echo            echo
        done
    fi
    

    # Edge IP    # Edge IP    # Edge IP
    if [[ "$transport" =~ ^(ws|wsmux|uwsmux)$ ]]; thensmux|uwsmux)$ ]]; thensmux|uwsmux)$ ]]; then
        while true; do
            echo
            echo -ne "[-] Edge IP/Domain (optional)(press enter to disable): "ho -ne "[-] Edge IP/Domain (optional)(press enter to disable): "ho -ne "[-] Edge IP/Domain (optional)(press enter to disable): "
            read -r edge_ip            read -r edge_ip            read -r edge_ip
    
            # Set default if input is emptyt default if input is emptyt default if input is empty
            if [[ -z "$edge_ip" ]]; thenif [[ -z "$edge_ip" ]]; thenif [[ -z "$edge_ip" ]]; then
                edge_ip="#edge_ip = \"188.114.96.0\""          edge_ip="#edge_ip = \"188.114.96.0\""          edge_ip="#edge_ip = \"188.114.96.0\""
                break            break            break
            fi            fi            fi
    
            # format the edge_ip variable
            edge_ip="edge_ip = \"$edge_ip\""dge_ip = \"$edge_ip\""dge_ip = \"$edge_ip\""
            breakkk
        done
    else
        edge_ip="#edge_ip = \"188.114.96.0\""    edge_ip="#edge_ip = \"188.114.96.0\""    edge_ip="#edge_ip = \"188.114.96.0\""
    fi
    
    echo

    # Security Token Token Token
    echo -ne "[-] Security Token (press enter to use default value): "echo -ne "[-] Security Token (press enter to use default value): "echo -ne "[-] Security Token (press enter to use default value): "
    read -r token
    token="${token:-your_token}"

    # Enable TCP_NODELAY TCP_NODELAY TCP_NODELAY
    local nodelay=""l nodelay=""l nodelay=""
    
    # Check transport typeCheck transport typeCheck transport type
    if [[ "$transport" == "udp" ]]; thenif [[ "$transport" == "udp" ]]; thenif [[ "$transport" == "udp" ]]; then
        nodelay=falsenodelay=falsenodelay=false
    else    else    else
        echo
        while [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; do
            echo -ne "[-] Enable TCP_NODELAY (true/false)(default true): "-ne "[-] Enable TCP_NODELAY (true/false)(default true): "-ne "[-] Enable TCP_NODELAY (true/false)(default true): "
            read -r nodelay
                                    
            if [[ -z "$nodelay" ]]; thenodelay" ]]; thenodelay" ]]; then
                nodelay=truelay=truelay=true
            fi        fi        fi
        
        
            if [[ "$nodelay" != "true" && "$nodelay" != "false" ]]; thenodelay" != "true" && "$nodelay" != "false" ]]; thenodelay" != "true" && "$nodelay" != "false" ]]; then
                colorize red "Invalid input. Please enter 'true' or 'false'."        colorize red "Invalid input. Please enter 'true' or 'false'."        colorize red "Invalid input. Please enter 'true' or 'false'."
                echo    echo    echo
            fi
        done
    fi

	    
    # Connection Pool
    local pool=8=8=8
    if [[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then[ "$transport" != "tcptun" && "$transport" != "faketcptun" ]]; then
    	echo o o 
        while true; do
            echo -ne "[-] Connection Pool (default 8): "
            read -r poolpoolpool

            if [[ -z "$pool" ]]; thenif [[ -z "$pool" ]]; thenif [[ -z "$pool" ]]; then
                pool=8          pool=8          pool=8
            fi            fi            fi
                          
            
            if [[ "$pool" =~ ^[0-9]+$ ]] && [ "$pool" -gt 1 ] && [ "$pool" -le 1024 ]; then[ "$pool" =~ ^[0-9]+$ ]] && [ "$pool" -gt 1 ] && [ "$pool" -le 1024 ]; then[ "$pool" =~ ^[0-9]+$ ]] && [ "$pool" -gt 1 ] && [ "$pool" -le 1024 ]; then
                break
            else  else  else
                colorize red "Please enter a valid connection pool between 1 and 1024."ze red "Please enter a valid connection pool between 1 and 1024."ze red "Please enter a valid connection pool between 1 and 1024."
                echo
            fi
        done        done        done
    fi


    # Mux Versionrsionrsion
    if [[ "$transport" =~ ^(tcpmux|wsmux|utcpmux|uwsmux)$ ]]; thentransport" =~ ^(tcpmux|wsmux|utcpmux|uwsmux)$ ]]; thentransport" =~ ^(tcpmux|wsmux|utcpmux|uwsmux)$ ]]; then
        while true; do
            echo 
            echo -ne "[-] Mux Version (1 or 2) (default 2): " -ne "[-] Mux Version (1 or 2) (default 2): " -ne "[-] Mux Version (1 or 2) (default 2): "
            read -r mux_version
    
            # Set default to 1 if input is emptySet default to 1 if input is emptySet default to 1 if input is empty
            if [[ -z "$mux_version" ]]; thenif [[ -z "$mux_version" ]]; thenif [[ -z "$mux_version" ]]; then
                mux_version=2          mux_version=2          mux_version=2
            fi            fi            fi
                                    
            # Validate the input for version 1 or 2idate the input for version 1 or 2idate the input for version 1 or 2
            if [[ "$mux_version" =~ ^[0-9]+$ ]] && [ "$mux_version" -ge 1 ] && [ "$mux_version" -le 2 ]; then" -ge 1 ] && [ "$mux_version" -le 2 ]; then" -ge 1 ] && [ "$mux_version" -le 2 ]; then
                break
            else
                colorize red "Please enter a valid mux version: 1 or 2."n: 1 or 2."n: 1 or 2."
                echo
            fi        fi        fi
        done
    else
        mux_version=2
    fi
    
    echo
    
	# Enable Sniffer
    local sniffer=""r=""r=""
    while [[ "$sniffer" != "true" && "$sniffer" != "false" ]]; do
        echo -ne "[-] Enable Sniffer (true/false)(default false): "] Enable Sniffer (true/false)(default false): "] Enable Sniffer (true/false)(default false): "
        read -r snifferr snifferr sniffer
        
        if [[ -z "$sniffer" ]]; thenif [[ -z "$sniffer" ]]; thenif [[ -z "$sniffer" ]]; then
            sniffer=falsealsealse
        fi  fi  fi
                            
        if [[ "$sniffer" != "true" && "$sniffer" != "false" ]]; thenif [[ "$sniffer" != "true" && "$sniffer" != "false" ]]; thenif [[ "$sniffer" != "true" && "$sniffer" != "false" ]]; then
            colorize red "Invalid input. Please enter 'true' or 'false'."        colorize red "Invalid input. Please enter 'true' or 'false'."        colorize red "Invalid input. Please enter 'true' or 'false'."
            echo
        fi
    done
	
	echo 
	
    # Get Web Port
	local web_port=""
	while true; doe; doe; do
	    echo -ne "[-] Enter Web Port (default 0 to disable): "e "[-] Enter Web Port (default 0 to disable): "e "[-] Enter Web Port (default 0 to disable): "
	    read -r web_port

        if [[ -z "$web_port" ]]; then "$web_port" ]]; then "$web_port" ]]; then
            web_port=0  web_port=0  web_port=0
        fififi
                      
	    if [[ "$web_port" == "0" ]]; thenf [[ "$web_port" == "0" ]]; thenf [[ "$web_port" == "0" ]]; then
	        break        break        break
	    elif [[ "$web_port" =~ ^[0-9]+$ ]] && ((web_port >= 23 && web_port <= 65535)); then_port" =~ ^[0-9]+$ ]] && ((web_port >= 23 && web_port <= 65535)); then_port" =~ ^[0-9]+$ ]] && ((web_port >= 23 && web_port <= 65535)); then
	        if check_port "$web_port" "tcp"; thenport "$web_port" "tcp"; thenport "$web_port" "tcp"; then
	            colorize red "Port $web_port is already in use. Please choose a different port."lorize red "Port $web_port is already in use. Please choose a different port."lorize red "Port $web_port is already in use. Please choose a different port."
	            echo
	        else
	            break	            break	            break
	        fi
	    else
	        colorize red "Invalid port. Please enter a number between 22 and 65535, or 0 to disable."olorize red "Invalid port. Please enter a number between 22 and 65535, or 0 to disable."olorize red "Invalid port. Please enter a number between 22 and 65535, or 0 to disable."
	        echo echo echo
	    fi
	done

    

    # IP Limit 
    if [[ ! "$transport" =~ ^(ws|udp|tcptun|faketcptun)$ ]]; then$transport" =~ ^(ws|udp|tcptun|faketcptun)$ ]]; then$transport" =~ ^(ws|udp|tcptun|faketcptun)$ ]]; then
        # Enable IP LimitP LimitP Limit
        local ip_limit=""al ip_limit=""al ip_limit=""
        while [[ "$ip_limit" != "true" && "$ip_limit" != "false" ]]; dohile [[ "$ip_limit" != "true" && "$ip_limit" != "false" ]]; dohile [[ "$ip_limit" != "true" && "$ip_limit" != "false" ]]; do
            echo
            echo -ne "[-] Enable IP Limit for X-UI Panel (true/false)(default false): "cho -ne "[-] Enable IP Limit for X-UI Panel (true/false)(default false): "cho -ne "[-] Enable IP Limit for X-UI Panel (true/false)(default false): "
            read -r ip_limit     read -r ip_limit     read -r ip_limit
                          
            if [[ -z "$ip_limit" ]]; then            if [[ -z "$ip_limit" ]]; then            if [[ -z "$ip_limit" ]]; then
                ip_limit=false            ip_limit=false            ip_limit=false
            fi            fi            fi
                  
            if [[ "$ip_limit" != "true" && "$ip_limit" != "false" ]]; then ]]; then ]]; then
                colorize red "Invalid input. Please enter 'true' or 'false'."red "Invalid input. Please enter 'true' or 'false'."red "Invalid input. Please enter 'true' or 'false'."
                echo
            fi
        done
    else
	    # Automatically set proxy_protocol to false for ws and udpxy_protocol to false for ws and udpxy_protocol to false for ws and udp
	    ip_limit="false"t="false"t="false"
	fi


    # Generate client configuration filelient configuration filelient configuration file
    cat << EOF > "${config_dir}/kharej${tunnel_port}.toml"
[client]
remote_addr = "${SERVER_ADDR}:${tunnel_port}"VER_ADDR}:${tunnel_port}"VER_ADDR}:${tunnel_port}"
${edge_ip}
transport = "${transport}""${transport}""${transport}"
token = "${token}""${token}""${token}"
connection_pool = ${pool}
aggressive_pool = falsesese
keepalive_period = 75palive_period = 75palive_period = 75
nodelay = ${nodelay}nodelay = ${nodelay}nodelay = ${nodelay}
retry_interval = 3retry_interval = 3retry_interval = 3
dial_timeout = 10
mux_version = ${mux_version}
mux_framesize = 32768esize = 32768esize = 32768
mux_recievebuffer = 4194304
mux_streambuffer = 2000000buffer = 2000000buffer = 2000000
sniffer = ${sniffer}
web_port = ${web_port}ort}ort}
sniffer_log = "/root/log.json"json"json"
log_level = "info"
ip_limit= ${ip_limit}
tun_name = "${tun_name}"me}"me}"
tun_subnet = "${tun_subnet}"n_subnet}"n_subnet}"
mtu = ${mtu}
EOF


    echo

    # Create the systemd service unit filemd service unit filemd service unit file
    cat << EOF > "${service_dir}/backhaul-kharej${tunnel_port}.service"r}/backhaul-kharej${tunnel_port}.service"r}/backhaul-kharej${tunnel_port}.service"
[Unit]
Description=Backhaul Kharej Port $tunnel_portKharej Port $tunnel_portKharej Port $tunnel_port
After=network.target

[Service]
Type=simplee=simplee=simple
ExecStart=${config_dir}/backhaul_premium -c ${config_dir}/kharej${tunnel_port}.tomlExecStart=${config_dir}/backhaul_premium -c ${config_dir}/kharej${tunnel_port}.tomlExecStart=${config_dir}/backhaul_premium -c ${config_dir}/kharej${tunnel_port}.toml
Restart=alwaysRestart=alwaysRestart=always
RestartSec=3ec=3ec=3

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd to apply new service to apply new service to apply new service
    systemctl daemon-reload >/dev/null 2>&1    systemctl daemon-reload >/dev/null 2>&1    systemctl daemon-reload >/dev/null 2>&1

    # Enable and start the servicee and start the servicee and start the service
    if systemctl enable --now "${service_dir}/backhaul-kharej${tunnel_port}.service" >/dev/null 2>&1; then" >/dev/null 2>&1; then" >/dev/null 2>&1; then
        colorize green "Kharej service with port $tunnel_port enabled to start on boot and started."ze green "Kharej service with port $tunnel_port enabled to start on boot and started."ze green "Kharej service with port $tunnel_port enabled to start on boot and started."
    else
        colorize red "Failed to enable service with port $tunnel_port. Please check your system configuration."        colorize red "Failed to enable service with port $tunnel_port. Please check your system configuration."        colorize red "Failed to enable service with port $tunnel_port. Please check your system configuration."
        return 1eturn 1eturn 1
    fi

    echo    echo    echo
    colorize green "Kharej server configuration completed successfully." boldration completed successfully." boldration completed successfully." bold
}



remove_core(){
	echo
	# If user try to remove core and still a service is running, we should prohibit this.	
	# Check if any .toml file exists.toml file exists.toml file exists
	if find "$config_dir" -type f -name "*.toml" | grep -q .; thennd "$config_dir" -type f -name "*.toml" | grep -q .; thennd "$config_dir" -type f -name "*.toml" | grep -q .; then
	    colorize red "You should delete all services first and then delete the Backhaul-Core."	    colorize red "You should delete all services first and then delete the Backhaul-Core."	    colorize red "You should delete all services first and then delete the Backhaul-Core."
	    sleep 3ep 3ep 3
	    return 1
	elseelseelse
	    colorize cyan "No .toml file found in the directory."	    colorize cyan "No .toml file found in the directory."	    colorize cyan "No .toml file found in the directory."
	fi	fi	fi

	echo
	
	# Prompt to confirm before removing Backhaul-core directory
	colorize yellow "Do you want to remove Backhaul-Core? (y/n)"remove Backhaul-Core? (y/n)"remove Backhaul-Core? (y/n)"
    read -r confirm
	echo     
	if [[ $confirm == [yY] ]]; thenirm == [yY] ]]; thenirm == [yY] ]]; then
	    if [[ -d "$config_dir" ]]; then "$config_dir" ]]; then "$config_dir" ]]; then
	        rm -rf "$config_dir" >/dev/null 2>&1    rm -rf "$config_dir" >/dev/null 2>&1    rm -rf "$config_dir" >/dev/null 2>&1
	        colorize green "Backhaul-Core directory removed." bold bold bold
	    else  else  else
	        colorize red "Backhaul-Core directory not found." bold	        colorize red "Backhaul-Core directory not found." bold	        colorize red "Backhaul-Core directory not found." bold
	    fififi
	elseelseelse
	    colorize yellow "Backhaul-Core removal canceled."
	fi
	
	echo
	press_key
}

# Function for checking tunnel status
check_tunnel_status() {nel_status() {nel_status() {
    echo
    
	# Check for .toml fileseck for .toml fileseck for .toml files
	if ! ls "$config_dir"/*.toml 1> /dev/null 2>&1; then
	    colorize red "No config files found in the Backhaul directory." bold  colorize red "No config files found in the Backhaul directory." bold  colorize red "No config files found in the Backhaul directory." bold
	    echo     echo     echo 
	    press_keypress_keypress_key
	    return 1n 1n 1
	fififi

	clear
    colorize yellow "Checking all services status..." boldecking all services status..." boldecking all services status..." bold
    sleep 1p 1p 1
    echoechoecho
    for config_path in "$config_dir"/iran*.toml; do$config_dir"/iran*.toml; do$config_dir"/iran*.toml; do
        if [ -f "$config_path" ]; then
            # Extract config_name without directory path and change it to service name service name service name
			config_name=$(basename "$config_path")name=$(basename "$config_path")name=$(basename "$config_path")
			config_name="${config_name%.toml}"="${config_name%.toml}"="${config_name%.toml}"
			service_name="backhaul-${config_name}.service"me="backhaul-${config_name}.service"me="backhaul-${config_name}.service"
            config_port="${config_name#iran}"         config_port="${config_name#iran}"         config_port="${config_name#iran}"
                                    
			# Check if the Backhaul-client-kharej service is activeheck if the Backhaul-client-kharej service is activeheck if the Backhaul-client-kharej service is active
			if systemctl is-active --quiet "$service_name"; then
				colorize green "Iran service with tunnel port $config_port is running"e green "Iran service with tunnel port $config_port is running"e green "Iran service with tunnel port $config_port is running"
			else
				colorize red "Iran service with tunnel port $config_port is not running"nfig_port is not running"nfig_port is not running"
			fi
   		fi
    done
    
    for config_path in "$config_dir"/kharej*.toml; do; do; do
        if [ -f "$config_path" ]; then
            # Extract config_name without directory path and change it to service name# Extract config_name without directory path and change it to service name# Extract config_name without directory path and change it to service name
			config_name=$(basename "$config_path")
			config_name="${config_name%.toml}"
			service_name="backhaul-${config_name}.service"
            config_port="${config_name#kharej}"     config_port="${config_name#kharej}"     config_port="${config_name#kharej}"
            
			# Check if the Backhaul-client-kharej service is active           send_email_notification "Tunnel Down: $service_name" "The tunnel $service_name is not running. Please check the logs."Check if the Backhaul-client-kharej service is activeCheck if the Backhaul-client-kharej service is active
			if systemctl is-active --quiet "$service_name"; thentemctl is-active --quiet "$service_name"; thenystemctl is-active --quiet "$service_name"; then
				colorize green "Kharej service with tunnel port $config_port is running"ize green "Kharej service with tunnel port $config_port is running"rize green "Kharej service with tunnel port $config_port is running"
			elsedonelselse
				colorize red "Kharej service with tunnel port $config_port is not running""
			fiharej*.toml; do
   		fi
    done directory path and change it to service name
    th")
    
    echoe"
    press_keyconfig_port="${config_name#kharej}"yy
}
ive

orize green "Kharej service with tunnel port $config_port is running"
# Function for destroying tunnel
tunnel_management() {olorize red "Kharej service with tunnel port $config_port is not running"l_management() {l_management() {
	echo         send_email_notification "Tunnel Down: $service_name" "The tunnel $service_name is not running. Please check the logs."
	# Check for .toml filesr .toml files for .toml files
	if ! ls "$config_dir"/*.toml 1> /dev/null 2>&1; then	fi! ls "$config_dir"/*.toml 1> /dev/null 2>&1; then! ls "$config_dir"/*.toml 1> /dev/null 2>&1; then
	    colorize red "No config files found in the Backhaul directory." bolddone colorize red "No config files found in the Backhaul directory." bold colorize red "No config files found in the Backhaul directory." bold
	    echo 
	    press_key
	    return 1   echo    return 1    return 1
	fi    press_key	fi	fi
	}		
	clear	clear	clear
	colorize cyan "List of existing services to manage:" boldces to manage:" bold
	echo 
	ction for destroying tunnel
	#Variables
    local index=1
    declare -a configs
$config_dir"/*.toml 1> /dev/null 2>&1; then
    for config_path in "$config_dir"/iran*.toml; dored "No config files found in the Backhaul directory." bold_path in "$config_dir"/iran*.toml; do_path in "$config_dir"/iran*.toml; do
        if [ -f "$config_path" ]; then"$config_path" ]; then-f "$config_path" ]; then
            # Extract config_name without directory path  press_key         # Extract config_name without directory path         # Extract config_name without directory path
            config_name=$(basename "$config_path")    return 1           config_name=$(basename "$config_path")           config_name=$(basename "$config_path")
                     
            # Remove "iran" prefix and ".toml" suffix
            config_port="${config_name#iran}"      config_port="${config_name#iran}"      config_port="${config_name#iran}"
            config_port="${config_port%.toml}"colorize cyan "List of existing services to manage:" bold           config_port="${config_port%.toml}"           config_port="${config_port%.toml}"
            
            configs+=("$config_path")th")gs+=("$config_path")
            echo -e "${MAGENTA}${index}${NC}) ${GREEN}Iran${NC} service, Tunnel port: ${YELLOW}$config_port${NC}"index}${NC}) ${GREEN}Iran${NC} service, Tunnel port: ${YELLOW}$config_port${NC}"{MAGENTA}${index}${NC}) ${GREEN}Iran${NC} service, Tunnel port: ${YELLOW}$config_port${NC}"
            ((index++))    local index=1            ((index++))            ((index++))
        fi
    done
    

    # Extract config_name without directory path
    for config_path in "$config_dir"/kharej*.toml; do
        if [ -f "$config_path" ]; then
            # Extract config_name without directory path suffixctory pathctory path
            config_name=$(basename "$config_path")config_port="${config_name#iran}"config_name=$(basename "$config_path")config_name=$(basename "$config_path")
            t%.toml}"
            # Remove "kharej" prefix and ".toml" suffix
            config_port="${config_name#kharej}"$config_path")="${config_name#kharej}"="${config_name#kharej}"
            config_port="${config_port%.toml}"  echo -e "${MAGENTA}${index}${NC}) ${GREEN}Iran${NC} service, Tunnel port: ${YELLOW}$config_port${NC}"  config_port="${config_port%.toml}"  config_port="${config_port%.toml}"
                ((index++))        
            configs+=("$config_path")    fi        configs+=("$config_path")        configs+=("$config_path")
            echo -e "${MAGENTA}${index}${NC}) ${GREEN}Kharej${NC} service, Tunnel port: ${YELLOW}$config_port${NC}"    done            echo -e "${MAGENTA}${index}${NC}) ${GREEN}Kharej${NC} service, Tunnel port: ${YELLOW}$config_port${NC}"            echo -e "${MAGENTA}${index}${NC}) ${GREEN}Kharej${NC} service, Tunnel port: ${YELLOW}$config_port${NC}"
            ((index++))        ((index++))        ((index++))
        fi
    done
    
    echo
    colorize cyan "Additional options:" bold# Extract config_name without directory path cyan "Additional options:" bold cyan "Additional options:" bold
    colorize yellow "R) Restore a backup" bold
    colorize red "0) Back to Main Menu" bold
    echol" suffix
    echo -ne "Enter your choice (0 to return): "config_port="${config_name#kharej}" "Enter your choice (0 to return): " "Enter your choice (0 to return): "
    read choice t%.toml}"
	
	# Check if the user chose to return$config_path")ose to returnose to return
	if [[ "$choice" == "0" ]]; then  echo -e "${MAGENTA}${index}${NC}) ${GREEN}Kharej${NC} service, Tunnel port: ${YELLOW}$config_port${NC}"hoice" == "0" ]]; thenhoice" == "0" ]]; then
	    return    ((index++))urnurn
	fi    fi
	#  validationdationdation
	while ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 0 || choice > ${#configs[@]} )); do dohoice < 0 || choice > ${#configs[@]} )); do
	    colorize red "Invalid choice. Please enter a number between 1 and ${#configs[@]}." bold}." boldr a number between 1 and ${#configs[@]}." bold
	    echo
	    echo -ne "Enter your choice (0 to return): "rize yellow "R) Restore a backup" boldo -ne "Enter your choice (0 to return): "o -ne "Enter your choice (0 to return): "
	    read choice
		if [[ "$choice" == "0" ]]; then ]]; then" == "0" ]]; then
			return   echo -ne "Enter your choice (0 to return): "		return		return
		fi
	done
	 the user chose to return
	selected_config="${configs[$((choice - 1))]}" [[ "$choice" == "0" ]]; thenlected_config="${configs[$((choice - 1))]}"lected_config="${configs[$((choice - 1))]}"
	config_name=$(basename "${selected_config%.toml}")sename "${selected_config%.toml}")(basename "${selected_config%.toml}")
	service_name="backhaul-${config_name}.service"
	  
	clear[[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 0 || choice > ${#configs[@]} )); do
	colorize cyan "List of available commands for $config_name:" bold number between 1 and ${#configs[@]}." boldonfig_name:" boldonfig_name:" bold
	echo 
	colorize red "1) Remove this tunnel"(0 to return): "nel"nel"
	colorize yellow "2) Restart this tunnel" choice yellow "2) Restart this tunnel" yellow "2) Restart this tunnel"
	colorize reset "3) View service logs" [[ "$choice" == "0" ]]; thenorize reset "3) View service logs"orize reset "3) View service logs"
	colorize reset "4) View service status"turnrize reset "4) View service status"rize reset "4) View service status"
	colorize red "0) Back to Main Menu" bold	ficolorize red "0) Back to Main Menu" boldcolorize red "0) Back to Main Menu" bold
	echo 
	read -p "Enter your choice (0 to return): " choice
	
    case $choice innfig_name=$(basename "${selected_config%.toml}") case $choice in case $choice in
        1) destroy_tunnel "$selected_config" ;;ce_name="backhaul-${config_name}.service"  1) destroy_tunnel "$selected_config" ;;  1) destroy_tunnel "$selected_config" ;;
        2) restart_service "$service_name" ;;
        3) view_service_logs "$service_name" ;;  3) view_service_logs "$service_name" ;;  3) view_service_logs "$service_name" ;;
        4) view_service_status "$service_name" ;;mands for $config_name:" boldice_name" ;;ice_name" ;;
        0) return ;;
        *) echo -e "${RED}Invalid option!${NC}" && sleep 1 && return 1;;n!${NC}" && sleep 1 && return 1;;on!${NC}" && sleep 1 && return 1;;
    esac"
	
}ize reset "4) View service status"

echo 
r choice (0 to return): " choice
destroy_tunnel(){
	#Vaiables
	config_path="$1"
	config_name=$(basename "${config_path%.toml}")
    service_name="backhaul-${config_name}.service"ice_logs "$service_name" ;;ckhaul-${config_name}.service"ckhaul-${config_name}.service"
    service_path="$service_dir/$service_name"
    0) return ;;
	# Check if config exists and delete it       *) echo -e "${RED}Invalid option!${NC}" && sleep 1 && return 1;;# Check if config exists and delete it# Check if config exists and delete it
	if [ -f "$config_path" ]; then   esacif [ -f "$config_path" ]; thenif [ -f "$config_path" ]; then
	  rm -f "$config_path" >/dev/null 2>&1		  rm -f "$config_path" >/dev/null 2>&1	  rm -f "$config_path" >/dev/null 2>&1
	fi}	fi	fi

    
    # Stop and disable the client service if it existsle the client service if it exists and disable the client service if it exists
    if [[ -f "$service_path" ]]; thenrvice_path" ]]; thenrvice_path" ]]; then
        if systemctl is-active "$service_name" &>/dev/null; then
            systemctl disable --now "$service_name" >/dev/null 2>&11
        fi")
        rm -f "$service_path" >/dev/null 2>&1service_name="backhaul-${config_name}.service"    rm -f "$service_path" >/dev/null 2>&1    rm -f "$service_path" >/dev/null 2>&1
    fi_name"
    
        
    echo [ -f "$config_path" ]; then echo echo
    # Reload systemd to read the new unit file	  rm -f "$config_path" >/dev/null 2>&1    # Reload systemd to read the new unit file    # Reload systemd to read the new unit file
    if systemctl daemon-reload >/dev/null 2>&1 ; thenf systemctl daemon-reload >/dev/null 2>&1 ; thenif systemctl daemon-reload >/dev/null 2>&1 ; then
        echo -e "Systemd daemon reloaded.\n"
    else
        echo -e "${RED}Failed to reload systemd daemon. Please check your system configuration.${NC}"system configuration.${NC}"heck your system configuration.${NC}"
    fi
     systemctl is-active "$service_name" &>/dev/null; then
    colorize green "Tunnel destroyed successfully!" bold_name" >/dev/null 2>&1ully!" boldully!" bold
    echo  fihoho
    press_key    rm -f "$service_path" >/dev/null 2>&1press_keypress_key
}


#Function to restart services
restart_service() {le
    echoystemctl daemon-reload >/dev/null 2>&1 ; then
    service_name="$1"
    colorize yellow "Restarting $service_name" boldselorize yellow "Restarting $service_name" boldlorize yellow "Restarting $service_name" bold
    echo    echo -e "${RED}Failed to reload systemd daemon. Please check your system configuration.${NC}"echoecho
    
    # Check if service existsif service existseck if service exists
    if systemctl list-units --type=service | grep -q "$service_name"; thengreen "Tunnel destroyed successfully!" boldctl list-units --type=service | grep -q "$service_name"; thenctl list-units --type=service | grep -q "$service_name"; then
        systemctl restart "$service_name"   echo       systemctl restart "$service_name"       systemctl restart "$service_name"
        colorize green "Service restarted successfully" bold    press_key        colorize green "Service restarted successfully" bold        colorize green "Service restarted successfully" bold
}
    else
        colorize red "Cannot restart the service" he service" d "Cannot restart the service" 
    fin to restart services
    echo
    press_key
}ice_name="$1"
colorize yellow "Restarting $service_name" bold
view_service_logs (){
	clear
	journalctl -eu "$1" -f
    press_keyce_name"; then
}        systemctl restart "$service_name"}}
colorize green "Service restarted successfully" bold
view_service_status (){
	clearse
	systemctl status "$1"colorize red "Cannot restart the service" tl status "$1"tl status "$1"
    press_key
}   echo
    press_key
check_core_version() {
    local url=$1l=$1cal url=$1
    local tmp_file=$(mktemp)mp)temp)

    # Download the file to a temporary locationjournalctl -eu "$1" -f   # Download the file to a temporary location   # Download the file to a temporary location
    curl -s -o "$tmp_file" "$url"    press_key    curl -s -o "$tmp_file" "$url"    curl -s -o "$tmp_file" "$url"

    # Check if the download was successfulif the download was successfulCheck if the download was successful
    if [ $? -ne 0 ]; then{henhen
        colorize red "Failed to check latest core version" "Failed to check latest core version"ize red "Failed to check latest core version"
        return 1systemctl status "$1"       return 1       return 1
    fi    press_key    fi    fi

    # Read the version from the downloaded file (assumes the version is stored on the first line)downloaded file (assumes the version is stored on the first line)ersion from the downloaded file (assumes the version is stored on the first line)
    local file_version=$(head -n 1 "$tmp_file") "$tmp_file")d -n 1 "$tmp_file")
    local url=$1
    # Get the version from the backhaul_premium binary using the -v flagv flag binary using the -v flag
    local backhaul_version=$($config_dir/backhaul_premium -v)ir/backhaul_premium -v)
    # Download the file to a temporary location
    # Compare the file version with the version from backhaul_premiumm backhaul_premiumrsion from backhaul_premium
    if [ "$file_version" != "$backhaul_version" ]; then then!= "$backhaul_version" ]; then
        colorize cyan "New Core version available: $backhaul_version => $file_version" boldile_version" boldul_version => $file_version" bold
    fi0 ]; then
  colorize red "Failed to check latest core version"
    # Clean up the temporary file        return 1    # Clean up the temporary file    # Clean up the temporary file
    rm "$tmp_file"
}
    # Read the version from the downloaded file (assumes the version is stored on the first line)
check_script_version() {
    local url=$1
    local tmp_file=$(mktemp)    # Get the version from the backhaul_premium binary using the -v flag    local tmp_file=$(mktemp)    local tmp_file=$(mktemp)

    # Download the file to a temporary location
    curl -s -o "$tmp_file" "$url"
 [ "$file_version" != "$backhaul_version" ]; then
    # Check if the download was successful        colorize cyan "New Core version available: $backhaul_version => $file_version" bold    # Check if the download was successful    # Check if the download was successful
    if [ $? -ne 0 ]; then
        colorize red "Failed to check latest script version"k latest script version"ed "Failed to check latest script version"
        return 1   # Clean up the temporary file       return 1       return 1
    fi    rm "$tmp_file"    fi    fi

    # Read the version from the downloaded file (assumes the version is stored on the first line)downloaded file (assumes the version is stored on the first line)ersion from the downloaded file (assumes the version is stored on the first line)
    local file_version=$(head -n 1 "$tmp_file") 1 "$tmp_file")d -n 1 "$tmp_file")
    local url=$1
    # Compare the file version with the version from backhaul_premiumium from backhaul_premium
    if [ "$file_version" != "$SCRIPT_VERSION" ]; then]; then
        colorize cyan "New script version available: $SCRIPT_VERSION => $file_version" bold    # Download the file to a temporary location        colorize cyan "New script version available: $SCRIPT_VERSION => $file_version" bold        colorize cyan "New script version available: $SCRIPT_VERSION => $file_version" bold
    fi

    # Clean up the temporary file
    rm "$tmp_file"0 ]; thene"e"
}  colorize red "Failed to check latest script version"
        return 1

update_script(){
# Define the destination path    # Read the version from the downloaded file (assumes the version is stored on the first line)# Define the destination path# Define the destination path
DEST_DIR="/usr/bin/"
BACKHAUL_SCRIPT="backhaul"
SCRIPT_URL="https://raw.githubusercontent.com/wafflenoodle/zenith-stash/refs/heads/main/backhaul.sh"
 [ "$file_version" != "$SCRIPT_VERSION" ]; then
echo        colorize cyan "New script version available: $SCRIPT_VERSION => $file_version" boldechoecho
# Check if backhaul.sh exists in /bin/bash
if [ -f "$DEST_DIR/$BACKHAUL_SCRIPT" ]; then ]; then/$BACKHAUL_SCRIPT" ]; then
    # Remove the existing rathole   # Clean up the temporary file   # Remove the existing rathole   # Remove the existing rathole
    rm "$DEST_DIR/$BACKHAUL_SCRIPT"    rm "$tmp_file"    rm "$DEST_DIR/$BACKHAUL_SCRIPT"    rm "$DEST_DIR/$BACKHAUL_SCRIPT"
    if [ $? -eq 0 ]; then}    if [ $? -eq 0 ]; then    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Existing $BACKHAUL_SCRIPT has been successfully removed from $DEST_DIR.${NC}"g $BACKHAUL_SCRIPT has been successfully removed from $DEST_DIR.${NC}""${GREEN}Existing $BACKHAUL_SCRIPT has been successfully removed from $DEST_DIR.${NC}"
    else
        echo -e "${RED}Failed to remove existing $BACKHAUL_SCRIPT from $DEST_DIR.${NC}"ailed to remove existing $BACKHAUL_SCRIPT from $DEST_DIR.${NC}"ED}Failed to remove existing $BACKHAUL_SCRIPT from $DEST_DIR.${NC}"
        sleep 1ath
        return 1
    fiBACKHAUL_SCRIPT="backhaul"    fi    fi
elsePT_URL="https://raw.githubusercontent.com/wafflenoodle/zenith-stash/refs/heads/main/backhaul.sh"
    echo -e "${YELLOW}$BACKHAUL_SCRIPT does not exist in $DEST_DIR. No need to remove.${NC}"e.${NC}"s not exist in $DEST_DIR. No need to remove.${NC}"
fi
/bin/bash
# Download the new backhaul.sh from the GitHub URL" ]; then the GitHub URL the GitHub URL
curl -s -L -o "$DEST_DIR/$BACKHAUL_SCRIPT" "$SCRIPT_URL" rathole$BACKHAUL_SCRIPT" "$SCRIPT_URL"$BACKHAUL_SCRIPT" "$SCRIPT_URL"

echo $? -eq 0 ]; then
if [ $? -eq 0 ]; thenDEST_DIR.${NC}"
    chmod +x "$DEST_DIR/$BACKHAUL_SCRIPT"R/$BACKHAUL_SCRIPT"DEST_DIR/$BACKHAUL_SCRIPT"
    colorize yellow "Type 'backhaul' to run the script.\n" bold"${RED}Failed to remove existing $BACKHAUL_SCRIPT from $DEST_DIR.${NC}"low "Type 'backhaul' to run the script.\n" boldlow "Type 'backhaul' to run the script.\n" bold
    colorize yellow "For removing script type: rm -rf /usr/bin/backhaul\n" bold  sleep 1lorize yellow "For removing script type: rm -rf /usr/bin/backhaul\n" boldlorize yellow "For removing script type: rm -rf /usr/bin/backhaul\n" bold
    press_key    return 1press_keypress_key
    exit 0
elsesesese
    echo -e "${RED}Failed to download $BACKHAUL_SCRIPT from $SCRIPT_URL.${NC}"    echo -e "${YELLOW}$BACKHAUL_SCRIPT does not exist in $DEST_DIR. No need to remove.${NC}"    echo -e "${RED}Failed to download $BACKHAUL_SCRIPT from $SCRIPT_URL.${NC}"    echo -e "${RED}Failed to download $BACKHAUL_SCRIPT from $SCRIPT_URL.${NC}"
    sleep 1
    return 1
fi# Download the new backhaul.sh from the GitHub URLfifi
 -s -L -o "$DEST_DIR/$BACKHAUL_SCRIPT" "$SCRIPT_URL"
}

# Function to auto-update the script
auto_update_script() {
    local latest_version=$(curl -s "https://example.com/latest_version.txt")yellow "Type 'backhaul' to run the script.\n" boldhboard_dir="/var/www/backhaul-dashboard"kup_dir="${config_dir}/backups"
    if [[ "$SCRIPT_VERSION" != "$latest_version" ]]; thenze yellow "For removing script type: rm -rf /usr/bin/backhaul\n" bold-p "$dashboard_dir"-p "$backup_dir"
        echo "Updating script to version $latest_version..."press_keyl timestamp=$(date +"%Y%m%d%H%M%S")
        curl -s -o "/usr/bin/backhaul" "https://example.com/backhaul.sh"
        chmod +x "/usr/bin/backhaul" "$dashboard_dir/index.html"f "$backup_file" -C "$config_dir" .
        echo "Script updated successfully.""${RED}Failed to download $BACKHAUL_SCRIPT from $SCRIPT_URL.${NC}"ml> green "Backup created: $backup_file" bold
    else  sleep 1tml>
        echo "You are already using the latest version."    return 1<head>
    fii   <title>Backhaul Dashboard</title> Function to restore a backup
}    <style>restore_configurations() {
y: Arial, sans-serif; margin: 20px; } monitor system resources in real-timekup_dir="${config_dir}/backups"
# Color codes) {$backup_dir" ]]; then
RED='\033[0;31m'100%; border-collapse: collapse; margin-top: 20px; }ckups found." bold
GREEN='\033[0;32m'ng: 10px; border: 1px solid #ddd; text-align: left; }Real-Time System Monitoring (Press Ctrl+C to exit)\e[0m"
YELLOW='\033[0;33m';32m'background-color: #f4f4f4; }e; do
CYAN='\e[36m'3m'e[1;36mCPU Usage:\e[0m $(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')%"
MAGENTA="\e[95m"e -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')"
NC='\033[0m' # No ColorMAGENTA="\e[95m"<body>        echo -e "\e[1;36mDisk Usage:\e[0m $(df -h | awk '$NF=="/"{printf "%s", $5}')"    colorize cyan "Available backups:" bold
1>etwork Traffic:\e[0m $(ifstat -t 1 1 | tail -n 1)"nl
# Function to display menu
display_menu() {n to display menuthead>lear-p "Enter the number of the backup to restore (or 0 to cancel): " choice
    clear
    display_logo
    display_server_info
    display_backhaul_core_statusdisplay_server_info            <th>Actions</th>lor codes    return 0
    lay_backhaul_core_status    </tr>3[0;31m'
    echo
    echo -e "\e[93m═══════════════════════════════════════════════════════════════════════\e[0m"
    echo -e " \e[1;36mMAIN MENU\e[0m"
    echo -e "\e[93m═══════════════════════════════════════════════════════════════════════\e[0m"
    echo -e " \e[1;32m1)\e[0m Configure a new tunnel [IPv4/IPv6]"═════════════════════════════════════\e[0m"
    echo -e " \e[1;31m2)\e[0m Tunnel management menu"l [IPv4/IPv6]"n>Stop</button></td>
    echo -e " \e[1;36m3)\e[0m Check tunnels status" menu"
    echo -e " \e[1;33m4)\e[0m Advanced Options"
    echo -e " \e[1;35m5)\e[0m Update & Install Backhaul Core"
    echo -e " \e[1;34m6)\e[0m Update & Install Script"haul Core"
    echo -e " \e[1;31m7)\e[0m Remove Backhaul Core"e & Install Script"
    echo -e " \e[1;31m0)\e[0m Exit"
    echo -e "\e[93m═══════════════════════════════════════════════════════════════════════\e[0m"   echo -e " \e[1;31m0)\e[0m Exit"  ED='\033[0;31m'
}    echo -e "\e[93m═══════════════════════════════════════════════════════════════════════\e[0m"    echo "Dashboard installed at $dashboard_dir/index.html"    echoGREEN='\033[0;32m'

# Function to display advanced options menu
display_advanced_menu() {n to display advanced options menuodes-e "\e[93m═══════════════════════════════════════════════════════════════════════\e[0m"\e[95m"
    clear
    echo -e "\e[93m═══════════════════════════════════════════════════════════════════════\e[0m"
    echo -e " \e[1;36mADVANCED OPTIONS\e[0m"
    echo -e "\e[93m═══════════════════════════════════════════════════════════════════════\e[0m"
    echo -e " \e[1;32m1)\e[0m View Service Logs"════════════════════════════════════════\e[0m"
    echo -e " \e[1;33m2)\e[0m View Service Status"
    echo -e " \e[1;34m3)\e[0m Check Core Version"
    echo -e " \e[1;35m4)\e[0m Check Script Version""
    echo -e " \e[1;36m8)\e[0m Auto-Update Script"
    echo -e " \e[1;31m0)\e[0m Back to Main Menu"   echo -e " \e[1;31m0)\e[0m Back to Main Menu"   clear   echo
    echo -e "\e[93m═══════════════════════════════════════════════════════════════════════\e[0m"    echo -e "\e[93m═══════════════════════════════════════════════════════════════════════\e[0m"    display_logo    echo -e "\e[93m═══════════════════════════════════════════════════════════════════════\e[0m"
}
═══════════════════════════════════════\e[0m"
# Function to handle advanced optionsle advanced options new tunnel [IPv4/IPv6]"
handle_advanced_options() {══════════════════════════════════════\e[0m" Tunnel management menu"
    while true; do
        display_advanced_menum"══════════════════════════════════════════════════════════\e[0m"vanced Options"
        read -p "Enter your choice [0-8]: " advanced_choice "Enter your choice [0-4]: " advanced_choice[93m═══════════════════════════════════════════════════════════════════════\e[0m"e[1;32m1)\e[0m View Service Logs"e[1;35m5)\e[0m Update & Install Backhaul Core"
        case $advanced_choice in
            1) 
                echo -e "\n\e[1;36mEnter the service name to view logs:\e[0m"ice name to view logs:\e[0m"s"n"
                read -p "Service Name: " service_namead -p "Service Name: " service_name;33m4)\e[0m Advanced Options";36m7)\e[0m Monitor System Resources"m═══════════════════════════════════════════════════════════════════════\e[0m"
                view_service_logs "$service_name" view_service_logs "$service_name"e[1;35m5)\e[0m Update & Install Backhaul Core"e[1;31m0)\e[0m Back to Main Menu"
                ;;
            2) 
                echo -e "\n\e[1;36mEnter the service name to view status:\e[0m"e name to view status:\e[0m""
                read -p "Service Name: " service_namead -p "Service Name: " service_name;31m0)\e[0m Exit"le advanced options
                view_service_status "$service_name" view_service_status "$service_name"[93m═══════════════════════════════════════════════════════════════════════\e[0m"_options() {[93m═══════════════════════════════════════════════════════════════════════\e[0m"
                ;;
            3) 
                echo -e "\n\e[1;36mChecking Core Version...\e[0m"\n\e[1;36mChecking Core Version...\e[0m"anced options menuur choice [0-4]: " advanced_choicee[0m View Service Logs"
                check_core_version "https://example.com/core_version.txt"eck_core_version "https://example.com/core_version.txt"enu() {nced_choice in;33m2)\e[0m View Service Status"
                press_key press_keym3)\e[0m Check Core Version"
                ;;
            4) 
                echo -e "\n\e[1;36mChecking Script Version...\e[0m"\n\e[1;36mChecking Script Version...\e[0m"═════════════════════════════════════════════════════════════════\e[0m"ice_logs "$service_name"e[0m Restore Configurations"
                check_script_version "https://example.com/script_version.txt"eck_script_version "https://example.com/script_version.txt";32m1)\e[0m View Service Logs";31m0)\e[0m Back to Main Menu"
                press_key press_keye[1;33m2)\e[0m View Service Status"[93m═══════════════════════════════════════════════════════════════════════\e[0m"
                ;;[0m Check Core Version"e "\n\e[1;36mEnter the service name to view status:\e[0m"
            8) auto_update_script ;;m4)\e[0m Check Script Version"ad -p "Service Name: " service_name
            0)  returne[1;31m0)\e[0m Back to Main Menu" view_service_status "$service_name"andle advanced options
                return
                ;;
            *) ho -e "\e[1;31mInvalid option! Please try again.\e[0m"hecking Core Version...\e[0m"vanced_menu
                echo -e "\e[1;31mInvalid option! Please try again.\e[0m"    sleep 1o handle advanced options    check_core_version "https://example.com/core_version.txt" -p "Enter your choice [0-6]: " advanced_choice
                sleep 1        ;;dvanced_options() {        press_keycase $advanced_choice in
                ;;       esac   while true; do               ;;           1) 
        esac    done        display_advanced_menu            4)                 echo -e "\n\e[1;36mEnter the service name to view logs:\e[0m"
    donece[1;36mChecking Script Version...\e[0m"ice Name: " service_name
}in check_script_version "https://example.com/script_version.txt" view_service_logs "$service_name"

# Function to read user input "\n\e[1;36mEnter the service name to view logs:\e[0m"
read_option() { [0-7]: " choicece Name: " service_namees ;;1;36mEnter the service name to view status:\e[0m"
    read -p "Enter your choice [0-7]: " choice_name"e_name
    case $choice in
        1) configure_tunnel ;;
        2) tunnel_management ;;tatus:\e[0m"
        3) check_tunnel_status ;;options ;;rvice Name: " service_name[1;31mInvalid option! Please try again.\e[0m"\e[1;36mChecking Core Version...\e[0m"
        4) handle_advanced_options ;;xtract_backhaul "menu" ;;ice_status "$service_name"version "https://example.com/core_version.txt"
        5) download_and_extract_backhaul "menu" ;;ript ;;y
        6) update_script ;;
        7) remove_core ;;0) exit 0 ;;        echo -e "\n\e[1;36mChecking Core Version...\e[0m"    4) 
        0) exit 0 ;;       *) echo -e "\e[1;31mInvalid option! Please try again.\e[0m" && sleep 1 ;;               check_core_version "https://example.com/core_version.txt"               echo -e "\n\e[1;36mChecking Script Version...\e[0m"
        *) echo -e "\e[1;31mInvalid option! Please try again.\e[0m" && sleep 1 ;;    esac                press_key                check_script_version "https://example.com/script_version.txt"
    esacser input   press_key
}      ;;
Function to send email notifications              echo -e "\n\e[1;36mChecking Script Version...\e[0m"  read -p "Enter your choice [0-7]: " choice          5) 
# Main scriptication() {check_script_version "https://example.com/script_version.txt" inecho -e "\n\e[1;36mBacking up configurations...\e[0m"
while truect="$1" press_keyigure_tunnel ;; backup_configurations
dolocal message="$2"            ;;    2) tunnel_management ;;            press_key
    display_menu    local recipient="admin@example.com"            0)         3) check_tunnel_status ;;                ;;



done    read_option









done    read_option    display_menudowhile true# Main script}    echo "$message" | mail -s "$subject" "$recipient"

































done    read_option    display_menudowhile true# Main script}    esac        *) echo -e "\e[1;31mInvalid option! Please try again.\e[0m" && sleep 1 ;;        0) exit 0 ;;        8) install_dashboard ;;        7) remove_core ;;        6) update_script ;;        5) download_and_extract_backhaul "menu" ;;        4) handle_advanced_options ;;        3) check_tunnel_status ;;        2) tunnel_management ;;        1) configure_tunnel ;;    case $choice in    read -p "Enter your choice [0-8]: " choiceread_option() {# Function to read user input}    done        esac                ;;                sleep 1                echo -e "\e[1;31mInvalid option! Please try again.\e[0m"            *)                 ;;                return















done    read_option    display_menudowhile true# Main script}    esac        *) echo -e "\e[1;31mInvalid option! Please try again.\e[0m" && sleep 1 ;;        0) exit 0 ;;        7) remove_core ;;        6) update_script ;;        5) download_and_extract_backhaul "menu" ;;        4) handle_advanced_options ;;            6) 
                echo -e "\n\e[1;36mRestoring configurations...\e[0m"
                restore_configurations
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

# Function to read user input
read_option() {
    read -p "Enter your choice [0-7]: " choice
    case $choice in
        1) configure_tunnel ;;
        2) tunnel_management ;;
        3) check_tunnel_status ;;
        4) handle_advanced_options ;;
        5) download_and_extract_backhaul "menu" ;;
        6) update_script ;;
        7) remove_core ;;
        0) exit 0 ;;
        *) echo -e "\e[1;31mInvalid option! Please try again.\e[0m" && sleep 1 ;;
    esac
}

# Main script
while true
do
    display_menu
    read_option
done
