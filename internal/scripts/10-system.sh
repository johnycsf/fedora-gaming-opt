#!/usr/bin/env bash
# System-level gaming setup (requires root)
set -euo pipefail

ROOT="${FGO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DRY_RUN="${FGO_DRY_RUN:-0}"
USER_NAME="${SUDO_USER:-${USER:-}}"
AMD_PERFORMANCE="${FGO_AMD_PERFORMANCE:-0}"
SYSCTL_TWEAKS="${FGO_SYSCTL_TWEAKS:-0}"
STATE_DIR="/var/lib/fedora-gaming-opt"
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

declare -A gpu_vendors=()
has_amd_gpu=0
if compgen -G /sys/class/drm/card*/device/vendor >/dev/null; then
  for vendor_path in /sys/class/drm/card*/device/vendor; do
    case "$(cat "${vendor_path}" 2>/dev/null || true)" in
      0x1002) gpu_vendors[AMD]=1; has_amd_gpu=1 ;;
      0x10de) gpu_vendors[NVIDIA]=1 ;;
      0x8086) gpu_vendors[Intel]=1 ;;
      *) gpu_vendors[Other]=1 ;;
    esac
  done
fi
gpu_names=("${!gpu_vendors[@]}")
if [[ "${#gpu_names[@]}" -gt 0 ]]; then
  gpu_summary="$(IFS=', '; printf '%s' "${gpu_names[*]}")"
else
  gpu_summary="unknown"
fi

echo "==> System gaming setup"
echo "    Target user: ${USER_NAME:-unknown}"
echo "    Detected GPU vendor(s): ${gpu_summary}"

if [[ -z "${USER_NAME}" || "${USER_NAME}" == "root" ]]; then
  echo "WARNING: Could not detect non-root user for gamemode group."
fi

echo "==> Installing packages..."
packages=(
  gamemode gamemode.i686 \
  mangohud mangohud.i686 \
  gamescope \
  vulkan-tools \
  lm_sensors \
  vkBasalt vkBasalt.i686 \
  tuned
)
if [[ "${has_amd_gpu}" -eq 1 ]]; then
  packages+=(corectrl)
else
  echo "    Skipping CoreCtrl (AMD GPU utility)."
fi
run dnf install -y "${packages[@]}"

if [[ -n "${USER_NAME}" && "${USER_NAME}" != "root" ]]; then
  echo "==> Adding ${USER_NAME} to gamemode group..."
  run usermod -aG gamemode "${USER_NAME}"
fi

echo "==> Installing GameMode config..."
backup_file /etc/gamemode.ini
run install -Dm644 "${ROOT}/internal/configs/etc/gamemode.ini" /etc/gamemode.ini

if [[ "${SYSCTL_TWEAKS}" == "1" ]]; then
  echo "==> Installing optional conservative sysctl tweaks..."
  backup_file /etc/sysctl.d/99-gaming.conf
  run install -Dm644 "${ROOT}/internal/configs/etc/sysctl.d/99-gaming.conf" /etc/sysctl.d/99-gaming.conf
  if [[ "$DRY_RUN" != "1" ]]; then
    sysctl --system >/dev/null || true
  fi
else
  echo "==> Skipping optional sysctl tweaks (use --sysctl-tweaks to opt in)."
fi

echo "==> Installing minimal global env (shader cache size only)..."
backup_file /etc/profile.d/gaming-env.sh
run install -Dm644 "${ROOT}/internal/configs/etc/profile.d/gaming-env.sh" /etc/profile.d/gaming-env.sh

echo "==> Installing desktop performance toggle..."
backup_file /usr/local/bin/fedora-gaming-performance
run install -Dm755 "${ROOT}/internal/configs/usr/local/bin/fedora-gaming-performance" /usr/local/bin/fedora-gaming-performance

if [[ "${has_amd_gpu}" -eq 1 ]]; then
  echo "==> AMD GPU detected — installing AMDGPU helper for the performance toggle..."
  backup_file /usr/local/bin/amdgpu-gaming-profile
  backup_file /etc/systemd/system/amdgpu-gaming-profile.service
  run install -Dm755 "${ROOT}/internal/configs/usr/local/bin/amdgpu-gaming-profile" /usr/local/bin/amdgpu-gaming-profile
  # The helper is invoked only by the explicit performance toggle. Do not
  # leave an always-on boot service behind from older releases.
  run systemctl disable --now amdgpu-gaming-profile.service 2>/dev/null || true
  run rm -f /etc/systemd/system/amdgpu-gaming-profile.service
  if [[ "$DRY_RUN" != "1" ]]; then
    systemctl daemon-reload
  fi
  echo "    Use ./manage.sh performance on before gaming and ./manage.sh performance off afterward."
else
  echo "==> ${gpu_summary} GPU detected — skipping AMD-only GPU controls; generic gaming setup remains enabled."
fi

if [[ "${AMD_PERFORMANCE}" == "1" ]]; then
  echo "==> Enabling desktop performance mode after install..."
  run /usr/local/bin/fedora-gaming-performance on
fi

if [[ "$DRY_RUN" != "1" ]]; then
  mkdir -p "${STATE_DIR}"
  printf '%s\n' "${BACKUP_DIR}" >"${STATE_DIR}/latest-backup"
fi

echo ""
echo "System setup complete."
echo "Log out/in for gamemode group, then run: ./manage.sh install"
echo "Toggle desktop mode any time: ./manage.sh performance on|off|status"
