select_server() {
	if (( ${ALL_SERVERS:-0} )); then
	selected=$(jq -c '.' <<< "$logical_servers_response")
	
	if [[ -z "$selected" || "$selected" == "[]" || "$selected" == "null" ]]; then
		echo "No servers available" >&2
		exit 1
	fi
	
	echo "Selected all servers"
	return 0
	fi
  if (( RANDOM_SERVER )); then
    local count=$(echo "$logical_servers_response" | jq 'length')
	local idx=$((RANDOM % count))
	selected=$(echo "$logical_servers_response" | jq -c ".[$idx]")

  elif [[ -n "$server_query" ]]; then
    selected=$(echo "$logical_servers_response" | jq --arg q "$server_query" \
      '[.[] | select(
        (.Name | ascii_downcase | contains($q | ascii_downcase))
        or (.City | ascii_downcase | contains($q | ascii_downcase))
      )]' \
      | jq -c '.[0]')

  elif command -v fzf >/dev/null 2>&1; then
    local name
    name=$(echo "$logical_servers_response" | jq -r '.[] | "\(.Name)\t\(.City)\t\(.Load)%"' | \
      fzf --header "ProtonVPN Free Servers" --prompt "🔒 " --no-mouse | awk -F'\t' '{print $1}')
    selected=$(echo "$logical_servers_response" | jq -c --arg n "$name" '.[] | select(.Name == $n)')

  else
    selected=$(echo "$logical_servers_response" | jq -c '[.[] | select(.Load != null)] | sort_by(.Load) | .[0]')
  fi

  if [[ -z "$selected" || "$selected" == "null" ]]; then
    echo "No server selected" >&2
    exit 1
  fi

  server_name=$(echo "$selected" | jq -r '.Name')
  server_city=$(echo "$selected" | jq -r '.City')
  server_ip=$(echo "$selected" | jq -r '.Servers[0].EntryIP')
  server_pub=$(echo "$selected" | jq -r '.Servers[0].X25519PublicKey')
  server_load=$(echo "$selected" | jq -r '.Load')

  echo "Selected: $server_name ($server_city) — $server_ip [load: ${server_load}%]"
}   
