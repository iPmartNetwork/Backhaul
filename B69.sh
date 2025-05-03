# ─── Script Info ───────────────────────────────────────────
script_version="2.1.0"
script_author="iPmart Network | Ali Hassanzadeh"
script_date="2025-05-03"


INDIGO="\033[38;5;44m"
PURPLE="\033[38;5;135m"
YELLOW="\033[38;5;226m"
NC="\033[0m"


config_dir="/etc/backhaul"
service_dir="/etc/systemd/system"

log_action() { echo "[LOG] $1"; }
log_detailed() { echo "[DETAIL] $1 - $2"; }
press_key() { read -rp "Press Enter to continue..."; }


colorize() {
    local color="$1"
    local text="$2"
    local style="$3"

    case "$color" in
        purple) code="\e[35m" ;;
        indigo) code="\e[94m" ;;
        yellow) code="\e[93m" ;;
        reset)  code="\e[0m"  ;;
        *) code="\e[0m" ;;
    esac

    [[ "$style" == "bold" ]] && code="\e[1m$code"
    echo -e "${code}${text}\e[0m"
}

if [[ "$1" == "--version" ]]; then
    echo "📜 Backhaul Script Version: $script_version"
    echo "👤 Author: $script_author"
    echo "🗓  Release Date: $script_date"
    exit 0
fi
# ───────────────────────────────────────────────────────────

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
    read -p "Enter your choice (or M to return to Main Menu): " configure_choice
    [[ "$configure_choice" =~ ^[Mm]$ ]] && return
    case "$configure_choice" in
        1) iran_server_configuration ;;
        2) kharej_server_configuration ;;
        *) echo -e "${PURPLE}Invalid option!${NC}" && sleep 1 ;;
    esac
    echo
    read -p "Press Enter to continue..."
}

iran_server_configuration() {
    clear
    colorize purple "Configuring IRAN server" bold

    echo




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
    log_detailed "CREATE" "IRAN tunnel created on port $tunnel_port with transport $transport"
    colorize indigo "IRAN server configuration completed successfully." bold
}


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
    log_detailed "CREATE" "KHAREJ tunnel created to $SERVER_ADDR:$tunnel_port with transport $transport"
    colorize indigo "Kharej server configuration completed successfully." bold
}

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
    colorize indigo "✅ $config_name service with tunnel port $config_port is running"
else
    colorize purple "❌ $config_name service with tunnel port $config_port is NOT running"
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
    colorize indigo "✅ $config_name service with tunnel port $config_port is running"
else
    colorize purple "❌ $config_name service with tunnel port $config_port is NOT running"
fi

   		fi
    done


    echo
    press_key
}

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
colorize purple "─────────────── Available Actions ───────────────" bold
	colorize indigo "1) 🗑 Remove this tunnel"
	colorize indigo "2) 🔄 Restart this tunnel"
	colorize indigo "3) 📜 View service logs"
	colorize indigo "4) 🔍 View service status"
	colorize yellow "5) ✏️ Edit tunnel configuration"
	echo
	read -p "Enter your choice (0 to return): " choice

    case $choice in
                1) destroy_tunnel "$selected_config" ;;
        2) restart_service "$service_name" ;;
        3) view_service_logs "$service_name" ;;
        4) view_service_status "$service_name" ;;
    5) edit_tunnel "$selected_config" ;;
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
    log_detailed "DESTROY" "Tunnel $config_name removed and service $service_name disabled"
    colorize indigo "Tunnel destroyed successfully!" bold
    echo
    press_key
}

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



edit_tunnel() {
    config_path="$1"
    if [[ -f "$config_path" ]]; then
        backup_config_file "$config_path"
        nano "$config_path"
        systemctl restart "backhaul-$(basename "${config_path%.toml}").service"
        colorize indigo "Tunnel restarted after editing." bold
    else
        colorize purple "Configuration file not found." bold
    fi
    echo
    press_key
}



show_header() {
    clear
    
    echo "╔══════════════════════════════════════════════════╗"
    echo "║            🚀 Backhaul Tunnel Manager           ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║ 📜 Version : $script_version                             ║"
    echo "║ 👤 Author  : $script_author                         ║"
    echo "║ 🗓  Date    : $script_date                             ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "📂 Script Path: $(realpath "$0")"
    echo -e "🕒 Executed at: $(date '+%Y-%m-%d %H:%M:%S')"
    
}






core_manager() {
    while true; do
        echo "╔═════════════════════╗"
        echo "║   ⚙️  Core Manager    ║"
        echo "╚═════════════════════╝"
        echo "1) Install Backhaul Core"
        echo "2) Update Backhaul Core"
        echo "3) Remove Backhaul Core"
        echo "M) Return to Main Menu"
        read -rp "Enter your choice: " core_choice
        [[ "$core_choice" =~ ^[Mm]$ ]] && return

        case "$core_choice" in
            1) install_backhaul_core ;;
            2) update_backhaul_core ;;
            3) remove_backhaul_core ;;
            *) echo "Invalid option. Try again." ;;
        esac

        read -rp "Press Enter to continue..." pause
    done
}

install_backhaul_core() {
    echo "[+] Installing Backhaul Core..."
    mkdir -p /etc/backhaul
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        URL="https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz"
    elif [[ "$ARCH" == "aarch64" ]]; then
        URL="https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_arm64.tar.gz"
    else
        echo "Unsupported architecture: $ARCH"
        return 1
    fi

    TMP_DIR=$(mktemp -d)
    curl -fsSL "$URL" -o "$TMP_DIR/backhaul.tar.gz"
    tar -xzf "$TMP_DIR/backhaul.tar.gz" -C "$TMP_DIR"
    mv "$TMP_DIR/backhaul" /etc/backhaul/backhaul-core
    chmod +x /etc/backhaul/backhaul-core
    rm -rf "$TMP_DIR"
    echo "[✓] Backhaul Core installed at /etc/backhaul/backhaul-core"
}

update_backhaul_core() {
    if [[ ! -f "$config_dir/backhaul" ]]; then
        colorize purple "Backhaul Core not found. Please install it first."
        return
    fi

    rm -f "$config_dir/backhaul"
    install_backhaul_core
}

remove_backhaul_core() {
    if [[ -f "$config_dir/backhaul" ]]; then
        rm -f "$config_dir/backhaul"
        colorize indigo "Backhaul Core removed."
    else
        colorize purple "Backhaul Core is not installed."
    fi
}




optimize_system() {
    clear
    colorize indigo "🚀 Optimizing System for Low Latency & High Performance..." bold
    echo

    # Enable BBR congestion control
    if grep -q "bbr" /proc/sys/net/ipv4/tcp_congestion_control; then
        colorize yellow "BBR already enabled."
    else
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p >/dev/null 2>&1
        colorize indigo "BBR enabled via sysctl."
    fi

    # Optimize sysctl for networking
    cat <<EOF >> /etc/sysctl.conf

# Backhaul Network Optimization
net.core.rmem_max=2500000
net.core.wmem_max=2500000
net.ipv4.tcp_rmem=4096 87380 2500000
net.ipv4.tcp_wmem=4096 65536 2500000
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_no_metrics_save=1
EOF

    sysctl -p >/dev/null 2>&1

    # Set high ulimit for open files
    ulimit -n 1048576
    echo -e "* soft nofile 1048576
* hard nofile 1048576" >> /etc/security/limits.conf
    echo -e "ulimit -n 1048576" >> ~/.bashrc

    colorize indigo "System optimization applied successfully!" bold
    echo
    press_key
}




update_script() {
    clear
    colorize indigo "♻️ Updating Backhaul Script..." bold
    echo

    local remote_url="https://raw.githubusercontent.com/iPmartNetwork/Backhaul/master/backhaul.sh"
    local script_path="$(realpath "$0")"
    local backup_path="${script_path}.bak"

    # Backup current version
    cp "$script_path" "$backup_path"
    colorize yellow "Backup created at $backup_path"

    # Try downloading new script
    if curl -fsSL "$remote_url" -o "$script_path"; then
        chmod +x "$script_path"
        colorize indigo "✅ Script updated successfully from:"
        echo -e "${YELLOW}$remote_url${NC}"
        echo
        read -rp "Press Enter to restart the script..." enter
[[ "$enter" =~ ^[Mm]$ ]] && returnexec "$script_path"
    else
        colorize purple "❌ Failed to update script. Reverting to previous version..."
        mv "$backup_path" "$script_path"
        chmod +x "$script_path"
    fi
    echo
    press_key
}




web_panel_manager() {
    while true; do
        clear
        echo "╔═══════════════════════╗"
        echo "║   🌐 Web Panel Menu    ║"
        echo "╚═══════════════════════╝"
        echo "1) Install Web Panel"
        echo "2) Remove Web Panel"
        echo "M) Return to Main Menu"
        read -rp "Enter your choice: " wp_choice
        [[ "$wp_choice" =~ ^[Mm]$ ]] && return
        case "$wp_choice" in
            1) install_web_panel ;;
            2) remove_web_panel ;;
            *) echo "Invalid option. Try again."; sleep 1 ;;
        esac
        read -rp "Press Enter to continue..." pause
    done
}

install_web_panel() {
    colorize indigo "Installing Web Panel..." bold
    apt update -y && apt install -y python3 python3-pip
    pip3 install flask >/dev/null 2>&1

    mkdir -p /opt/backhaul-panel
    cat <<EOF > /opt/backhaul-panel/panel.py
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "✅ Backhaul Web Panel is Running!"

app.run(host="0.0.0.0", port=9090)
EOF

    cat <<EOF > /etc/systemd/system/backhaul-panel.service
[Unit]
Description=Backhaul Web Panel
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/backhaul-panel/panel.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now backhaul-panel.service

    colorize indigo "Web Panel installed and started on port 9090." bold
}

uninstall_web_panel() {
    systemctl disable --now backhaul-panel.service
    rm -f /etc/systemd/system/backhaul-panel.service
    rm -rf /opt/backhaul-panel
    systemctl daemon-reload
    colorize purple "Web Panel has been removed." bold
}

check_web_panel() {
    if systemctl is-active --quiet backhaul-panel.service; then
        colorize indigo "✅ Web Panel is running on port 9090"
    else
        colorize purple "❌ Web Panel is not running"
    fi
}


##############################################
# Main Menu & Submenu Definitions (Rewritten)
##############################################

main_menu() {
    while true; do
        clear
        echo "╔════════════════════════════════════╗"
        echo "║     🚀 Backhaul Management Menu    ║"
        echo "╠════════════════════════════════════╣"
        echo "║ 1) ⚙️  Core Manager                 ║"
        echo "║ 2) 🔧 Configure Tunnel             ║"
        echo "║ 3) 🎯 Tunnel Manager               ║"
        echo "║ 4) 🚀 Optimize System              ║"
        echo "║ 5) 🌐 Web Panel                    ║"
        echo "║ 6) ♻️ Update Script                ║"
        echo "║ 0) ❌ Exit                         ║"
        echo "╚════════════════════════════════════╝"
        read -rp "Enter your choice: " choice
        case "$choice" in
            1) core_manager ;;
            2) configure_tunnel ;;
            3) tunnel_management ;;
            4) optimize_system ;;
            5) web_panel_manager ;;
            6) update_script ;;
            0) exit 0 ;;
            *) echo "Invalid choice. Please try again."; sleep 1 ;;
        esac
    done
}

core_manager() {
    while true; do
        clear
        echo "╔═════════════════════╗"
        echo "║   ⚙️  Core Manager    ║"
        echo "╚═════════════════════╝"
        echo "1) Install Backhaul Core"
        echo "2) Update Backhaul Core"
        echo "3) Remove Backhaul Core"
        echo "M) Return to Main Menu"
        read -rp "Enter your choice: " core_choice
        [[ "$core_choice" =~ ^[Mm]$ ]] && return
        case "$core_choice" in
            1) install_backhaul_core ;;
            2) update_backhaul_core ;;
            3) remove_backhaul_core ;;
            *) echo "Invalid option. Try again." ;;
        esac
        read -rp "Press Enter to continue..." pause
    done
}

configure_tunnel() {
    clear
    echo "🔧 Configure Tunnel"
    echo "1) Configure for IRAN Server"
    echo "2) Configure for KHAREJ Server"
    echo "M) Return to Main Menu"
    read -rp "Enter your choice: " conf_choice
    [[ "$conf_choice" =~ ^[Mm]$ ]] && return
    case "$conf_choice" in
        1) iran_server_configuration ;;
        2) kharej_server_configuration ;;
        *) echo "Invalid option. Try again."; sleep 1 ;;
    esac
}

tunnel_management() {
    clear
    echo "🎯 Tunnel Management"
    echo "1) Restart Tunnel"
    echo "2) Stop Tunnel"
    echo "3) View Logs"
    echo "M) Return to Main Menu"
    read -rp "Enter your choice: " tm_choice
    [[ "$tm_choice" =~ ^[Mm]$ ]] && return
    case "$tm_choice" in
        1) restart_tunnel ;;
        2) stop_tunnel ;;
        3) view_logs ;;
        *) echo "Invalid option. Try again."; sleep 1 ;;
    esac
}

optimize_system() {
    echo "🚀 Optimizing system..."
    sysctl -w net.core.default_qdisc=fq
    sysctl -w net.ipv4.tcp_congestion_control=bbr
    echo "Done. Press enter to continue."
    read
}

web_panel_manager() {
    echo "🌐 Web Panel"
    echo "1) Install Web Panel"
    echo "2) Remove Web Panel"
    echo "M) Return to Main Menu"
    read -rp "Enter your choice: " wp_choice
    [[ "$wp_choice" =~ ^[Mm]$ ]] && return
    case "$wp_choice" in
        1) install_web_panel ;;
        2) remove_web_panel ;;
        *) echo "Invalid option. Try again."; sleep 1 ;;
    esac
}

update_script() {
    echo "♻️ Updating Script..."
    echo "Not implemented yet."
    sleep 1
}

install_backhaul_core() {
    echo "[+] Installing Backhaul Core..."
    mkdir -p /etc/backhaul
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        URL="https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz"
    elif [[ "$ARCH" == "aarch64" ]]; then
        URL="https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_arm64.tar.gz"
    else
        echo "Unsupported architecture: $ARCH"
        return 1
    fi

    TMP_DIR=$(mktemp -d)
    curl -fsSL "$URL" -o "$TMP_DIR/backhaul.tar.gz"
    tar -xzf "$TMP_DIR/backhaul.tar.gz" -C "$TMP_DIR"
    mv "$TMP_DIR/backhaul" /etc/backhaul/backhaul-core
    chmod +x /etc/backhaul/backhaul-core
    rm -rf "$TMP_DIR"
    echo "[✓] Backhaul Core installed at /etc/backhaul/backhaul-core"
}

update_backhaul_core() {
    echo "[~] Updating Backhaul Core..."
    curl -fsSL -o /etc/backhaul/backhaul-core https://raw.githubusercontent.com/iPmartNetwork/backhaul-core/main/backhaul-core
    chmod +x /etc/backhaul/backhaul-core
    echo "[✓] Updated successfully."
}

remove_backhaul_core() {
    echo "[x] Removing Backhaul Core..."
    rm -f /etc/backhaul/backhaul-core
    echo "[✓] Removed."
}

iran_server_configuration() {
    echo "Configuring tunnel for IRAN server..."
    echo "remote_addr = "KHAREJ_IP"" > /etc/backhaul/tunnel.toml
    echo "local_addr = "127.0.0.1:1080"" >> /etc/backhaul/tunnel.toml
    echo "mode = "reverse"" >> /etc/backhaul/tunnel.toml
    echo "[✓] Config saved at /etc/backhaul/tunnel.toml"
}



restart_tunnel() {
    systemctl restart backhaul-tunnel.service
    echo "[✓] Tunnel restarted."
}

stop_tunnel() {
    systemctl stop backhaul-tunnel.service
    echo "[✓] Tunnel stopped."
}

view_logs() {
    journalctl -u backhaul-tunnel.service --no-pager
}

install_web_panel() {
    echo "[+] Installing Web Panel..."
    apt update && apt install -y python3 python3-pip
    pip3 install flask
    mkdir -p /opt/backhaul-panel
    echo 'from flask import Flask; app = Flask(__name__); @app.route("/")
def home(): return "Backhaul Panel Running"; app.run(host="0.0.0.0", port=8080)' > /opt/backhaul-panel/app.py
    cat <<EOF > /etc/systemd/system/backhaul-panel.service
[Unit]
Description=Backhaul Web Panel
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/backhaul-panel/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now backhaul-panel.service
    echo "[✓] Web panel running on port 8080"
}

remove_web_panel() {
    echo "[x] Removing Web Panel..."
    systemctl disable --now backhaul-panel.service
    rm -rf /opt/backhaul-panel /etc/systemd/system/backhaul-panel.service
    systemctl daemon-reload
    echo "[✓] Removed web panel service."
}

main_menu


kharej_server_configuration() {
kharej_server_configuration() {
    echo "[+] Configuring Backhaul for KHAREJ server..."

    read -rp "Enter local listen port (e.g. 443): " listen_port
    read -rp "Enter remote IRAN IP: " iran_ip
    read -rp "Enter token for client authentication: " token

    cat <<EOF > /etc/backhaul/tunnel.toml
[server]
listen = "0.0.0.0:$listen_port"
token = "$token"

[client_map]
[client_map.iran]
address = "$iran_ip:1080"
EOF

    echo "[✓] KHAREJ server tunnel configuration saved at /etc/backhaul/tunnel.toml"
}
