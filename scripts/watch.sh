#!/usr/bin/env bash
set -euo pipefail

printf "[Pre-jobs] Running pre-watch jobs...\n"

run_after=1
while getopts "n" opt; do
  case "$opt" in
  n) run_after=0 ;;
  esac
done
shift $((OPTIND - 1))

get_config() {
  config="$1"
  input="$2"
  if [[ $input =~ $config[[:space:]]*=[[:space:]]*(.*) ]]; then
    value="${BASH_REMATCH[1]}"
    echo "$value"
    return 0
  fi
  return 1
}

appName=""
buildDir=""
defaultBuildDir="out/release"

if [ -f ".connfig" ]; then
  while IFS= read -r line; do
    if appName=$(get_config "AppName" "$line"); then
      break
    fi
    if buildDir=$(get_config "BuildDir" "$line"); then
      continue
    fi
  done <.config
  if [[ -z $appName ]]; then
    echo "Error: AppName not found in .config" >&2
    exit 1
  fi

  if [[ -z "$buildDir" ]]; then
    echo "Warning: BuildDir not found in .config, using default dir $defaultBuildDir" >&2
    buildDir=$defaultBuildDir
  fi
fi

printf "[Pre-jobs] Pre-watch jobs complete!\n"

printf "[Watcher] Starting watcher\n"

watchexec -w src -e sh -r \
  --stop-signal SIGTERM \
  --wrap-process=none \
  -E RUN_AFTER="$run_after" \
  -E APP_NAME="$appName" \
  -E BUILD_DIR="$buildDir" \
  -- bash -lc '
    set -m
    clear

    printf "[Watcher] Change detected\n"

    exec bash -lc "source src/Logish.sh"
  '
