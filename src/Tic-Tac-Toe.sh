#!/usr/bin/env bash
set -euo pipefail

SHUTTING_DOWN=0

kill_tree() {
  local parent="$1"
  local children

  # Get direct children only
  mapfile -t children < <(pgrep -P "$parent" 2>/dev/null || true)

  for child in "${children[@]}"; do
    kill_tree "$child"
  done

  # kill this process last
  kill -TERM "$parent" 2>/dev/null || true
}

cleanup_all() {
  [[ "${__CLEANING_UP:-0}" = 1 ]] && return 0
  __CLEANING_UP=1
  SHUTTING_DOWN=1
  set +e

  { printf '\e[?25h\e[0m' >&2; } 2>/dev/null
  stty sane 2>/dev/null || true

  kill_tree "$$"
  sleep 0.05
  # pkill -KILL -P $$ 2>/dev/null || true

  [[ -n "${PIPE_DIR:-}" ]] && rm -rf "$PIPE_DIR" 2>/dev/null || true
}
trap cleanup_all EXIT INT TERM

source "src/utils/Messages.sh"
source "src/utils/Prompt.sh"
source "src/Client.sh"
source "src/Server.sh"

type=$(prompt "Choose an option:" "Client" "Server")

if [[ $type = 0 ]]; then
  start_client
else
  start_server
fi
