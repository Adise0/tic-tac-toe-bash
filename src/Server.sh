#!/usr/bin/env bash
set -euo pipefail

start_server() {

  printf "Starting server...\n"
  local default_port=5555
  local port
  read -r -p "What port do you want to use? (Default $default_port): " port
  [[ -z "${port}" ]] && port=$default_port

  local ip
  ip=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
  printf "Listening on %s:%s\n" "$ip" "$port"
  printf "(Waiting for clients...)\n"

  while ((!SHUTTING_DOWN)); do
    coproc NC { nc -l "$port" 2>/dev/null; }
    nc_pid=$NC_PID

    exec 3<&"${NC[0]}"
    exec 4>&"${NC[1]}"

    local connected=0
    local hello_done=0
    local kill_conn=0
    local hash_bd="b221d9dbb083a7f33428d7c2a3c3198ae925614d70210e28716ccaa7cd4ddb79"
    local salt=0

    while IFS= read -r line <&3; do
      if ((connected == 0)); then
        printf "Client connected\n"
        connected=1
      fi

      printf "Received: %s\n" "$line"
      decode_message "$line"

      if ((hello_done == 0)); then
        if [[ $header != "HELLO" ]]; then
          printf '%s\n' "$(encode_message "KO_HEADER" "")" >&4
          sleep 0.05
          kill_conn=1
          break
        else
          hello_done=1
          salt=$((RANDOM % 10))
          printf '%s\n' "$(encode_message "OK_HEADER" "$salt")" >&4
        fi
      fi

      case $header in
      AUTH)
        if [[ $payload =~ ^([^:]+):([^:]+)$ ]]; then
          user="${BASH_REMATCH[1]}"
          client_hash="${BASH_REMATCH[2]}"

          local hash_salt=$(printf "%s%s" "$hash_bd" "$salt" | sha256sum | cut -d' ' -f1)

          if [ "$client_hash" != "$hash_salt" ]; then
            printf '%s\n' "$(encode_message "KO_AUTH" "")" >&4
            kill_conn=1
            break
          fi
          printf '%s\n' "$(encode_message "OK_AUTH" "")" >&4
        else
          printf '%s\n' "$(encode_message "KO_FORMAT" "")" >&4
          kill_conn=1
          break
        fi
        ;;
      esac

      ((SHUTTING_DOWN)) && break
    done

    # If we want to drop just this connection:
    if ((kill_conn)); then
      exec 3<&- 4>&-
      kill "$nc_pid" 2>/dev/null || true
      wait "$nc_pid" 2>/dev/null || true
      printf "Client disconnected (killed)\n\n"
      continue
    fi

    # Server shutdown:
    if ((SHUTTING_DOWN)); then
      exec 3<&- 4>&-
      kill "$nc_pid" 2>/dev/null || true
      wait "$nc_pid" 2>/dev/null || true
      break
    fi

    # Normal disconnect:
    wait "$nc_pid" 2>/dev/null || true
    exec 3<&- 4>&-

    if ((connected == 1)); then
      printf "Client disconnected\n\n"
    fi
  done
}
