# Backhaul Tunnel Manager API & Web Panel

This project provides a full-featured API and React-based web panel to manage reverse tunnels using Backhaul Core.

## 🌐 Features
- Create, delete, and monitor tunnels
- Support for transport protocols: `tcp`, `udp`, `ws`, `wss`, `tcpmux`, `faketcptun`, etc
- Secure API with Bearer Token authentication
- JSON configuration output for each tunnel
- Auto-generated systemd services
- Modern Web UI (React + Tailwind + shadcn)

---

## 📦 Installation

### 1. Run the installer
```bash
chmod +x install_api.sh
sudo ./install_api.sh
```

### 2. After installation:
- API runs on `http://localhost:8686`
- Token is set during install and required via:
```http
Authorization: Bearer <YOUR_TOKEN>
```

### 3. API Endpoints
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/status` | GET | List all tunnels |
| `/status/<name>` | GET | Get specific tunnel info |
| `/create` | POST | Create a tunnel (JSON body) |
| `/delete` | POST | Delete tunnel by name |

---

## ⚙️ Tunnel JSON Example
```json
{
  "type": "iran",
  "port": 443,
  "transport": "tcp",
  "token": "secure123",
  "web_port": 9090,
  "mux_version": 2,
  "sniffer": "true",
  "nodelay": "true",
  "proxy_protocol": "false",
  "heartbeat": 30,
  "mux": 8,
  "ip_mode": "ipv4",
  "ports": ["443=1.1.1.1:5201"]
}
```

---

## 🖥 Web UI (React)
- Located in `backhaul_panel.tsx`
- Includes:
  - Tunnel list
  - Form to create new tunnel
  - Delete and status indicators

---

## 🔒 Security
- Token-based access for all endpoints
- Systemd protection for auto-recovery

---

## 📁 File Structure
```
/etc/systemd/system/backhaul-api.service
/opt/backhaul/backhaul_api.py
/usr/local/bin/create_backhaul_tunnel.sh
install_api.sh
```

---

## 🧪 Test API
```bash
curl -X GET http://localhost:8686/status \
  -H "Authorization: Bearer mysecuretoken"
```

---

## 📝 License
MIT License
