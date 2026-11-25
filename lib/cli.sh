parse_args() {
  protocol=""
  server_query=""
  output_file=""
  NO_IPV6=0
  NO_DNS_LEAK=0
  RANDOM_SERVER=0
  CONNECT=0
  GEN=0

  while (($#)); do
    case "$1" in
      -p|--protocol)
        (($# >= 2)) || { echo "Missing value for --protocol" >&2; return 2; }
        protocol=$2
        shift 2
        ;;
      --server)
        (($# >= 2)) || { echo "Missing value for --server" >&2; return 2; }
        server_query=$2
        shift 2
        ;;
      --output)
        (($# >= 2)) || { echo "Missing value for --output" >&2; return 2; }
        output_file=$2
        shift 2
        ;;
      --no-ipv6)
        NO_IPV6=1
        shift
        ;;
      --no-dns-leak)
        NO_DNS_LEAK=1
        shift
        ;;
      -r|--random)
        RANDOM_SERVER=1
        shift
        ;;
      --connect)
        CONNECT=1
        shift
        ;;
      --gen)
        GEN=1
        shift
        ;;
      -h|--help)
        print_help
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        print_help >&2
        return 2
        ;;
    esac
  done

  if (( CONNECT && ! GEN )); then
    return 0
  fi

  case "$protocol" in
    openvpn|wireguard) ;;
    *)
      echo "Specify --protocol openvpn or --protocol wireguard" >&2
      return 2
      ;;
  esac

  if [[ -z "$output_file" ]]; then
    if [[ "$protocol" == openvpn ]]; then
      output_file="vpn.ovpn"
    else
      output_file="vpn.conf"
    fi
  fi

  case "$output_file" in
    /*) ;;
    *) output_file="$PWD/$output_file" ;;
  esac
}

print_help() {
  cat <<'EOF'
Usage: ./main.sh --protocol openvpn|wireguard [options]

Options:
  --server TEXT       Server name or city to select
  -r, --random        Pick a random server
  --output PATH       Config output path
  --no-ipv6           Add the OpenVPN IPv6-disable settings
  --no-dns-leak       Add the OpenVPN DNS settings
  --connect           Dial (config must exist unless --gen)
  --gen               Generate config before connecting
  -h, --help          Show this help

Modes:
  generate only:        ./main.sh -p openvpn
  connect only:         ./main.sh -p openvpn --connect
  generate + connect:   ./main.sh -p openvpn --connect --gen
EOF
}   
