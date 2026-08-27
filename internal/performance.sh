#!/usr/bin/env bash
# Convenience wrapper for the installed system performance toggle.
set -euo pipefail

mode="${1:-status}"
helper="/usr/local/bin/fedora-gaming-performance"

if [[ ! -x "${helper}" ]]; then
  if [[ "${mode}" == "status" ]]; then
    echo "Performance mode is not installed yet."
    echo "Run ./manage.sh install to provision the system helper, then check status again."
    exit 0
  fi
  echo "Performance mode is not installed yet. Run ./manage.sh install first." >&2
  exit 1
fi

exec sudo "${helper}" "${mode}"
