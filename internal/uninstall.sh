#!/usr/bin/env bash
# Fedora gaming optimizations — uninstall orchestrator
set -euo pipefail

ROOT="${FGO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN=0
DO_SYSTEM=0
DO_USER=0

usage() {
  cat <<'EOF'
Usage:
  ./manage.sh uninstall [--dry-run]

Removes configs/services installed by this repo.
Does not remove DNF packages (mangohud, gamescope, etc.).
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

if [[ $DO_USER -eq 1 ]]; then
  if [[ "${EUID}" -eq 0 ]]; then
    TARGET_USER="${SUDO_USER:-}"
    if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
      echo "Run ./manage.sh uninstall from your normal account."
      exit 1
    fi
    sudo -u "${TARGET_USER}" -H env FGO_DRY_RUN="$DRY_RUN" FGO_ROOT="$ROOT" \
      bash "${ROOT}/internal/scripts/rollback-20-user.sh"
  else
    bash "${ROOT}/internal/scripts/rollback-20-user.sh"
  fi
fi

if [[ $DO_SYSTEM -eq 1 ]]; then
  if [[ "${EUID}" -ne 0 ]]; then
    echo "System uninstall requires root. Re-run: sudo $0 --system"
    exit 1
  fi
  bash "${ROOT}/internal/scripts/rollback-10-system.sh"
fi

echo ""
echo "Rollback complete. Reboot recommended."
