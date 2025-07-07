#!/usr/bin/env bash

set -eu
set -o pipefail

ARGS=" $* "
VERB=1
if [[ "$ARGS" = *" -v "* ]]; then
    CURL_NO_SILENT=
    VERB=3
elif [[ "$ARGS" = *" -vvv "* ]]; then
    CURL_VERBOSE=1
    CURL_NO_SILENT=
    VERB=5
    set -x
fi

OVPN_CONF=proton.ovpn
app_version="5.11.70.0"
device_name=$(shuf -i 111111111111-999999999999 -n 1)

# Check requirements
if ! command -v jq >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1 || ! command -v ip >/dev/null 2>&1; then
    echo -e "\e[31m[-] Please install the following requirements to run this script:\e[0m"
    echo "Debian    $ apt install -y jq curl iproute2"
    echo "Fedora    $ dnf install -y jq curl iproute"
    echo "Alpine    $ apk add jq curl iproute2"
    echo "OpenWrt   $ apk add jq curl iproute2"
    echo "Nixos     $ nix-shell -p jq curl iproute2"
    echo "Archlinux $ pacman -Sy --noconfirm jq curl iproute2"
    exit 1
fi

echo "Please wait..."

# Get new session
rm -f cookie.jar
# shellcheck disable=SC2086
session=$(curl ${CURL_VERBOSE:+-v} ${CURL_NO_SILENT--sS} --fail --connect-timeout 10 --retry 3 -X "POST" --cookie-jar cookie.jar -H "X-Pm-Appversion: android-vpn@$app_version+play" -H "X-Pm-Locale: en" -H "User-Agent: ProtonVPN/$app_version (Android 15; google sdk_gphone64_x86_64)" -H "Accept: application/vnd.protonmail.v1+json" -H "Content-Type: application/json; charset=utf-8" -H "Connection: keep-alive" -d '{"Payload":{"vpn-android-v4-challenge-0":{"v":"2.0.7","appLang":"en","timezone":"Europe/Monaco","deviceName":'"$device_name"',"regionCode":"US","timezoneOffset":-120,"isJailbreak":false,"preferredContentSize":"1.0","storageCapacity":16.0,"isDarkmodeOn":false,"keyboards":["com.google.android.inputmethod.latin","com.google.android.tts"]}}}' "https://vpn-api.proton.me/auth/v4/sessions")

x_pm_uid=$(echo "$session" | jq -r '.UID')
access_token=$(echo "$session" | jq -r '.AccessToken')
session_id=$(grep <cookie.jar "Session-Id" | awk '{print $7}')

# Get credentialless access token
# shellcheck disable=SC2086
credentialless=$(curl ${CURL_VERBOSE:+-v} ${CURL_NO_SILENT--sS} --fail --connect-timeout 10 --retry 3 -X "POST" -H "X-Pm-Appversion: android-vpn@$app_version+play" -H "X-Pm-Locale: en" -H "User-Agent: ProtonVPN/$app_version (Android 15; google sdk_gphone64_x86_64)" -H "Accept: application/vnd.protonmail.v1+json" -H "X-Pm-Uid: $x_pm_uid" -H "Authorization: Bearer $access_token" -H "Content-Type: application/json; charset=utf-8" -b "Session-Id=$session_id; Tag=vpn-b" -d '{"Payload":{"vpn-android-v4-challenge-0":{"type":"me.proton.core.challenge.data.frame.ChallengeFrame.Device","v":"2.0.7","appLang":"en","timezone":"Europe/Monaco","deviceName":'"$device_name"',"regionCode":"US","timezoneOffset":-120,"isJailbreak":false,"preferredContentSize":"1.0","storageCapacity":16.0,"isDarkmodeOn":true,"keyboards":["com.google.android.inputmethod.latin","com.google.android.tts"]}}}' "https://vpn-api.proton.me/auth/v4/credentialless")

access_token=$(echo "$credentialless" | jq -r '.AccessToken')

# Get VPN credentials
# shellcheck disable=SC2086
vpn_credential=$(curl ${CURL_VERBOSE:+-v} ${CURL_NO_SILENT--sS} --fail --connect-timeout 10 --retry 3 -X "GET" -H "X-Pm-Appversion: android-vpn@$app_version+play" -H "X-Pm-Locale: en" -H "User-Agent: ProtonVPN/$app_version (Android 15; google sdk_gphone64_x86_64)" -H "Accept: application/vnd.protonmail.v1+json" -H "X-Pm-Uid: $x_pm_uid" -H "Authorization: Bearer $access_token" -b "Session-Id=$session_id; Tag=vpn-b" "https://vpn-api.proton.me/vpn/v2")

vpn_name=$(echo "$vpn_credential" | jq -r '.VPN.Name')
vpn_password=$(echo "$vpn_credential" | jq -r '.VPN.Password')

# Start generating OpenVPN config
cp proton-sample.ovpn $OVPN_CONF
sed -i '/^remote .*$/d' $OVPN_CONF
sed -i "s/^verb .*$/verb $VERB/g" $OVPN_CONF
echo "
<auth-user-pass>
$vpn_name
$vpn_password
</auth-user-pass>" >>$OVPN_CONF

if [[ "$ARGS" = *" --no-ipv6 "* ]]; then
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

if [[ "$ARGS" = *" --no-dns-leak "* ]]; then
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

# Get the VPN IP list, and add them to openvpn conf
# shellcheck disable=SC2086
logical_servers=$(curl ${CURL_VERBOSE:+-v} ${CURL_NO_SILENT--sS} --fail --connect-timeout 10 --retry 3 -X "GET" -H "X-Pm-Country: US" -H "If-Modified-Since: Thu, 01 Jan 1970 00:00:00 GMT" -H "X-Pm-Appversion: android-vpn@$app_version+play" -H "X-Pm-Locale: en" -H "User-Agent: ProtonVPN/$app_version (Android 15; google sdk_gphone64_x86_64)" -H "Accept: application/vnd.protonmail.v1+json" -H "X-Pm-Uid: $x_pm_uid" -H "Authorization: Bearer $access_token" -b "Session-Id=$session_id; Tag=vpn-b" "https://vpn-api.proton.me/vpn/v1/logicals?WithTranslations=en&WithEntriesForProtocols=WireGuardUDP%2CWireGuardTCP%2COpenVPNUDP%2COpenVPNTCP%2CWireGuardTLS&WithState=true" | jq -r '.LogicalServers | map(select(.Tier == 0))')

for logical_server_b64 in $(echo "$logical_servers" | jq -r '.[] | @base64'); do
    logical_server=$(echo "$logical_server_b64" | base64 -d)
    name=$(echo "$logical_server" | jq -r '.Name')
    city=$(echo "$logical_server" | jq -r '.City')
    load=$(echo "$logical_server" | jq -r '.Load')
    entry_ip=$(echo "$logical_server" | jq -r '.Servers[0].EntryIP')
    sed -i "/^remote-random$/i remote $entry_ip 443 # $name ($city) load: $load%" $OVPN_CONF
done

echo "OpenVPN conf was created with success !"
echo -e "\e[36m$ sudo openvpn --config $OVPN_CONF\e[0m"
