#!/usr/bin/env bash
# User-level gaming setup (no sudo)
set -euo pipefail

ROOT="${FGO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN="${FGO_DRY_RUN:-0}"
HOME_DIR="${HOME}"
CORES="$(nproc 2>/dev/null || echo 6)"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY-RUN: $*"
  else
    "$@"
  fi
}

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run user setup as root."
  exit 1
fi

echo "==> User gaming setup for ${HOME_DIR}"
echo "    Detected CPU cores: ${CORES}"

echo "==> MangoHud config..."
run mkdir -p "${HOME_DIR}/.config/MangoHud"
run mkdir -p "${HOME_DIR}/Games/mangohud-logs"
if [[ "$DRY_RUN" == "1" ]]; then
  echo "DRY-RUN: write MangoHud.conf"
else
  sed "s|__HOME__|${HOME_DIR}|g; s|__GPU_TEXT__|GPU|g" \
    "${ROOT}/configs/home/.config/MangoHud/MangoHud.conf" \
    > "${HOME_DIR}/.config/MangoHud/MangoHud.conf"
fi

echo "==> vkBasalt config..."
run mkdir -p "${HOME_DIR}/.config/vkBasalt"
run install -Dm644 "${ROOT}/configs/home/.config/vkBasalt/vkBasalt.conf" \
  "${HOME_DIR}/.config/vkBasalt/vkBasalt.conf"

echo "==> Ensuring Steam is NOT wrapped with gamemoderun..."
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
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY-RUN: python3 update-heroic-config.py"
  else
    CORES="${CORES}" python3 "${ROOT}/scripts/update-heroic-config.py"
  fi
else
  echo "==> Heroic Flatpak not installed — skipping Heroic overrides"
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
echo "  Audit: ./scripts/audit.sh"
