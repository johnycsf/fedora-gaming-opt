#!/usr/bin/env bash
# Non-destructive readiness check for this toolkit.
set -euo pipefail

failed=0
check() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "OK: $1"
  else
    echo "MISSING: $1"
    failed=1
  fi
}

echo "== Fedora gaming readiness =="
for cmd in gamemoded gamemoderun mangohud vulkaninfo; do check "${cmd}"; done
systemctl --user is-active --quiet gamemoded.service && echo "OK: gamemoded service active" || echo "INFO: gamemoded will start when a game requests it"

declare -A gpu_vendors=()
if compgen -G /sys/class/drm/card*/device/vendor >/dev/null; then
  for vendor_path in /sys/class/drm/card*/device/vendor; do
    case "$(cat "${vendor_path}" 2>/dev/null || true)" in
      0x1002) gpu_vendors[AMD]=1 ;;
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
echo "INFO: detected GPU vendor(s): ${gpu_summary}"
[[ -n "${gpu_vendors[AMD]:-}" ]] || echo "INFO: AMD-only GPU controls are skipped; generic gaming optimizations still apply."

if grep -qw 'amdgpu.ppfeaturemask=0xfff7ffff' /proc/cmdline 2>/dev/null; then
  echo "INFO: legacy AMD ppfeaturemask is enabled; uninstall the old setup if you no longer need it"
else
  echo "OK: no legacy AMD ppfeaturemask is enabled"
fi

exit "${failed}"
