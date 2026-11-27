connect_openvpn(){
	sudo openvpn --config $OVPN_CONF --redirect-gateway def1 --script-security 2 --up ./update-resolv-conf --down ./update-resolv-conf 2>&1 | tee /tmp/openvpn-log.txt &

	for i in {1..15}; do
		REMOTE_LINE=$(grep -m1 'Preserving recently used remote address' /tmp/openvpn-log.txt 2>/dev/null)
		[ -n "$REMOTE_LINE" ] && break
		sleep 1
	done
	SERVER_IP=$(echo "$REMOTE_LINE" | sed 's/.*AF_INET]\([0-9.]*\):\([0-9]*\).*/\1/')
	PORT=$(echo "$REMOTE_LINE" | sed 's/.*AF_INET][0-9.]*:\([0-9]*\).*/\1/')

	sudo ufw allow out to "$SERVER_IP" port "$PORT" proto tcp
	echo "server ip $SERVER_IP port $PORT"

	#sudo ufw allow in on tun0
	sudo ufw allow out on tun0
}

connect_wireguard(){
    WG_SERVER=$(grep -oP 'Endpoint = \K[0-9.]+' "$WG_CONF")
    WG_PORT=$(grep -oP 'Endpoint = [0-9.]+:\K[0-9]+' "$WG_CONF")
    WG_IFACE=$(basename "$WG_CONF" .conf)

    sudo ufw allow out on "$WG_IFACE"
    sudo ufw allow out to "$WG_SERVER" port "$WG_PORT" proto udp
    # fwmark rule (the actual fix)
    sudo nft add table ip filter 2>/dev/null || true
    sudo nft add chain ip filter output '{ type filter hook output priority -1 ; }' 2>/dev/null || true
    sudo nft add rule ip filter output meta mark 0xca6c accept 2>/dev/null || true

    echo "wg server $WG_SERVER port $WG_PORT"
    sudo wg-quick up "./$WG_CONF"
}   

  
connect_random_wireguard() {
  local conf
  conf=$(find proton-wg -maxdepth 1 -type f -name '*.conf' -print 2>/dev/null | shuf -n1)

  if [[ -z "$conf" ]]; then
    echo "No configs in proton-wg/" >&2
    return 1
  fi

  local wg_server
  local wg_port
  local wg_iface

  wg_server=$(grep -oP 'Endpoint = \K[0-9.]+' "$conf")
  wg_port=$(grep -oP 'Endpoint = [0-9.]+:\K[0-9]+' "$conf")
  wg_iface=$(basename "$conf" .conf)

  if [[ -z "$wg_server" || -z "$wg_port" ]]; then
    echo "Could not read WireGuard endpoint from $conf" >&2
    return 1
  fi

  echo "Connecting to: $conf"
  echo "WireGuard endpoint: $wg_server:$wg_port"
  echo "WireGuard interface: $wg_iface"

  sudo ufw allow out on "$wg_iface"
  sudo ufw allow out to "$wg_server" port "$wg_port" proto udp
	
  
  sudo nft add table ip filter 2>/dev/null || true
  sudo nft add chain ip filter output '{ type filter hook output priority -1 ; }' 2>/dev/null || true
  sudo nft add rule ip filter output meta mark 0xca6c accept 2>/dev/null || true


  sudo wg-quick up "$conf"
}


