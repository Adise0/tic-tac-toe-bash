#!/usr/bin/env bash
set -euo pipefail

encode_message() {
  header=$1
  payload=$2

  echo "${header}|${payload}"
}

decode_message() {
  local msg="$1"

  header="${msg%%|*}"
  payload="${msg#*|}"
}
