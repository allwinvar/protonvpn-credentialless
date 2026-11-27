#wireguard.sh

get_keypair(){
	# ============================================
	# WireGuard config generation
	# ============================================
	
	# Get EC keypair from Proton
	key_response=$(curl ${CURL_VERBOSE:+-v} ${CURL_NO_SILENT:--sS} \
	--fail --connect-timeout 10 --retry 3 \
	-X GET \
	-H "Authorization: Bearer $credentialless_access_token" \
	-H "x-pm-uid: $x_pm_uid" \
	-H "User-Agent: PVPN/5.18.75.1 (Android 12; Google Pixel 6)" \
	-H "x-pm-appversion: android-vpn@5.18.75.1-dev+play" \
	-H "x-pm-apiversion: 4" \
	-H "Accept: application/vnd.protonmail.v1+json" \
	"https://vpn-api.proton.me/vpn/v1/certificate/key/EC"
	)
	
	# Extract full base64 (strip PEM headers, join all lines)
	ec_pub_b64=$(echo "$key_response" | jq -r '.PublicKey' | grep -v -- '-----' | tr -d '\r\n')
	ec_priv_b64=$(echo "$key_response" | jq -r '.PrivateKey' | grep -v -- '-----' | tr -d '\r\n')  

}

register_certificate(){
	echo "WG server: $server_name ($server_city) — $server_ip"

	# Register certificate
	cert_response=$(curl ${CURL_VERBOSE:+-v} ${CURL_NO_SILENT:--sS} \
  --fail --connect-timeout 10 --retry 3 \
  -X POST \
  -H "Authorization: Bearer $credentialless_access_token" \
  -H "x-pm-uid: $x_pm_uid" \
  -H "User-Agent: PVPN/5.18.75.1 (Android 12; Google Pixel 6)" \
  -H "x-pm-appversion: android-vpn@5.18.75.1-dev+play" \
  -H "x-pm-apiversion: 4" \
  -H "Accept: application/vnd.protonmail.v1+json" \
  -H "Content-Type: application/json" \
  --data-raw "{
    \"ClientPublicKey\": \"$ec_pub_b64\",
    \"Mode\": \"persistent\",
    \"DeviceName\": \"pvpn-client\",
    \"Features\": {
      \"peerName\": \"$server_name\",
      \"peerIp\": \"$server_ip\",
      \"peerPublicKey\": \"$server_pub\",
      \"platform\": \"Linux\"
    }
  }" \
  "https://vpn-api.proton.me/vpn/v1/certificate"
	)
	
	
	
	# Derive X25519 private key from EC private key
  wg_priv=$(python3 -c "
import hashlib, base64
raw = base64.b64decode('$ec_priv_b64')
h = bytearray(hashlib.sha512(raw[-32:]).digest()[:32])
h[0] &= 0xf8
h[31] &= 0x7f
h[31] |= 0x40
print(base64.b64encode(bytes(h)).decode())
")   
}

generate_wireguard_config() {
  local safe_name="${server_name//#/-}"
  WG_CONF="proton-wg/${safe_name}-wg.conf"
  mkdir -p "$(dirname "$WG_CONF")"
  cat > "$WG_CONF" <<EOF
# Name: $server_name
# City: $server_city
# Load: $server_load
# IP: $server_ip
# Created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

[Interface]
PrivateKey = $wg_priv
Address = 10.2.0.2/32
DNS = 10.2.0.1

[Peer]
PublicKey = $server_pub
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $server_ip:51820
PersistentKeepalive = 25
EOF

  echo "WireGuard conf saved to $WG_CONF"
  echo -e "\e[36m\$ sudo wg-quick up $WG_CONF\e[0m"
  echo -e "\e[36m\$ sudo wg-quick down $WG_CONF\e[0m"
}


generate_all_wireguard_configs() {
  mkdir -p proton-wg

  register_certificate

  while IFS= read -r selected_server; do
    selected=$selected_server
    server_name=$(jq -r '.Name' <<< "$selected")
    server_city=$(jq -r '.City' <<< "$selected")
    server_ip=$(jq -r '.Servers[0].EntryIP' <<< "$selected")
    server_pub=$(jq -r '.Servers[0].X25519PublicKey' <<< "$selected")
    server_load=$(jq -r '.Load' <<< "$selected")

    generate_wireguard_config
  done < <(jq -c '.[]' <<< "$selected")
}   
  

