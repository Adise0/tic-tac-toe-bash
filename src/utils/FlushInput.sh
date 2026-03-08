#!/usr/bin/env bash
set -euo pipefail

flush_input() {

  while read -r -t 0.01 _ </dev/tty; do :; done

}
