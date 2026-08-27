#!/usr/bin/env bash
# Rollback system-level changes from this repo
set -euo pipefail

DRY_RUN="${FGO_DRY_RUN:-0}"
STATE_DIR="/var/lib/fedora-gaming-opt"
BACKUP_DIR=""
[[ -f "${STATE_DIR}/latest-backup" ]] && BACKUP_DIR="$(cat "${STATE_DIR}/latest-backup")"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY-RUN: $*"
  else
    "$@"
  fi
}

restore_file() {
  local target="$1" state
  [[ -n "${BACKUP_DIR}" && -f "${BACKUP_DIR}/manifest" ]] || return 1
  state="$(awk -v path="${target}" '$2 == path { print $1 }' "${BACKUP_DIR}/manifest" | tail -1)"
  case "${state}" in
    present) run mkdir -p "$(dirname "${target}")"; run cp -a "${BACKUP_DIR}${target}" "${target}" ;;
    absent) run rm -f "${target}" ;;
    *) return 1 ;;
  esac
}

echo "==> Rolling back system gaming configs..."

run systemctl disable --now amdgpu-gaming-profile.service 2>/dev/null || true
restore_file /etc/systemd/system/amdgpu-gaming-profile.service || run rm -f /etc/systemd/system/amdgpu-gaming-profile.service
restore_file /usr/local/bin/amdgpu-gaming-profile || run rm -f /usr/local/bin/amdgpu-gaming-profile
if [[ "$DRY_RUN" != "1" ]]; then
  systemctl daemon-reload || true
fi

restore_file /etc/profile.d/gaming-env.sh || run rm -f /etc/profile.d/gaming-env.sh
restore_file /etc/sysctl.d/99-gaming.conf || run rm -f /etc/sysctl.d/99-gaming.conf
restore_file /etc/gamemode.ini || run rm -f /etc/gamemode.ini

if [[ "$DRY_RUN" != "1" ]]; then
  sysctl --system >/dev/null || true
fi

if command -v grubby >/dev/null; then
  run grubby --update-kernel=ALL --remove-args="amdgpu.ppfeaturemask=0xfff7ffff" || true
fi

echo "System rollback done. Packages were left installed."
