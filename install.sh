#!/usr/bin/env bash
# Fedora gaming optimizations — install orchestrator
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
DO_SYSTEM=0
DO_USER=0

usage() {
  cat <<'EOF'
Usage:
  sudo ./install.sh --system [--dry-run]
       ./install.sh --user   [--dry-run]
  sudo ./install.sh --all    [--dry-run]   # system half requires root

Options:
  --system   Install packages and system-wide configs (root)
  --user     Install per-user Steam/Heroic/MangoHud configs
  --all      Run system then user (must start as root for system)
  --dry-run  Print actions without applying
  -h, --help Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --system) DO_SYSTEM=1 ;;
    --user) DO_USER=1 ;;
    --all) DO_SYSTEM=1; DO_USER=1 ;;
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

if [[ $DO_SYSTEM -eq 1 ]]; then
  if [[ "${EUID}" -ne 0 ]]; then
    echo "System install requires root. Re-run: sudo $0 --system"
    exit 1
  fi
  bash "${ROOT}/scripts/10-system.sh"
fi

if [[ $DO_USER -eq 1 ]]; then
  if [[ "${EUID}" -eq 0 ]]; then
    TARGET_USER="${SUDO_USER:-}"
    if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
      echo "User install must not run as root without SUDO_USER."
      echo "After system install, run as your normal user: ./install.sh --user"
      exit 1
    fi
    echo "==> Re-running user install as ${TARGET_USER}..."
    sudo -u "${TARGET_USER}" -H env FGO_DRY_RUN="$DRY_RUN" FGO_ROOT="$ROOT" \
      bash "${ROOT}/scripts/20-user.sh"
  else
    bash "${ROOT}/scripts/20-user.sh"
  fi
fi

echo ""
echo "Done. See docs/HOWTO.md for Steam launch options and reboot notes."
