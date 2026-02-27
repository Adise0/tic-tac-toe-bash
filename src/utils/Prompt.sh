#!/usr/bin/env bash
set -euo pipefail

SELECTED="\033[4;38;5;45m"
RESET="\033[0m"

prompt() {

  local text="$1"
  shift 1
  local options=("$@")
  local currentOption=0
  local nOfOptions=$((${#options[@]} - 1))
  local currentOption=0
  local prevOption=0

  clear >&2
  printf '%s\n' "$text" >&2
  for i in "${!options[@]}"; do
    local line="$RESET"
    if [[ $currentOption == $i ]]; then line+=$SELECTED; fi
    line+="[$i] - ${options[$i]}"
    if [[ $currentOption == $i ]]; then line+=$RESET; fi
    printf "%b$line%b\n" >&2
  done

  print() {
    for i in "${!options[@]}"; do
      if [[ $i != $prevOption && $i != $currentOption ]]; then continue; fi

      local line=$RESET
      if [[ $currentOption == $i ]]; then line+=$SELECTED; fi
      line+="[$i] - ${options[$i]}"
      if [[ $currentOption == $i ]]; then line+=$RESET; fi
      echo -ne "\e[$(($i + 2));1H" >&2
      printf "%b$line%b\n" >&2
    done
  }

  moveUp() {
    ((currentOption--))
    if [[ $currentOption == -1 ]]; then currentOption=$nOfOptions; fi
  }

  moveDown() {
    ((currentOption++))
    if (($currentOption == $nOfOptions + 1)); then ((currentOption = 0)); fi
  }

  while true; do
    print
    prevOption=$currentOption

    read -rsN1 key

    if [[ $key == $'\e' ]]; then
      read -rsN2 -t 0.05 rest || rest=''
      key+="$rest"
    fi

    case "$key" in
    $'\e[A' | $'\eOA')
      moveUp
      ;;
    $'\e[B' | $'\eOB')
      moveDown
      ;;
    $'w')
      moveUp
      ;;
    $'s')
      moveDown
      ;;
    $'\n' | $'\r')
      break
      ;;
    '')
      continue
      ;;
    *)
      if [[ "$key" =~ ^[0-9]+$ ]] && ((key >= 0 && key <= $nOfOptions)); then
        currentOption=$key
      fi
      ;;
    esac
  done

  echo -ne "\e[?25h" >&2
  echo -ne "\e[$(($nOfOptions + 3));1H" >&2
  echo $currentOption
}
