
# Backhaul Tunnel Manager v5.0.0

This is a full-featured Bash-based management script for Backhaul Core.

## 📦 Contents
- `backhaul.sh`: The main management script
- Web panel on port `8686` with token-protected API
- Full support for tunnel creation, editing, deletion, exporting configs, and live stats

## 🚀 Installation

```
tar -xvzf backhaul-v5.0.0.tar.gz
chmod +x backhaul.sh
sudo ./backhaul.sh
```

## 🔐 API Access

To authorize API requests, use the token found in:

```
/root/.backhaul_api_token
```

Add it as a header:

```
Authorization: Bearer <token>
```

## 🌐 Web Interface

After running the script, access the interface at:

```
http://<server-ip>:8686/
```

## 🔁 Updating

Simply overwrite the old script with the latest version and re-run.

---

Made with 💻  ali hassanzadeh
