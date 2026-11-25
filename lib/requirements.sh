check_requirements() {
  local protocol=$1
  local command_name
  local required=(curl jq awk)

  case "$protocol" in
    openvpn)
      required+=(cp sed)
      ;;
    wireguard)
      required+=(python3)
      ;;
    *)
      echo "Unsupported protocol: $protocol" >&2
      return 2
      ;;
  esac

  for command_name in "${required[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      echo "Required command not found: $command_name" >&2
      return 1
    fi
  done
}
