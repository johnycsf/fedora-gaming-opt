#!/usr/bin/env bash
# Rollback system-level changes from this repo
set -euo pipefail

DRY_RUN="${FGO_DRY_RUN:-0}"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY-RUN: $*"
  else
    "$@"
  fi
}

echo "==> Rolling back system gaming configs..."

run systemctl disable --now amdgpu-gaming-profile.service 2>/dev/null || true
run rm -f /etc/systemd/system/amdgpu-gaming-profile.service
run rm -f /usr/local/bin/amdgpu-gaming-profile
if [[ "$DRY_RUN" != "1" ]]; then
  systemctl daemon-reload || true
fi

run rm -f /etc/profile.d/gaming-env.sh
run rm -f /etc/sysctl.d/99-gaming.conf
run rm -f /etc/gamemode.ini

if [[ "$DRY_RUN" != "1" ]]; then
  sysctl --system >/dev/null || true
fi

if command -v grubby >/dev/null; then
  run grubby --update-kernel=ALL --remove-args="amdgpu.ppfeaturemask=0xfff7ffff" || true
fi

echo "System rollback done. Packages were left installed."
