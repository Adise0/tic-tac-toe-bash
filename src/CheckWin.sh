#!/usr/bin/env bash
set -euo pipefail

check_win() {

  local value
  for ((y = 0; y < rows; y++)); do
    value=$(get_tile 0 "$y")
    [[ $value == " " ]] && continue
    if [[ $(get_tile 1 "$y") == "$value" && $(get_tile 2 "$y") == "$value" ]]; then
      echo 1
      return 0
    fi
  done

  for ((x = 0; x < 3; x++)); do
    value=$(get_tile "$x" 0)
    [[ $value == " " ]] && continue
    if [[ $(get_tile "$x" 1) == "$value" && $(get_tile "$x" 2) == "$value" ]]; then
      echo 1
      return 0
    fi
  done

  value=$(get_tile 0 0)
  if [[ $value != " " && $(get_tile 1 1) == "$value" && $(get_tile 2 2) == "$value" ]]; then
    echo 1
    return 0
  fi

  if [[ $value != " " && $(get_tile 1 1) == "$value" && $(get_tile 0 2) == "$value" ]]; then
    echo 1
    return 0
  fi

  echo 0
}
