# ProtonVPN - CredentialLess

Simple script that generates an OpenVPN configuration file for use with [ProtonVPN](https://protonvpn.com/).

There's no need to manually create a ProtonVPN account — the script leverages Proton's `/credentialless` API to automatically generate a new one each time it runs.

## Pre-requisites

- **curl**: Used for making HTTP(S) requests.
- **OpenVPN**: Required to create and manage the VPN tunnel.
- **UFW (Uncomplicated Firewall)**: Used to configure firewall rules and allow VPN traffic.

## Usage

```bash
# Generate new conf and credentials
./connect.sh generate

# Connect to ProtonVPN
./connect.sh connect

# Create a strict killswitch
./connect.sh ks

# For oneclick privacy
./connect.sh ks g c
```
# ./generate.sh -options (not needed for most users)
| Options           | Description                                                                                                    |
| ----------------- | -------------------------------------------------------------------------------------------------------------- |
| `-v`              | Verbose mode.                                                                                                  |
| `-vvv`            | Very verbose mode (enables `set -x` for full debugging output).                                                |
| `--no-ipv6`       | Explicitly disables IPv6 in the generated OpenVPN configuration. Required if IPv6 is disabled on your host.    |
| `--no-dns-leak`   | Add up/down scripts to avoid using your ISP's DNS servers (DNS queries go through the tunnel anyway).          |

