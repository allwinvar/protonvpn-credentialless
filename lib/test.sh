# Dependencies
command -v curl jq awk grep base64 python3 sed cp

# For actually connecting (not just generating config):
# WireGuard:  sudo apt install wireguard
# OpenVPN:    sudo apt install openvpn

# Template (OpenVPN path only):
[[ -f proton-sample.ovpn ]] && echo "OK" || echo "MISSING"

# Run:
./main.sh --protocol wireguard --server "US"   
