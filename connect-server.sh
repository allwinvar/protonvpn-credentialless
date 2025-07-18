#!/bin/bash


# Path to the OpenVPN configuration file
CONFIG_FILE="proton.ovpn"

#connect to random server
random(){
<<<<<<< Updated upstream
=======

	
	# Since server is IP, no need to resolve
	#echo "Allowing outgoing $proto to $server port $port"
	#sudo ufw allow out to "$server_address" port "$server_port" proto "$proto"
	
	
	# Start the OpenVPN client with the selected server
	#sudo openvpn --config "$CONFIG_FILE" --remote "$server_address" "$server_port" --redirect-gateway def1
	#echo "executed sudo openvpn --config "$CONFIG_FILE" --remote "$server_address" "$server_port" --redirect-gateway def1"
	sudo openvpn --config proton.ovpn  --redirect-gateway def1  2>&1 | tee /tmp/openvpn-log.txt &
	# Give OpenVPN a few seconds to start and log the target
	sleep 3
	REMOTE_LINE=$(grep -m1 'Preserving recently used remote address' /tmp/openvpn-log.txt)
	SERVER_IP=$(echo "$REMOTE_LINE" | sed 's/.*AF_INET]\([0-9.]*\):\([0-9]*\).*/\1/')
	PORT=$(echo "$REMOTE_LINE" | sed 's/.*AF_INET][0-9.]*:\([0-9]*\).*/\1/')
	PROTO=$(grep -m1 'TCP' /tmp/openvpn-log.txt && echo tcp || echo udp)
	#sudo ufw allow out to "$SERVER_IP" port "$PORT" proto "$PROTO"
	sudo ufw allow out to "$SERVER_IP" port "$PORT" proto tcp
	echo "server ip $SERVER_IP port $PORT proto $PROTO"
	#print("server ip " + $SERVER_IP + "port" + "$PORT" + "proto" + $PROTO)
>>>>>>> Stashed changes
	
	
	# Extract the list of remote directives
	remote_lines=$(grep '^remote ' "$CONFIG_FILE")
	
	# Randomly select a remote directive
	selected_remote=$(echo "$remote_lines" | shuf -n 1)
	
	
	# Extract the server address and port from the selected remote directive
	server_address=$(echo "$selected_remote" | awk '{print $2}')
	server_port=$(echo "$selected_remote" | awk '{print $3}')
	
	proto=$(grep '^proto ' "$CONFIG_FILE" | head -n1 | awk '{print $2}')
	
	# Since server is IP, no need to resolve
	echo "Allowing outgoing $proto to $server port $port"
	sudo ufw allow out to "$server_address" port "$server_port" proto "$proto"
	
	echo "executed sudo openvpn --config \"$CONFIG_FILE\" --remote \"$server_address\" \"$server_port\" --redirect-gateway def1"
	#echo 'ufw allow out to "$server_address" port "$server_port" proto "$proto"'
	
	# Start the OpenVPN client with the selected server
	sudo openvpn --config "$CONFIG_FILE" --remote "$server_address" "$server_port" --redirect-gateway def1 --verb 4
	echo "executed sudo openvpn --config "$CONFIG_FILE" --remote "$server_address" "$server_port" --redirect-gateway def1"
}
#choose a server from the remote list
#choose(){}

# Connect to ProtonVPN
#sudo openvpn --config proton.ovpn --redirect-gateway def1 #redirect gateway
