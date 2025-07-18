#!/bin/bash


#connect to random server
random(){

	sudo openvpn --config proton.ovpn  --redirect-gateway def1 --script-security 2 --up ./update-resolv-conf --down ./update-resolv-conf 2>&1 | tee /tmp/openvpn-log.txt &
	# Give OpenVPN a few seconds to start and log the target
	sleep 3
	REMOTE_LINE=$(grep -m1 'Preserving recently used remote address' /tmp/openvpn-log.txt)
	SERVER_IP=$(echo "$REMOTE_LINE" | sed 's/.*AF_INET]\([0-9.]*\):\([0-9]*\).*/\1/')
	PORT=$(echo "$REMOTE_LINE" | sed 's/.*AF_INET][0-9.]*:\([0-9]*\).*/\1/')
	PROTO=$(grep -m1 'TCP' /tmp/openvpn-log.txt && echo tcp || echo udp)

	sudo ufw allow out to "$SERVER_IP" port "$PORT" proto tcp
	echo "server ip $SERVER_IP port $PORT proto $PROTO"

	
	sudo ufw allow in on tun0
	sudo ufw allow out on tun0
}
#choose a server from the remote list
#choose(){}

# Connect to ProtonVPN
#sudo openvpn --config proton.ovpn --redirect-gateway def1 #redirect gateway
