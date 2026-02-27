#!/usr/bin/env bash
set -euo pipefail

present_rules() {
  clear

  printf "Welcome to tic-tac-toe, you are %s\n" $1

  printf "Controls:\n"
  printf "Arrow keys to move around the map!\n"
  printf "Press Enter to confirm a move\n\n"
}
