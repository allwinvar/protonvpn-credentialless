#!/bin/bash
set -uo pipefail

PASS=0
FAIL=0

run() {
    local desc="$1"; shift
    echo "=== $desc ==="
    if "$@"; then
        echo "--- PASS ---"; ((PASS++)) || true
    else
        echo "--- FAIL ---"; ((FAIL++)) || true
    fi
    echo
}

run "gen openvpn"    ./main.sh -p openvpn
run "gen wireguard"  ./main.sh -p wireguard
run "connect openvpn"    ./main.sh -p openvpn --connect
run "connect wireguard"  ./main.sh -p wireguard --connect
run "gen+connect openvpn"    ./main.sh -p openvpn --connect --gen
run "gen+connect wireguard"  ./main.sh -p wireguard --connect --gen
#run "gen random wireguard" ./main.sh -p wireguard -r 
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]] || exit 1
