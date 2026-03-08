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
  exec 9</dev/tty

  printf "✅ Connected\n"

  present_rules "O"

  printf "%s\n" "$(encode_message "HELLO" "")" >&4
  read -p "Press Enter to start the game"
  printf "%s\n" "$(encode_message "CLIENT_READY" "")" >&4
  printf "Waiting for server...\n"

  local old_x=1
  local old_y=1
  local current_x=1
  local current_y=1

  set_tile $current_x $current_y "X"

  while true; do

    if IFS= read -r -t 0.2 line <&3; then

      printf "Received%s" "$line"
      decode_message "$line"

      case $header in
      START)
        print_map 0
        ;;
      MOVE_X)
        old_x=$current_x
        current_x=$payload

        set_tile "$old_x" "$current_y" " "
        set_tile "$current_x" "$current_y" "X"
        print_map 0
        ;;

      MOVE_Y)
        old_y=$current_y
        current_y=$payload

        set_tile "$current_x" "$old_y" " "
        set_tile "$current_x" "$current_y" "X"
        print_map 0
        ;;

      SET)
        read -r x y <<<"$(get_free_spot)"

        if [[ $x == -1 ]]; then
          #TODO: End game "DRAW"
          break
        fi

        current_x=$x
        current_y=$y

        print_map 1
        turn "O"
        ;;
      esac

      continue
    fi

    if ! kill -0 "$nc_pid" 2>/dev/null; then
      printf "❌ Disconnected (nc exited)\n" >&2
      break
    fi

    if ! ss -Htnp 2>/dev/null | grep -F "pid=$nc_pid" | grep -q ESTAB; then
      printf "❌ Disconnected (socket gone; killing stuck nc)\n" >&2
      kill "$nc_pid" 2>/dev/null || true
      break
    fi
  done

  exec 3<&- 4>&-
  wait -n "$nc_pid" 2>/dev/null || true
  kill "$nc_pid" 2>/dev/null || true
  exec 3<&- 4>&-
}
