#!/usr/bin/env bash
set -euo pipefail

print_map() {
  my_turn=$1
  clear

  printf "%s\n" "         |         |         "
  printf "%s\n" "   $(get_tile 0 0)     |    $(get_tile 1 0)    |    $(get_tile 2 0)    "
  printf "%s\n" "         |         |         "
  printf "%s\n" "---------|---------|---------"
  printf "%s\n" "         |         |         "
  printf "%s\n" "   $(get_tile 0 1)     |    $(get_tile 1 1)    |    $(get_tile 2 1)    "
  printf "%s\n" "         |         |         "
  printf "%s\n" "---------|---------|---------"
  printf "%s\n" "         |         |         "
  printf "%s\n" "   $(get_tile 0 2)     |    $(get_tile 1 2)    |    $(get_tile 2 2)    "
  printf "%s\n" "         |         |         "

  if ((my_turn)); then
    printf "\n\nMove with the arrow keys\n"
    printf "Press ENTER to confirm position\n"
  else
    printf "\n\nIt's not your turn!"
  fi

}
