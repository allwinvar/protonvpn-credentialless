#vpn_api.sh       
fetch_servers(){
	# Fetch logical servers (WireGuard-capable, Tier 0 = Free)
logical_servers_response=$(
  curl ${CURL_VERBOSE:+-v} ${CURL_NO_SILENT:--sS} \
    --fail \
    --connect-timeout 10 \
    --retry 3 \
    -X "GET" \
    -H "Authorization: Bearer $credentialless_access_token" \
    -H "x-pm-uid: $x_pm_uid" \
    -H "User-Agent: PVPN/5.18.75.1 (Android 12; Google Pixel 6)" \
    -H "x-pm-appversion: android-vpn@5.18.75.1-dev+play" \
    -H "x-pm-apiversion: 4" \
    -H "Accept: application/vnd.protonmail.v1+json" \
    "https://vpn-api.proton.me/vpn/v2/logicals?WithEntriesForProtocols=wireguard&WithState=true" \
    | jq -r '.LogicalServers | map(select(.Tier == 0))'
)
	}

fetch_vpn_credentials(){
  vpn_credential_response=$(curl -sS --fail --connect-timeout 10 \
  -X GET \
  -H "Authorization: Bearer $credentialless_access_token"   \
  -H "x-pm-uid: $x_pm_uid" \
  -H "User-Agent: PVPN/5.18.75.1 (Android 12; Google Pixel 6)" \
  -H "x-pm-appversion: android-vpn@5.18.75.1-dev+play" \
  -H "x-pm-apiversion: 4" \
  -H "Accept: application/vnd.protonmail.v1+json" \
  "https://vpn-api.proton.me/vpn/v2" | jq .
  )

# Line with .Name →
vpn_name=$(echo "$vpn_credential_response" | jq -r '.VPN.Name')

# Line with .Password →
vpn_password=$(echo "$vpn_credential_response" | jq -r '.VPN.Password')   
	}
