#!/usr/bin/env bash
# Fedora Gaming Opt control center.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

ui_setup() {
  if [[ "${NO_COLOR:-}" == "1" ]]; then return; fi
  if [[ -t 1 || -n "${FORCE_COLOR:-}" ]]; then
    UI_RESET=$'\e[0m'; UI_BOLD=$'\e[1m'
    UI_RED=$'\e[38;2;243;139;168m'; UI_GREEN=$'\e[38;2;166;227;161m'
    UI_YELLOW=$'\e[38;2;249;226;175m'; UI_BLUE=$'\e[38;2;137;180;250m'
    UI_MAUVE=$'\e[38;2;203;166;247m'; UI_TEAL=$'\e[38;2;148;226;213m'
  fi
}
ui_banner() { printf '\n%s%s══ %s %s══%s\n' "${UI_MAUVE:-}" "${UI_BOLD:-}" "$1" "${2:-}" "${UI_RESET:-}"; }
ui_step() { printf '%s▸%s %s\n' "${UI_BLUE:-}" "${UI_RESET:-}" "$*"; }
ui_ok() { printf '%s✓%s %s\n' "${UI_GREEN:-}" "${UI_RESET:-}" "$*"; }
ui_error() { printf '%s✗%s %s\n' "${UI_RED:-}" "${UI_RESET:-}" "$*" >&2; }
ui_style_task_output() {
  local line
  while IFS= read -r line || [[ -n "${line}" ]]; do
    case "${line}" in
      '==>'*) printf '%s%s%s\n' "${UI_BLUE:-}" "${line}" "${UI_RESET:-}" ;;
      *WARNING*|*Skipping*|DRY-RUN:*) printf '%s%s%s\n' "${UI_YELLOW:-}" "${line}" "${UI_RESET:-}" ;;
      *ERROR*|*' requires root'*|*'Do not run'*) printf '%s%s%s\n' "${UI_RED:-}" "${line}" "${UI_RESET:-}" ;;
      *complete*|Done.*|*'No AMD GPU detected'*) printf '%s%s%s\n' "${UI_GREEN:-}" "${line}" "${UI_RESET:-}" ;;
      *) printf '%s\n' "${line}" ;;
    esac
  done
}
run_task() { "$@" 2>&1 | ui_style_task_output; }
ui_setup

usage() {
  printf '%s%sUsage:%s ./manage.sh <command> [options]\n\n' "${UI_MAUVE:-}" "${UI_BOLD:-}" "${UI_RESET:-}"
  cat <<'EOF'

Commands:
  install [--sysctl-tweaks] [--performance-on] [--dry-run]
  performance on|off|status
  status
  benchmark [label]
  audit
  fix-steam
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
    *) ui_error "Unknown install option: ${arg}"; exit 2 ;;
    esac
  done
  local -a opts=()
  (( sysctl )) && opts+=(--sysctl-tweaks)
  (( performance )) && opts+=(--amd-performance)
  (( dry )) && opts+=(--dry-run)
  if [[ "${EUID}" -eq 0 ]]; then
    run_task "${ROOT}/internal/install.sh" --all "${opts[@]}"
  else
    run_task sudo FGO_ASSUME_YES=1 "${ROOT}/internal/install.sh" --system "${opts[@]}"
    run_task "${ROOT}/internal/install.sh" --user "${opts[@]}"
  fi
  ui_ok "Install complete. Use ./manage.sh performance on before gaming."
}

uninstall_all() {
  local -a opts=()
  [[ "${1:-}" == "--dry-run" ]] && opts+=(--dry-run)
  [[ $# -le 1 ]] || { ui_error "Unknown uninstall option: ${2:-}"; exit 2; }
  if [[ "${EUID}" -eq 0 ]]; then
    run_task "${ROOT}/internal/uninstall.sh" --all "${opts[@]}"
  else
    run_task "${ROOT}/internal/uninstall.sh" --user "${opts[@]}"
    run_task sudo "${ROOT}/internal/uninstall.sh" --system "${opts[@]}"
  fi
}

case "${1:-help}" in
  install) shift; ui_banner "Fedora Gaming Opt" "Install"; ui_step "Applying selected gaming optimizations"; install_all "$@" ;;
  performance) shift; ui_banner "Fedora Gaming Opt" "Performance mode"; run_task "${ROOT}/internal/performance.sh" "${1:-status}" ;;
  status) ui_banner "Fedora Gaming Opt" "Status"; run_task "${ROOT}/internal/scripts/check.sh"; run_task "${ROOT}/internal/performance.sh" status ;;
  benchmark) shift; ui_banner "Fedora Gaming Opt" "Benchmark"; run_task "${ROOT}/internal/scripts/benchmark.sh" "${1:-baseline}" ;;
  audit) ui_banner "Fedora Gaming Opt" "Audit"; run_task "${ROOT}/internal/scripts/audit.sh" ;;
  fix-steam) ui_banner "Fedora Gaming Opt" "Steam repair"; run_task "${ROOT}/internal/scripts/fix-steam.sh" ;;
  uninstall) shift; ui_banner "Fedora Gaming Opt" "Uninstall"; ui_step "Restoring backed-up configuration"; uninstall_all "$@"; ui_ok "Uninstall complete." ;;
  help|-h|--help) usage ;;
  *) ui_error "Unknown command: $1"; usage; exit 2 ;;
esac
