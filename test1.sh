#!/bin/bash
# Backhaul Tunnel Manager v2.1.0 (English Version)

CYAN='\e[36m'
MAGENTA='\e[35m'
RESET='\e[0m'

# ========= Functions =========

manage_core() {
    while true; do
        clear
        echo -e "${MAGENTA}Backhaul Core Management${RESET}"
        echo -e "${CYAN}1) Check Backhaul Service Status${RESET}"
        echo -e "${CYAN}2) Start Backhaul Service${RESET}"
        echo -e "${CYAN}3) Stop Backhaul Service${RESET}"
        echo -e "${CYAN}4) Restart Backhaul Service${RESET}"
        echo -e "${CYAN}5) View Backhaul Logs${RESET}"
        echo -e "${CYAN}6) Return to Main Menu${RESET}"
        read -p "Choose an option [1-6]: " core_choice

        case $core_choice in
            1) systemctl status backhaul.service --no-pager | head -20 ;;
            2) sudo systemctl start backhaul.service ;;
            3) sudo systemctl stop backhaul.service ;;
            4) sudo systemctl restart backhaul.service ;;
            5) journalctl -u backhaul.service --no-pager ;;
            6) break ;;
            *) echo -e "${CYAN}Invalid option${RESET}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

configure_tunnel_ipv46() {
# Tunnel logic could not be extracted.
}
    validate_ip6() { [[ "$1" =~ ^([0-9a-fA-F]{0,1,4}:){1,7}[0-9a-fA-F]{0,1,4}$ ]]; }
    validate_port() { [[ "$1" -ge 1 && "$1" -le 65535 ]]; }

    test_connection() {
        echo -e "${CYAN}Testing connection to $1:$2...${RESET}"
        nc -z -w3 "$1" "$2" >/dev/null 2>&1 && echo -e "${MAGENTA}✅ Success${RESET}" || echo -e "${MAGENTA}❌ Failed${RESET}"
    }

    read -p "Tunnel mode (reverse/direct): " TUNNEL_MODE
    read -p "Transport protocol (tcp/udp/ws/wss/icmp/faketcp): " PROTO
    read -p "Authentication token: " TOKEN

    CONFIG_PATH="/etc/backhaul/config.toml"
    mkdir -p /etc/backhaul
    > "$CONFIG_PATH"

    while true; do
        read -p "Use IPv4 or IPv6? (4/6): " IP_VER
        if [[ "$IP_VER" == "4" ]]; then
            while true; do read -p "Remote IPv4: " IP; validate_ip4 "$IP" && break; done
        elif [[ "$IP_VER" == "6" ]]; then
            while true; do read -p "Remote IPv6: " IP; validate_ip6 "$IP" && IP="[$IP]" && break; done
        else
            echo "Invalid IP version."; continue
        fi

        while true; do read -p "Remote port: " PORT; validate_port "$PORT" && break; done
        while true; do read -p "Local port: " LOCAL_PORT; validate_port "$LOCAL_PORT" && break; done

        test_connection "$IP" "$PORT"

        if [[ "$TUNNEL_MODE" == "reverse" ]]; then
            cat >> "$CONFIG_PATH" <<EOF
[[client]]
remote_addr = "$IP:$PORT"
transport = "$PROTO"
token = "$TOKEN"
local_addr = "127.0.0.1:$LOCAL_PORT"
keepalive_period = 75
heartbeat = 40
mux_con = 4

EOF
        else
            cat >> "$CONFIG_PATH" <<EOF
[[server]]
bind_addr = "0.0.0.0:$PORT"
transport = "$PROTO"
token = "$TOKEN"
keepalive_period = 75
heartbeat = 40
mux_con = 4
web_port = 2060

EOF
        fi

        read -p "Add another server? (y/n): " more
        [[ "$more" =~ ^[Yy]$ ]] || break
    done

    echo -e "${MAGENTA}✅ Configuration saved.${RESET}"
    sudo systemctl restart backhaul.service
    systemctl status backhaul.service --no-pager | head -20
    read -p "Press Enter to continue..."
}

manage_tunnels() {
    while true; do
        clear
        echo -e "${MAGENTA}Tunnel Management${RESET}"
        echo -e "${CYAN}1) Service Status${RESET}"
        echo -e "${CYAN}2) Restart Service${RESET}"
        echo -e "${CYAN}3) Stop Service${RESET}"
        echo -e "${CYAN}4) View config.toml${RESET}"
        echo -e "${CYAN}5) Live Logs${RESET}"
        echo -e "${CYAN}6) Delete config.toml${RESET}"
        echo -e "${CYAN}7) Edit Tunnel${RESET}"
        echo -e "${CYAN}8) Back to Main Menu${RESET}"
        read -p "Choose an option [1-8]: " option

        case $option in
            1) systemctl status backhaul.service --no-pager | head -20 ;;
            2) sudo systemctl restart backhaul.service ;;
            3) sudo systemctl stop backhaul.service ;;
            4) cat /etc/backhaul/config.toml ;;
            5) journalctl -u backhaul.service -f ;;
            6) rm -f /etc/backhaul/config.toml ;;
            7)
                grep -n '\[\[client\]\]\|\[\[server\]\]' /etc/backhaul/config.toml
                read -p "Enter line number to edit: " LINE
                START=$LINE
                END=$(tail -n +$((LINE+1)) /etc/backhaul/config.toml | grep -n '^\[\[.*\]\]' | head -n1 | cut -d: -f1)
                [[ -z "$END" ]] && END=$(wc -l < /etc/backhaul/config.toml)
                END=$((START + END - 1))

                sed -n "${START},${END}p" /etc/backhaul/config.toml
                read -p "New remote_addr: " R; read -p "New transport: " T
                read -p "New token: " TK; read -p "New local_addr: " L

                TMP=$(mktemp)
                awk -v s="$START" -v e="$END" -v r="$R" -v t="$T" -v tk="$TK" -v l="$L" '
                NR<s || NR>e { print }
                NR==s { block=1; print }
                block && /^remote_addr/ { print "remote_addr = "" r """; next }
                block && /^transport/ { print "transport = "" t """; next }
                block && /^token/ { print "token = "" tk """; next }
                block && /^local_addr/ { print "local_addr = "" l """; next }
                block && /^\[/ { block=0; print }
                block==1 { next }
                { print }' /etc/backhaul/config.toml > "$TMP" && mv "$TMP" /etc/backhaul/config.toml
                echo -e "${MAGENTA}✅ Tunnel updated.${RESET}"
                ;;
            8) break ;;
            *) echo -e "${CYAN}Invalid option${RESET}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

manage_web_panel() {
    while true; do
        clear
        echo -e "${MAGENTA}Web Panel Management${RESET}"
        echo -e "${CYAN}1) Show Web Panel URL${RESET}"
        echo -e "${CYAN}2) Check Panel Port Status${RESET}"
        echo -e "${CYAN}3) Restart Backhaul for Panel${RESET}"
        echo -e "${CYAN}4) Return to Main Menu${RESET}"
        read -p "Choose an option [1-4]: " panel_choice

        case $panel_choice in
            1)
                IP=$(hostname -I | awk '{print $1}')
                PORT=$(grep "web_port" /etc/backhaul/config.toml | awk -F= '{print $2}' | tr -d ' ')
                [[ -z "$PORT" ]] && PORT="2060"
                echo -e "Web Panel URL: http://$IP:$PORT"
                ;;
            2)
                PORT=$(grep "web_port" /etc/backhaul/config.toml | awk -F= '{print $2}' | tr -d ' ')
                [[ -z "$PORT" ]] && PORT="2060"
                nc -z 127.0.0.1 "$PORT" && echo "✅ Running" || echo "❌ Not Active"
                ;;
            3) sudo systemctl restart backhaul.service ;;
            4) break ;;
            *) echo "Invalid option" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

optimize_network_jitter() {
    echo -e "${MAGENTA}Optimizing Network for Ping and Jitter${RESET}"
    sudo bash -c 'cat > /etc/sysctl.d/99-backhaul.conf' <<EOF
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1
net.core.netdev_max_backlog = 5000
EOF
    sudo sysctl --system
    sudo bash -c 'echo "* soft nofile 1048576" >> /etc/security/limits.conf'
    sudo bash -c 'echo "* hard nofile 1048576" >> /etc/security/limits.conf'
    echo -e "${MAGENTA}✅ Optimization complete.${RESET}"
    read -p "Press Enter to continue..."
}

# ========== Main Menu ==========

while true; do
    clear
    echo -e "${CYAN}========= Backhaul Tunnel Manager =========${RESET}"
    echo -e "${CYAN}1) Core Management${RESET}"
    echo -e "${CYAN}2) Tunnel Configuration (IPv4/IPv6)${RESET}"
    echo -e "${CYAN}3) Tunnel Management${RESET}"
    echo -e "${CYAN}4) Web Panel Management${RESET}"
    echo -e "${CYAN}5) Optimize Ping/Jitter${RESET}"
    echo -e "${CYAN}6) Exit${RESET}"
    echo -e "${CYAN}==========================================${RESET}"
    read -p "Select an option [1-6]: " main_choice

    case $main_choice in
        1) manage_core ;;
        2) configure_tunnel_ipv46 ;;
        3) manage_tunnels ;;
        4) manage_web_panel ;;
        5) optimize_network_jitter ;;
        6) break ;;
        *) echo "Invalid option"; sleep 1 ;;
    esac
done
