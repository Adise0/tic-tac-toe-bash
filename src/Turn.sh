#!/usr/bin/env bash
set -euo pipefail

turn() {
  type=$1

  while true; do
    read -rsN1 key <&9

    if [[ $key == $'\e' ]]; then
      read -rsN2 -t 0.05 rest <&9 || rest=''
      key+="$rest"
    fi

    case "$key" in
    $'\e[A' | $'\eOA')
      if ((current_y == 0)); then
        continue
      fi
      old_y=$current_y
      current_y=$((current_y - 1))

      set_tile "$current_x" "$old_y" " "
      set_tile "$current_x" "$current_y" "$type"

      printf "%s\n" "$(encode_message "MOVE_Y" "$current_y")" >&4
      print_map 1
      ;;

    $'\e[B' | $'\eOB')
      if ((current_y == rows - 1)); then
        continue
      fi
      old_y=$current_y
      current_y=$((current_y + 1))

      set_tile "$current_x" "$old_y" " "
      set_tile "$current_x" "$current_y" "$type"

      printf "%s\n" "$(encode_message "MOVE_Y" "$current_y")" >&4
      print_map 1
      ;;

    $'\e[D' | $'\eOD')
      if ((current_x == 0)); then
        continue
      fi
      old_x=$current_x
      current_x=$((current_x - 1))

      set_tile "$old_x" "$current_y" " "
      set_tile "$current_x" "$current_y" "$type"

      printf "%s\n" "$(encode_message "MOVE_X" "$current_x")" >&4
      print_map 1
      ;;

    $'\e[C' | $'\eOC')
      if ((current_x == cols - 1)); then
        continue
      fi
      old_x=$current_x
      current_x=$((current_x + 1))

      set_tile "$old_x" "$current_y" " "
      set_tile "$current_x" "$current_y" "$type"

      printf "%s\n" "$(encode_message "MOVE_X" "$current_x")" >&4
      print_map 1
      ;;

    $'\n' | $'\r')

      #TODO: Check victory

      read -r x y <<<"$(get_free_spot)"
      if [[ $x == -1 ]]; then
        #TODO: End game "DRAW"

        printf "%s\n" "$(encode_message "END" "draw")" >&4
        break
      fi

      old_x=$x
      old_y=$y
      current_x=$x
      current_y=$y

      printf "%s\n" "$(encode_message "SET" "$x $y")" >&4
      print_map 0
      break
      ;;

    '')
      continue
      ;;
    esac
  done
}
