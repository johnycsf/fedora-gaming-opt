#!/usr/bin/env bash
# Fedora gaming optimizations — install orchestrator
set -euo pipefail

ROOT="${FGO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN=0
DO_SYSTEM=0
DO_USER=0
AMD_PERFORMANCE=0
SYSCTL_TWEAKS=0

usage() {
  cat <<'EOF'
Usage:
  ./manage.sh install [--sysctl-tweaks] [--performance-on] [--dry-run]

Options:
  --system   Install packages and system-wide configs (root)
  --user     Install per-user Steam/Heroic/MangoHud configs
  --all      Run system then user (must start as root for system)
  --amd-performance  Enable desktop performance mode immediately after install
  --sysctl-tweaks    Install the optional conservative sysctl preset
  --dry-run  Print actions without applying
  -h, --help Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --system) DO_SYSTEM=1 ;;
    --user) DO_USER=1 ;;
    --all) DO_SYSTEM=1; DO_USER=1 ;;
    --amd-performance) AMD_PERFORMANCE=1 ;;
    --sysctl-tweaks) SYSCTL_TWEAKS=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

if [[ $DO_SYSTEM -eq 0 && $DO_USER -eq 0 ]]; then
  usage
  exit 1
fi

export FGO_DRY_RUN="$DRY_RUN"
export FGO_ROOT="$ROOT"
export FGO_AMD_PERFORMANCE="$AMD_PERFORMANCE"
export FGO_SYSCTL_TWEAKS="$SYSCTL_TWEAKS"

if [[ $DO_SYSTEM -eq 1 ]]; then
  if [[ "${EUID}" -ne 0 ]]; then
    echo "System install requires root. Re-run: sudo $0 --system"
    exit 1
  fi
  cat <<'EOF'
========================================================================
WARNING — hardware-specific gaming tweaks
========================================================================
This repo was built and tested for a Fedora Workstation desktop with an
AMD Radeon GPU (RX 6700 XT class) and an Intel desktop CPU.

It changes system packages, optional sysctl, GameMode, and (on AMD GPUs)
an explicit performance toggle. That can affect stability, thermals,
and performance on OTHER hardware.

- Use at your own risk. No warranty (see LICENSE / README disclaimer).
- Prefer: ./manage.sh install --dry-run
- Keep the uninstall/rollback scripts available.
- Not recommended for NVIDIA-primary laptops or production machines.

Press Enter to continue, or Ctrl+C to abort.
EOF
  if [[ "${FGO_ASSUME_YES:-0}" != "1" && "$DRY_RUN" != "1" ]]; then
    read -r _
  fi
  bash "${ROOT}/internal/scripts/10-system.sh"
fi

if [[ $DO_USER -eq 1 ]]; then
  if [[ "${EUID}" -eq 0 ]]; then
    TARGET_USER="${SUDO_USER:-}"
    if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
      echo "User install must not run as root without SUDO_USER."
      echo "After system install, run as your normal user: ./manage.sh install"
      exit 1
    fi
    echo "==> Re-running user install as ${TARGET_USER}..."
    sudo -u "${TARGET_USER}" -H env FGO_DRY_RUN="$DRY_RUN" FGO_ROOT="$ROOT" \
      FGO_AMD_PERFORMANCE="$AMD_PERFORMANCE" FGO_SYSCTL_TWEAKS="$SYSCTL_TWEAKS" \
      bash "${ROOT}/internal/scripts/20-user.sh"
  else
    bash "${ROOT}/internal/scripts/20-user.sh"
  fi
fi

echo ""
echo "Done. See docs/HOWTO.md for Steam launch options and performance-mode notes."
