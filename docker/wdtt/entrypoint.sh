#!/bin/sh
set -eu

: "${WDTT_MAIN_PASSWORD:?WDTT_MAIN_PASSWORD is required}"

LISTEN="${WDTT_LISTEN:-0.0.0.0:56000}"
WG_PORT="${WDTT_WG_PORT:-56001}"
CONFIG_DIR="${WDTT_CONFIG_DIR:-/etc/wdtt}"
DNS_VALUE="${WDTT_DNS:-1.1.1.1,1.0.0.1}"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

set -- \
  /usr/local/bin/wdtt-server \
  -listen "$LISTEN" \
  -wg-port "$WG_PORT" \
  -config-dir "$CONFIG_DIR" \
  -password "$WDTT_MAIN_PASSWORD" \
  -dns "$DNS_VALUE"

if [ -n "${WDTT_ADMIN_ID:-}" ]; then
  set -- "$@" -admin "$WDTT_ADMIN_ID"
fi

if [ -n "${WDTT_BOT_TOKEN:-}" ]; then
  set -- "$@" -bot-token "$WDTT_BOT_TOKEN"
fi

exec "$@"
