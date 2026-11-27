#!/usr/bin/env bash
set -euo pipefail

source lib/cli.sh
source lib/requirements.sh
source lib/auth.sh
source lib/vpn_api.sh
source lib/server_selection.sh
source lib/openvpn.sh
source lib/wireguard.sh
source lib/flow.sh
source lib/connect.sh   

parse_args "$@"

if (( CONNECT && GEN )); then
    check_requirements "$protocol"
    WG_CONF="$output_file"
    OVPN_CONF="$output_file"
    VERB="${VERB:-1}"
    run_flow "$protocol"
elif (( CONNECT )); then
    OVPN_CONF="$output_file"
    WG_CONF="$output_file"
else
    check_requirements "$protocol"
    WG_CONF="$output_file"
    OVPN_CONF="$output_file"
    VERB="${VERB:-1}"
    run_flow "$protocol"
fi

if (( CONNECT )); then
  if (( RANDOM_SERVER )); then
    if [[ "$protocol" == wireguard ]]; then
      connect_random_wireguard
    fi
  elif [[ "$protocol" == openvpn ]]; then
    connect_openvpn
  else
    connect_wireguard
  fi
fi   
