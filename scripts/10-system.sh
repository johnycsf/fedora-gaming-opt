#!/usr/bin/env bash
# System-level gaming setup (requires root)
set -euo pipefail

ROOT="${FGO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN="${FGO_DRY_RUN:-0}"
USER_NAME="${SUDO_USER:-${USER:-}}"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY-RUN: $*"
  else
    "$@"
  fi
}

echo "==> System gaming setup"
echo "    Target user: ${USER_NAME:-unknown}"

if [[ -z "${USER_NAME}" || "${USER_NAME}" == "root" ]]; then
  echo "WARNING: Could not detect non-root user for gamemode group."
fi

echo "==> Installing packages..."
run dnf install -y \
  gamemode gamemode.i686 \
  mangohud mangohud.i686 \
  gamescope \
  corectrl \
  vulkan-tools \
  lm_sensors \
  vkBasalt vkBasalt.i686 \
  tuned

if [[ -n "${USER_NAME}" && "${USER_NAME}" != "root" ]]; then
  echo "==> Adding ${USER_NAME} to gamemode group..."
  run usermod -aG gamemode "${USER_NAME}"
fi

echo "==> Installing GameMode config..."
run install -Dm644 "${ROOT}/configs/etc/gamemode.ini" /etc/gamemode.ini

echo "==> Installing sysctl tweaks..."
run install -Dm644 "${ROOT}/configs/etc/sysctl.d/99-gaming.conf" /etc/sysctl.d/99-gaming.conf
if [[ "$DRY_RUN" != "1" ]]; then
  sysctl --system >/dev/null || true
fi

echo "==> Installing minimal global env (shader cache size only)..."
run install -Dm644 "${ROOT}/configs/etc/profile.d/gaming-env.sh" /etc/profile.d/gaming-env.sh

echo "==> Installing AMDGPU gaming profile helper + service..."
run install -Dm755 "${ROOT}/configs/usr/local/bin/amdgpu-gaming-profile" /usr/local/bin/amdgpu-gaming-profile
run install -Dm644 "${ROOT}/configs/etc/systemd/system/amdgpu-gaming-profile.service" \
  /etc/systemd/system/amdgpu-gaming-profile.service
if [[ "$DRY_RUN" != "1" ]]; then
  systemctl daemon-reload
  systemctl enable --now amdgpu-gaming-profile.service
fi

echo "==> Applying AMDGPU kernel parameter..."
if command -v grubby >/dev/null; then
  run grubby --update-kernel=ALL --args="amdgpu.ppfeaturemask=0xfff7ffff"
else
  echo "    WARNING: grubby missing — add amdgpu.ppfeaturemask=0xfff7ffff to GRUB manually"
fi

echo "==> Enabling tuned throughput-performance..."
run systemctl enable --now tuned
if [[ "$DRY_RUN" != "1" ]]; then
  tuned-adm profile throughput-performance || true
  sensors-detect --auto >/dev/null 2>&1 || true
fi

echo ""
echo "System setup complete."
echo "Log out/in for gamemode group, then run: ./install.sh --user"
echo "Reboot recommended for kernel args."
