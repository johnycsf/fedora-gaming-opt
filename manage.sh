#!/usr/bin/env bash
# Fedora Gaming Opt control center.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

usage() {
  cat <<'EOF'
Usage: ./manage.sh <command> [options]

Commands:
  install [--sysctl-tweaks] [--performance-on] [--dry-run]
  performance on|off|status
  status
  benchmark [label]
  audit
  uninstall [--dry-run]
  help
EOF
}

install_all() {
  local sysctl=0 performance=0 dry=0 arg
  for arg in "$@"; do
    case "${arg}" in
      --sysctl-tweaks) sysctl=1 ;;
      --performance-on) performance=1 ;;
      --dry-run) dry=1 ;;
      *) echo "Unknown install option: ${arg}" >&2; exit 2 ;;
    esac
  done
  local -a opts=()
  (( sysctl )) && opts+=(--sysctl-tweaks)
  (( performance )) && opts+=(--amd-performance)
  (( dry )) && opts+=(--dry-run)
  if [[ "${EUID}" -eq 0 ]]; then
    "${ROOT}/install.sh" --all "${opts[@]}"
  else
    sudo FGO_ASSUME_YES=1 "${ROOT}/install.sh" --system "${opts[@]}"
    "${ROOT}/install.sh" --user "${opts[@]}"
  fi
  echo "Install complete. Use ./manage.sh performance on before gaming."
}

uninstall_all() {
  local -a opts=()
  [[ "${1:-}" == "--dry-run" ]] && opts+=(--dry-run)
  [[ $# -le 1 ]] || { echo "Unknown uninstall option: ${2:-}" >&2; exit 2; }
  if [[ "${EUID}" -eq 0 ]]; then
    "${ROOT}/uninstall.sh" --all "${opts[@]}"
  else
    "${ROOT}/uninstall.sh" --user "${opts[@]}"
    sudo "${ROOT}/uninstall.sh" --system "${opts[@]}"
  fi
}

case "${1:-help}" in
  install) shift; install_all "$@" ;;
  performance) shift; exec "${ROOT}/performance.sh" "${1:-status}" ;;
  status) "${ROOT}/scripts/check.sh"; exec "${ROOT}/performance.sh" status ;;
  benchmark) shift; exec "${ROOT}/scripts/benchmark.sh" "${1:-baseline}" ;;
  audit) exec "${ROOT}/scripts/audit.sh" ;;
  uninstall) shift; uninstall_all "$@" ;;
  help|-h|--help) usage ;;
  *) echo "Unknown command: $1" >&2; usage; exit 2 ;;
esac
