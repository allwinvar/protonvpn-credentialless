run_flow() {
  local protocol="$1"

  # C1: always fresh
  rm -f session_credentials.json cookie.jar
  echo "[1/6] Creating session..."
  create_session
  x_pm_uid=$(jq -r '.UID' session_credentials.json)
  access_token=$(jq -r '.AccessToken' session_credentials.json)
  credentialless_access_token=""

  # C2
  echo "[2/6] Getting credentialless token..."
  get_credentialless_token

  # C3
  echo "[3/6] Fetching servers..."
  fetch_servers
  if [[ "$protocol" == wireguard ]]; then
    select_server
  fi

  # C4
  if [[ "$protocol" == openvpn ]]; then
    echo "[4/6] Fetching VPN credentials..."
    fetch_vpn_credentials
  else
    echo "[4/6] Skipping (WireGuard)"
  fi

  # C5
  if [[ "$protocol" == wireguard ]]; then
    echo "[5/6] Getting EC keypair..."
    get_keypair
  else
    echo "[5/6] Skipping (OpenVPN)"
  fi

  # C6
  if [[ "$protocol" == wireguard ]]; then
    echo "[6/6] Registering certificate..."
    register_certificate
    generate_wireguard_config
  else
    echo "[6/6] Generating OpenVPN config..."
    generate_ovpn
  fi
}

 
