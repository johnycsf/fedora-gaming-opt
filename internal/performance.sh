#!/usr/bin/env bash
# Convenience wrapper for the installed system performance toggle.
set -euo pipefail
exec sudo /usr/local/bin/fedora-gaming-performance "${1:-status}"
