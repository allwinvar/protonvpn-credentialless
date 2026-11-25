#openvpn.sh

generate_ovpn(){
# ============================================
# OpenVPN config generation
# ============================================

# Start generating OpenVPN config
cp proton-sample.ovpn $OVPN_CONF
sed -i '/^remote .*$/d' $OVPN_CONF
sed -i "s/^verb .*$/verb $VERB/g" $OVPN_CONF
echo "
<auth-user-pass>
$vpn_name
$vpn_password
</auth-user-pass>" >>$OVPN_CONF

if (( NO_IPV6 )); then
    echo -e "\e[33;3mIPv6 disabled.\e[0m"
    echo '
# Disable IPv6
pull-filter ignore "tun-ipv6"
pull-filter ignore "route-ipv6"
pull-filter ignore "ifconfig-ipv6"
pull-filter ignore "redirect-gateway"
block-ipv6
redirect-gateway def1' >>$OVPN_CONF
elif ! ip a | grep inet6 >/dev/null 2>&1; then
    echo -e "\e[33;3mIPv6 appears to be disabled on your host. You may want to explicitly disable it using --no-ipv6\e[0m"
fi

if (( NO_DNS_LEAK )); then
    echo -e "\e[33;3mAvoid using ISP dns servers.\e[0m"
    echo '
# Avoid using ISP dns servers
pull-filter ignore "block-outside-dns"
pull-filter ignore "dhcp-option"
dhcp-option DNS 1.1.1.1
script-security 2
up "/usr/bin/env bash -c '\''/etc/openvpn/update-resolv-conf $* || /etc/openvpn/up.sh $*'\''"
down "/usr/bin/env bash -c '\''/etc/openvpn/update-resolv-conf $* || /etc/openvpn/down.sh $*'\''"' >>$OVPN_CONF
fi

# Add all server remotes to OpenVPN conf
for logical_server_b64 in $(echo "$logical_servers_response" | jq -r '.[] | @base64'); do
    logical_server=$(echo "$logical_server_b64" | base64 -d)
    name=$(echo "$logical_server" | jq -r '.Name')
    city=$(echo "$logical_server" | jq -r '.City')
    load=$(echo "$logical_server" | jq -r '.Load')
    entry_ip=$(echo "$logical_server" | jq -r '.Servers[0].EntryIP')
    sed -i "/^remote-random$/i remote $entry_ip 443 # $name ($city) load: $load%" $OVPN_CONF
done

echo "OpenVPN conf was created with success!"
echo -e "\e[36m$ sudo openvpn --config $OVPN_CONF\e[0m"
}
