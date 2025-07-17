#!/bin/bash

source ./connect-server.sh

sudo ufw allow from 185.159.159.148 to any port 443 proto tcp
sudo ufw allow out to 185.159.159.148 port 443 proto tcp



# Function to handle arguments and set flags
handle_arguments() {
  local args=("$@")
  local found_generate=0
  local found_connecting=0
  local found_killswitch=0

  for arg in "${args[@]}"; do
    if [[ "$arg" == g* || "$arg" == ge* || "$arg" == gen* || "$arg" == gene* || "$arg" == gener* || "$arg" == genera* || "$arg" == generat* || "$arg" == generate* ]]; then
	  found_generate=1
	elif [[ "$arg" == c* || "$arg" == co* || "$arg" == con* || "$arg" == conn* || "$arg" == conne* || "$arg" == connect* ]]; then
      found_connecting=1
    elif [[ "$arg"==ks || "$arg" == k* || "$arg" == ki* || "$arg" == kil* || "$arg" == kills* || "$arg" == killsw* || "$arg" == killswi* || "$arg" == killswith* || "$arg" == killswitch* ]]; then
      found_killswitch=1
    fi
  done
  if [ $found_generate -eq 1 ]; then
    echo "generate"
  fi
  if [ $found_connecting -eq 1 ]; then
    echo "connecting"
  fi

  if [ $found_killswitch -eq 1 ]; then
    echo "killswitch-on"
  fi
}

# Check if any arguments were passed
if [ $# -eq 0 ]; then
  echo "No arguments provided."
  exit 1
fi

# Call the argument handler function and capture the result
result=$(handle_arguments "$@")


if echo "$result" | grep -q "killswitch-on"; then
  echo "Running killswitch.sh"
  ./strict-ks.sh
fi

# Generate proton.ovpn and session files
if echo "$result" | grep -q "generate"; then
  echo "Running generate.sh"
  # call ./generate.sh
  ./generate.sh
fi

# Trigger the corresponding scripts based on the result
if echo "$result" | grep -q "connecting"; then
  echo "Running connect.sh"
  #./connect-server.sh
  #call ./connect-server.sh's random()
  random
fi



if [ -z "$result" ]; then
  echo "No matching arguments found."
  exit 1
fi

#sudo openvpn --redirect-gateway def1 #redirect gateway
