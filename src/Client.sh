#!/usr/bin/env bash
set -euo pipefail

start_client() {
  printf "Starting client...\n"

  default_ip=localhost
  default_port=5555

  read -r -p "Ip to connect to (Default: $default_ip): " ip
  read -r -p "Port (Default: $default_port): " port
  [[ -z "${ip}" ]] && ip=$default_ip
  [[ -z "${port}" ]] && port=$default_port

  if ! nc -z -w 1 "$ip" "$port" 2>/dev/null; then
    echo "❌ Cannot connect to $ip:$port"
    return 1
  fi

  coproc NC { exec nc "$ip" "$port" 2>/dev/null; }
  nc_pid=$NC_PID

  exec 3<&"${NC[0]}"
  exec 4>&"${NC[1]}"

  printf "✅ Connected\n"
  printf "%s\n" "$(encode_message "HELLO" "")" >&4

  while true; do

    local server_salt=0

    if IFS= read -r -t 0.2 line <&3; then
      printf "Received: %s\n" "$line"

      decode_message "$line"

      case $header in
      OK_HEADER)
        server_salt=$payload
        printf "Saved salt: %s\n" "$server_salt"

        read -r -p "User: " user
        read -r -p "Password: " password

        hashed_password="$(printf "%s" "$password" | sha256sum | cut -d' ' -f1)"
        hash_salt="$(printf "%s%s" "$hashed_password" "$server_salt" | sha256sum | cut -d' ' -f1)"

        printf '%s\n' "$(encode_message "AUTH" "$user:$hash_salt")" >&4
        ;;

      KO_FORMAT)
        printf "Invalid format!\n"
        ;;

      KO_AUTH)
        printf "Invalid auth!\n"
        ;;

      OK_AUTH)
        printf "Logged in!\n"
        ;;
      esac

      continue
    fi

    # If nc died, we're done
    if ! kill -0 "$nc_pid" 2>/dev/null; then
      printf "❌ Disconnected (nc exited)\n" >&2
      break
    fi

    # If nc is alive but no ESTABLISHED socket -> connection is gone; nc is just stuck
    if ! ss -Htnp 2>/dev/null | grep -F "pid=$nc_pid" | grep -q ESTAB; then
      printf "❌ Disconnected (socket gone; killing stuck nc)\n" >&2
      kill "$nc_pid" 2>/dev/null || true
      break
    fi
  done

  # cleanup fds
  exec 3<&- 4>&-

  # Wait for *either* the reader or nc to exit
  wait -n "$nc_pid" 2>/dev/null || true

  # Cleanup
  kill "$nc_pid" 2>/dev/null || true
  exec 3<&- 4>&-
}
