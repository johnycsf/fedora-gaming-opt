#!/usr/bin/env bash
# Fail if forbidden gaming env vars are present globally.
set -euo pipefail

FORBIDDEN=(
  ENABLE_GAMESCOPE_WSI
  DXVK_ASYNC
  DXVK_STATE_CACHE
  DXVK_HUD
  RADV_PERFTEST
  AMD_VULKAN_ICD
  VKD3D_CONFIG
  mesa_glthread
  PROTON_ENABLE_NVAPI
  PROTON_NO_ESYNC
  PROTON_NO_FSYNC
)

FOUND=0

check_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  for var in "${FORBIDDEN[@]}"; do
    if grep -Eq "(^|[[:space:]]|export )${var}=" "$file" 2>/dev/null; then
      echo "FAIL: ${var} found in ${file}"
      FOUND=1
    fi
  done
}

echo "==> Auditing global env for forbidden gaming variables..."

check_file /etc/environment
check_file /etc/profile
for f in /etc/profile.d/*.sh; do
  check_file "$f"
done
check_file "${HOME}/.bashrc"
check_file "${HOME}/.bash_profile"
check_file "${HOME}/.profile"
check_file "${HOME}/.pam_environment"
for f in "${HOME}/.config/environment.d"/*.conf; do
  check_file "$f"
done

# Steam must not be wrapped with gamemoderun
STEAM_DESKTOP="${HOME}/.local/share/applications/steam.desktop"
if [[ -f "${STEAM_DESKTOP}" ]] && grep -q 'gamemoderun' "${STEAM_DESKTOP}"; then
  echo "FAIL: ${STEAM_DESKTOP} wraps Steam with gamemoderun (causes 0x3008)"
  FOUND=1
fi

# Heroic Flatpak should not force Gamescope WSI
if command -v flatpak >/dev/null; then
  OVERRIDES="$(flatpak override --user --show com.heroicgameslauncher.hgl 2>/dev/null || true)"
  if grep -q 'ENABLE_GAMESCOPE_WSI' <<<"${OVERRIDES}"; then
    echo "FAIL: Heroic Flatpak override sets ENABLE_GAMESCOPE_WSI"
    FOUND=1
  fi
fi

# Current systemd user env
if command -v systemctl >/dev/null; then
  ENV_OUT="$(systemctl --user show-environment 2>/dev/null || true)"
  for var in "${FORBIDDEN[@]}"; do
    if grep -Eq "^${var}=" <<<"${ENV_OUT}"; then
      echo "FAIL: ${var} is set in systemd --user environment"
      FOUND=1
    fi
  done
fi

if [[ $FOUND -ne 0 ]]; then
  echo ""
  echo "Audit failed. See docs/LESSONS.md"
  exit 1
fi

echo "Audit passed."
