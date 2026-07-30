#!/usr/bin/env bash
# Rollback user-level changes from this repo
set -euo pipefail

DRY_RUN="${FGO_DRY_RUN:-0}"
HOME_DIR="${HOME}"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY-RUN: $*"
  else
    "$@"
  fi
}

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run user rollback as root."
  exit 1
fi

echo "==> Rolling back user gaming configs..."

run rm -f "${HOME_DIR}/.config/MangoHud/MangoHud.conf"
run rm -f "${HOME_DIR}/.config/vkBasalt/vkBasalt.conf"
run rm -f "${HOME_DIR}/.local/share/applications/steam.desktop"
run rm -f "${HOME_DIR}/.local/bin/steam-gaming"
update-desktop-database "${HOME_DIR}/.local/share/applications" 2>/dev/null || true

if command -v flatpak >/dev/null; then
  run flatpak override --user --reset com.heroicgameslauncher.hgl || true
fi

HEROIC_CFG="${HOME_DIR}/.var/app/com.heroicgameslauncher.hgl/config/heroic/config.json"
if [[ -f "${HEROIC_CFG}" && "$DRY_RUN" != "1" ]]; then
  python3 - <<'PY'
import json
from pathlib import Path
p = Path.home() / ".var/app/com.heroicgameslauncher.hgl/config/heroic/config.json"
with open(p) as f:
    cfg = json.load(f)
d = cfg.setdefault("defaultSettings", {})
d["maxWorkers"] = 0
d["enableMsync"] = False
banned = {"MESA_SHADER_CACHE_MAX_SIZE", "OMP_NUM_THREADS"}
d["enviromentOptions"] = [
    e for e in d.get("enviromentOptions", []) if e.get("key") not in banned
]
with open(p, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print(f"Reverted conservative fields in {p}")
PY
elif [[ "$DRY_RUN" == "1" ]]; then
  echo "DRY-RUN: revert Heroic config.json fields"
fi

echo "User rollback done."
