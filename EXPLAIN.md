# protonvpn-credentialless

Connect to ProtonVPN free servers without an account. No GUI, no app, no credentials.

## How it works

Spoofs the ProtonVPN Android app to hit Proton's API directly, then generates
a ready-to-use config file.
 

main.sh
│
├─ parse_args (lib/cli.sh)
├─ check_requirements (lib/requirements.sh)
│
└─ run_flow (lib/flow.sh)
│
├─ [1] create_session (lib/auth.sh)
├─ [2] get_credentialless_token (lib/auth.sh)
├─ [3] fetch_servers (lib/vpn_api.sh)
├─ [4] select_server (lib/server_selection.sh)
│
├─ WireGuard path:
│ ├─ get_keypair (lib/wireguard.sh)
│ ├─ register_certificate (lib/wireguard.sh)
│ └─ generate_wireguard_config (lib/wireguard.sh)
│
└─ OpenVPN path:
├─ fetch_vpn_credentials (lib/vpn_api.sh)
└─ generate_ovpn (lib/openvpn.sh)


## Files

| File | Role |
|------|------|
| `main.sh` | Entry point. Parses args, calls `run_flow` |
| `lib/cli.sh` | Argument parsing + help text |
| `lib/requirements.sh` | Checks for `curl`, `jq`, `awk`, etc. |
| `lib/auth.sh` | Session creation + credentialless (guest) token |
| `lib/vpn_api.sh` | Fetches server list + OpenVPN credentials |
| `lib/server_selection.sh` | Random / by-name / fzf / lowest-load selection |
| `lib/openvpn.sh` | Generates `.ovpn` from template + credentials |
| `lib/wireguard.sh` | Gets EC keypair, registers cert, generates `.conf` |
| `lib/flow.sh` | Orchestrates all 6 steps in order |
| `proton-sample.ovpn` | OpenVPN template (only needed for OpenVPN path) |

## Usage

```bash
# WireGuard (recommended)
./main.sh --protocol wireguard --server "US"
sudo wg-quick up vpn.conf
sudo wg-quick down vpn.conf

# Random server
./main.sh --protocol wireguard -r

# OpenVPN
./main.sh --protocol openvpn --server "Germany"
sudo openvpn --config vpn.ovpn

# Interactive picker (requires fzf)
./main.sh --protocol wireguard

 
Options
Flag	Description
--protocol openvpn|wireguard	Protocol (required)
--server TEXT	Filter by name or city
-r, --random	Pick a random server
--output PATH	Output config path
--no-ipv6	Disable IPv6 in OpenVPN config
--no-dns-leak	Force Cloudflare DNS in OpenVPN config
Dependencies
Required	Why
curl	HTTP requests to Proton API
jq	JSON parsing
awk	Cookie extraction
base64	Key encoding
python3	X25519 key derivation (WireGuard only)
sed, cp	Config generation (OpenVPN only)
Optional	Why
fzf	Interactive server picker
openvpn	Actually connect (OpenVPN path)
wireguard	Actually connect (WireGuard path)
What it does NOT do

    No account required (uses credentialless/guest auth)

    No stored credentials (session is ephemeral, deleted on next run)

    No root needed to generate config (only to connect)

    No daemon, no background process

Security notes

    session_credentials.json is created with chmod 600 and deleted on next run

    cookie.jar is deleted on next run

    Config files contain private keys — don't commit or share them


Save it:

```bash
cat > EXPLAIN.md << 'ENDOF'
(paste the above)
ENDOF
