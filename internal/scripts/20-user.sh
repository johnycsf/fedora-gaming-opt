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

configure_steam_shader_threads() {
  local steam_dir="$1" cfg tmp
  cfg="${steam_dir}/steam_dev.cfg"
  if [[ "${DRY_RUN}" == "1" ]]; then
    echo "DRY-RUN: set ${cfg} unShaderBackgroundProcessingThreads ${CORES}"
    return
  fi

  backup_file "${cfg}"
  mkdir -p "${steam_dir}"
  tmp="$(mktemp "${cfg}.tmp.XXXXXX")"
  if [[ -f "${cfg}" ]]; then
    awk -v threads="${CORES}" '
      $1 == "unShaderBackgroundProcessingThreads" {
        if (!written++) print "unShaderBackgroundProcessingThreads " threads
        next
      }
      { print }
      END { if (!written) print "unShaderBackgroundProcessingThreads " threads }
    ' "${cfg}" >"${tmp}"
  else
    printf 'unShaderBackgroundProcessingThreads %s\n' "${CORES}" >"${tmp}"
  fi
  chmod 0644 "${tmp}"
  mv "${tmp}" "${cfg}"
  echo "    Configured ${cfg} to use ${CORES} logical CPU threads."
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

echo "==> Configuring Steam Vulkan shader compilation..."
declare -A seen_steam_dirs=()
steam_dirs=(
  "${HOME_DIR}/.steam/steam"
  "${HOME_DIR}/.steam/debian-installation"
  "${HOME_DIR}/.local/share/Steam"
  "${HOME_DIR}/.local/share/steam"
  "${HOME_DIR}/.var/app/com.valvesoftware.Steam/data/Steam"
)
for steam_dir in "${steam_dirs[@]}"; do
  if [[ -d "${steam_dir}" ]]; then
    steam_dir="$(readlink -f "${steam_dir}")"
  elif [[ "${steam_dir}" == "${HOME_DIR}/.var/app/com.valvesoftware.Steam/data/Steam" ]] && \
       command -v flatpak >/dev/null && flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
    : # Steam Flatpak is installed; its data directory can be created safely.
  else
    continue
  fi
  [[ -n "${seen_steam_dirs[${steam_dir}]:-}" ]] && continue
  seen_steam_dirs["${steam_dir}"]=1
  configure_steam_shader_threads "${steam_dir}"
done
if [[ "${#seen_steam_dirs[@]}" -eq 0 ]]; then
  echo "    Steam was not detected — skipping shader-thread configuration."
fi

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
echo "  Steam shaders: configured to use ${CORES} logical CPU threads; restart Steam"
echo "  MangoHud: Shift+F12 in-game when launched with mangohud"
echo "  Audit: ./manage.sh audit"
