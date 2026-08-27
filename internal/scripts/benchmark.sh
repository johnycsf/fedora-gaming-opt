#!/usr/bin/env bash
# Record a repeatable system snapshot alongside MangoHud logs.
set -euo pipefail

label="${1:-baseline}"
safe_label="$(printf '%s' "${label}" | tr -cd '[:alnum:]_.-')"
[[ -n "${safe_label}" ]] || safe_label=baseline
out_dir="${HOME}/Games/fedora-gaming-opt-benchmarks"
out_file="${out_dir}/$(date +%Y%m%d-%H%M%S)-${safe_label}.txt"
mkdir -p "${out_dir}"

{
  echo "label=${safe_label}"
  echo "timestamp=$(date --iso-8601=seconds)"
  uname -a
  echo
  echo "== GameMode =="
  gamemoded -s 2>&1 || true
  echo
  echo "== CPU governor =="
  grep -H . /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | head -32 || true
  echo
  echo "== AMD power profile =="
  grep -H . /sys/class/drm/card*/device/{power_dpm_force_performance_level,pp_power_profile_mode} 2>/dev/null || true
  echo
  echo "== Vulkan summary =="
  vulkaninfo --summary 2>/dev/null | head -80 || true
} >"${out_file}"

echo "Wrote ${out_file}"
echo "Run the same game/scene with MangoHud logging, then compare FPS, 1% lows, frametimes, temperatures, and power."
