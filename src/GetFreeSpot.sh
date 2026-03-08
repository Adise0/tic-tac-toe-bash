#!/usr/bin/env bash
set -euo pipefail

get_free_spot() {
  for ((y = 0; y < 3; y++)); do
    for ((x = 0; x < 3; x++)); do
      if [[ "$(get_tile "$x" "$y")" == " " ]]; then
        echo "$x $y"
        return 0
      fi
    done
  done

  echo "-1"
}
