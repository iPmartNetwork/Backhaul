
# Backhaul Tunnel Manager with Internal API

This script provides a menu-driven Backhaul Core tunnel manager and also includes an optional internal REST-style API for automation.

## 🚀 Usage

### Run menu interface:
```bash
./backhaul.sh
```

### Run internal API (port 22490):
```bash
./backhaul.sh --api
```

## 🔐 Authentication

All API requests must include a bearer token:
```
Authorization: Bearer my_secret_token
```

You can change the token by editing the `AUTH_TOKEN` variable inside the script.

---

## 📡 API Endpoints

### `GET /list`
Returns a JSON array of all configured tunnels.
#### Example:
```bash
curl -H "Authorization: Bearer my_secret_token" http://localhost:22490/list
```

---

### `GET /status/<name>`
Returns status of a specific tunnel.

#### Example:
```bash
curl -H "Authorization: Bearer my_secret_token" http://localhost:22490/status/tunnelname
```

---

### `POST /create`
Creates a new tunnel using JSON input.

#### Example:
```bash
curl -X POST http://localhost:22490/create \
     -H "Authorization: Bearer my_secret_token" \
     -H "Content-Type: application/json" \
     -d '{
           "name": "mytunnel",
           "port": "443",
           "mode": "iran",
           "type": "tcp",
           "token": "abc123",
           "domain": "example.com",
           "direction": "reverse"
         }'
```

---

### `POST /delete/<name>`
Deletes a tunnel and its service.

#### Example:
```bash
curl -X POST -H "Authorization: Bearer my_secret_token" \
     http://localhost:22490/delete/mytunnel
```

---

## 🧰 Systemd Service

To install the API as a service:

```bash
chmod +x install_backhaul_api.sh
./install_backhaul_api.sh
```

This installs and runs the API via `systemd` as `backhaul-api.service`.

---

## 📂 Logs

Logs for each tunnel are saved in:
```
/var/log/backhaul/backhaul-<name>.service.log
```

---

## 📞 Support

Telegram: [@iPmart_Network](https://t.me/iPmart_Network)
