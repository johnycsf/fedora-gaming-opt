#!/usr/bin/env bash
# Rollback user-level changes from this repo
set -euo pipefail

DRY_RUN="${FGO_DRY_RUN:-0}"
HOME_DIR="${HOME}"
STATE_DIR="${HOME_DIR}/.local/state/fedora-gaming-opt"
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

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run user rollback as root."
  exit 1
fi

echo "==> Rolling back user gaming configs..."

restore_file "${HOME_DIR}/.config/MangoHud/MangoHud.conf" || run rm -f "${HOME_DIR}/.config/MangoHud/MangoHud.conf"
restore_file "${HOME_DIR}/.config/vkBasalt/vkBasalt.conf" || run rm -f "${HOME_DIR}/.config/vkBasalt/vkBasalt.conf"
restore_file "${HOME_DIR}/.local/share/applications/steam.desktop" || run rm -f "${HOME_DIR}/.local/share/applications/steam.desktop"
restore_file "${HOME_DIR}/.local/bin/steam-gaming" || run rm -f "${HOME_DIR}/.local/bin/steam-gaming"
update-desktop-database "${HOME_DIR}/.local/share/applications" 2>/dev/null || true

if command -v flatpak >/dev/null; then
  run flatpak override --user --reset com.heroicgameslauncher.hgl || true
fi

HEROIC_CFG="${HOME_DIR}/.var/app/com.heroicgameslauncher.hgl/config/heroic/config.json"
restore_file "${HEROIC_CFG}" || echo "No saved Heroic config found; leaving it unchanged."

echo "User rollback done."
