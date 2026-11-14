#!/usr/bin/env bash
#
# Turns the production lock (guard-production.sh) on or off.
# The choice lives in ${CLAUDE_PLUGIN_DATA}/production_lock and takes effect immediately.
#
# Usage: production-lock.sh status | on | off

set -u

to_unix_path() {
    if [ -n "$1" ] && command -v cygpath >/dev/null 2>&1; then
        cygpath -u "$1"
    else
        printf '%s' "$1"
    fi
}

DATA_DIR="$(to_unix_path "${CLAUDE_PLUGIN_DATA:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/data/fabrica-de-asas-no-ar-fabricadeasas}")"
STATE_FILE="$DATA_DIR/production_lock"

current() {
    if [ -f "$STATE_FILE" ] && [ "$(tr -d '\r\n' < "$STATE_FILE")" = off ]; then
        echo off
    else
        echo on
    fi
}

case "${1:-}" in
    status) echo "production_lock=$(current)" ;;
    on | off)
        mkdir -p "$DATA_DIR" &&
            printf '%s\n' "$1" > "$STATE_FILE" &&
            echo "production_lock=$1 (takes effect immediately)"
        ;;
    *) echo "Use: status | on | off" >&2; exit 1 ;;
esac
