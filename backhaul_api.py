from flask import Flask, request, jsonify
import os
import subprocess
import json

app = Flask(__name__)

TUNNELS_DIR = "/opt/backhaul"
JSON_LOG = "/var/log/backhaul_tunnels.json"
SERVICE_DIR = "/etc/systemd/system"

def get_status(tunnel_name):
    service = f"backhaul-{tunnel_name}.service"
    try:
        subprocess.run(["systemctl", "is-active", "--quiet", service], check=True)
        return "running"
    except subprocess.CalledProcessError:
        return "stopped"

@app.route("/status", methods=["GET"])
def list_status():
    if os.path.exists(JSON_LOG):
        with open(JSON_LOG) as f:
            data = json.load(f)
        data["status"] = get_status(data["tunnel_name"])
        return jsonify(data)
    return jsonify({"error": "No tunnel data found"}), 404

@app.route("/status/<name>", methods=["GET"])
def tunnel_status(name):
    return jsonify({
        "tunnel": name,
        "status": get_status(name)
    })

@app.route("/delete", methods=["POST"])
def delete_tunnel():
    data = request.get_json()
    tunnel_name = data.get("tunnel_name")
    service = f"backhaul-{tunnel_name}.service"
    config = os.path.join(TUNNELS_DIR, f"{tunnel_name}.toml")

    subprocess.run(["systemctl", "disable", "--now", service])
    os.remove(os.path.join(SERVICE_DIR, service))
    if os.path.exists(config):
        os.remove(config)
    return jsonify({"message": f"Tunnel {tunnel_name} deleted."})

@app.route("/restart", methods=["POST"])
def restart_tunnel():
    data = request.get_json()
    tunnel_name = data.get("tunnel_name")
    service = f"backhaul-{tunnel_name}.service"
    subprocess.run(["systemctl", "restart", service])
    return jsonify({"message": f"Tunnel {tunnel_name} restarted."})

@app.route("/create", methods=["POST"])
def create_placeholder():
    return jsonify({"error": "Not implemented in this version"}), 501

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=9090)
