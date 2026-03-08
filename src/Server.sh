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

  present_rules "X"

  local waiting_said=0

  exec 9</dev/tty

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

    local old_x=1
    local old_y=1
    local current_x=1
    local current_y=1

    set_tile $current_x $current_y "X"

    if ((!connected && !waiting_said)); then
      printf "Waiting for clients...\n"
      waiting_said=1
    fi

    while IFS= read -r line <&3; do
      if ((connected == 0)); then
        printf "Client connected\n"
        printf "Waiting for client to be ready!\n"
        connected=1
        continue
      fi

      decode_message "$line"

      case $header in
      CLIENT_READY)
        printf "Client is ready!\n"
        flush_input
        read -p "Press Enter to start the game!"

        printf "%s\n" "$(encode_message "START" "")" >&4

        print_map 1
        turn "X"
        ;;

      MOVE_X)
        old_x=$current_x
        current_x=$payload

        set_tile "$old_x" "$current_y" " "
        set_tile "$current_x" "$current_y" "O"
        print_map 0
        ;;

      MOVE_Y)
        old_y=$current_y
        current_y=$payload

        set_tile "$current_x" "$old_y" " "
        set_tile "$current_x" "$current_y" "O"
        print_map 0
        ;;
      SET)
        read -r x y <<<"$payload"

        old_x=$x
        old_y=$y
        current_x=$x
        current_y=$y

        set_tile "$current_x" "$current_y" "X"

        print_map 1
        turn "X"
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
