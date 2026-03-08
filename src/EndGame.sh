#!/usr/bin/env bash
set -euo pipefail

end_game() {

  printf "\n\n"
  type=$1

  case $type in
  "DRAW")
    printf "The game ended in a draw!"
    ;;
  "WIN")
    printf "      YOU WON!"
    ;;
  "LOSS")
    printf "      YOU LOST!\nGet good brother"
    ;;
  esac

  printf "\n\n"

  flush_input
  read -r -p "Press Enter to continue..."
  exit 0
}
