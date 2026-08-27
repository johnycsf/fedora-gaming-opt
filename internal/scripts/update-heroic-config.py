#!/usr/bin/env python3
"""Tune Heroic config.json safely for Fedora gaming setups."""
from __future__ import annotations

import json
import os
from pathlib import Path

config_path = Path.home() / ".var/app/com.heroicgameslauncher.hgl/config/heroic/config.json"
if not config_path.exists():
    print(f"Heroic config not found at {config_path}")
    raise SystemExit(0)

cores = max(1, int(os.environ.get("CORES", os.cpu_count() or 6)))
# All-core workers can compete with a running game; keep the default bounded.
workers = min(4, cores)

with open(config_path) as f:
    config = json.load(f)

defaults = config.setdefault("defaultSettings", {})
defaults["maxWorkers"] = workers
defaults["useGameMode"] = True
defaults["enableEsync"] = True
defaults["enableFsync"] = True
defaults["enableMsync"] = False
defaults["autoInstallDxvk"] = True
defaults["autoInstallVkd3d"] = True
defaults["autoInstallDxvkNvapi"] = False

# Strip known-harmful globals; keep only safe defaults.
banned = {
    "RADV_PERFTEST",
    "DXVK_ASYNC",
    "DXVK_STATE_CACHE",
    "mesa_glthread",
    "PROTON_ENABLE_NVAPI",
    "VKD3D_CONFIG",
    "AMD_VULKAN_ICD",
    "ENABLE_GAMESCOPE_WSI",
}
allowed = {
    "MESA_SHADER_CACHE_MAX_SIZE": "512MB",
}

env_opts = [
    entry
    for entry in defaults.get("enviromentOptions", [])
    if entry.get("key") not in banned
]
existing = {e.get("key") for e in env_opts}
for key, value in allowed.items():
    if key in existing:
        for entry in env_opts:
            if entry.get("key") == key:
                entry["value"] = value
    else:
        env_opts.append({"key": key, "value": value})
defaults["enviromentOptions"] = env_opts

with open(config_path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")

print(f"Updated {config_path} (maxWorkers={workers}, msync/NVAPI left opt-in)")
