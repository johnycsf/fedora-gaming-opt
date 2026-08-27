#!/usr/bin/env bash
# User-level gaming setup (no sudo)
set -euo pipefail

ROOT="${FGO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DRY_RUN="${FGO_DRY_RUN:-0}"
HOME_DIR="${HOME}"
CORES="$(nproc 2>/dev/null || echo 6)"
STATE_DIR="${HOME_DIR}/.local/state/fedora-gaming-opt"
BACKUP_DIR="${STATE_DIR}/backup-$(date +%Y%m%d-%H%M%S)"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY-RUN: $*"
  else
    "$@"
  fi
}

backup_file() {
  local target="$1"
  [[ "$DRY_RUN" == "1" ]] && { echo "DRY-RUN: backup ${target}"; return; }
  mkdir -p "${BACKUP_DIR}$(dirname "${target}")"
  if [[ -e "${target}" ]]; then
    cp -a "${target}" "${BACKUP_DIR}${target}"
    printf 'present %s\n' "${target}" >>"${BACKUP_DIR}/manifest"
  else
    printf 'absent %s\n' "${target}" >>"${BACKUP_DIR}/manifest"
  fi
}

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run user setup as root."
  exit 1
fi

echo "==> User gaming setup for ${HOME_DIR}"
echo "    Detected CPU cores: ${CORES}"

echo "==> MangoHud config..."
backup_file "${HOME_DIR}/.config/MangoHud/MangoHud.conf"
run mkdir -p "${HOME_DIR}/.config/MangoHud"
run mkdir -p "${HOME_DIR}/Games/mangohud-logs"
if [[ "$DRY_RUN" == "1" ]]; then
  echo "DRY-RUN: write MangoHud.conf"
else
  sed "s|__HOME__|${HOME_DIR}|g; s|__GPU_TEXT__|GPU|g" \
    "${ROOT}/internal/configs/home/.config/MangoHud/MangoHud.conf" \
    > "${HOME_DIR}/.config/MangoHud/MangoHud.conf"
fi

echo "==> vkBasalt config..."
backup_file "${HOME_DIR}/.config/vkBasalt/vkBasalt.conf"
run mkdir -p "${HOME_DIR}/.config/vkBasalt"
run install -Dm644 "${ROOT}/internal/configs/home/.config/vkBasalt/vkBasalt.conf" \
  "${HOME_DIR}/.config/vkBasalt/vkBasalt.conf"

echo "==> Ensuring Steam is NOT wrapped with gamemoderun..."
backup_file "${HOME_DIR}/.local/share/applications/steam.desktop"
backup_file "${HOME_DIR}/.local/bin/steam-gaming"
# Never install a Steam .desktop that uses gamemoderun — that causes 0x3008.
run rm -f "${HOME_DIR}/.local/share/applications/steam.desktop"
run rm -f "${HOME_DIR}/.local/bin/steam-gaming"
update-desktop-database "${HOME_DIR}/.local/share/applications" 2>/dev/null || true

if command -v flatpak >/dev/null && flatpak info com.heroicgameslauncher.hgl >/dev/null 2>&1; then
  echo "==> Heroic Flatpak overrides (safe env only)..."
  run flatpak override --user --reset com.heroicgameslauncher.hgl
  run flatpak override --user com.heroicgameslauncher.hgl \
    --filesystem=xdg-run/gamemode-0 \
    --talk-name=org.freedesktop.GameMode \
    --env=MESA_SHADER_CACHE_MAX_SIZE=512MB

  echo "==> Updating Heroic config.json..."
  backup_file "${HOME_DIR}/.var/app/com.heroicgameslauncher.hgl/config/heroic/config.json"
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY-RUN: python3 update-heroic-config.py"
  else
    CORES="${CORES}" python3 "${ROOT}/internal/scripts/update-heroic-config.py"
  fi
else
  echo "==> Heroic Flatpak not installed — skipping Heroic overrides"
fi

if [[ "$DRY_RUN" != "1" ]]; then
  mkdir -p "${STATE_DIR}"
  printf '%s\n' "${BACKUP_DIR}" >"${STATE_DIR}/latest-backup"
fi

echo "==> Enabling gamemoded user service..."
if [[ "$DRY_RUN" == "1" ]]; then
  echo "DRY-RUN: systemctl --user enable --now gamemoded.service"
else
  systemctl --user enable --now gamemoded.service 2>/dev/null || \
    echo "    (gamemoded will start on next login)"
fi

echo ""
echo "User setup complete."
echo "  Steam: launch normally; use 'gamemoderun %command%' per game only"
echo "  MangoHud: Shift+F12 in-game when launched with mangohud"
echo "  Audit: ./manage.sh audit"
