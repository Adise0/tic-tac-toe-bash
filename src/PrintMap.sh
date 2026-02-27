#!/usr/bin/env bash
set -euo pipefail

print_map() {
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
}
