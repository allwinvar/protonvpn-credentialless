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
    # Extract endpoint from config
    WG_SERVER=$(grep -oP 'Endpoint = \K[0-9.]+' "$WG_CONF")
    WG_PORT=$(grep -oP 'Endpoint = [0-9.]+:\K[0-9]+' "$WG_CONF")

    sudo ufw allow out to "$WG_SERVER" port "$WG_PORT" proto udp
    echo "wg server $WG_SERVER port $WG_PORT"

    sudo wg-quick up "./$WG_CONF"
    
    WG_IFACE=$(basename "$WG_CONF" .conf)
    #sudo ufw allow in on "$WG_IFACE"
    sudo ufw allow out on "$WG_IFACE"
}   
