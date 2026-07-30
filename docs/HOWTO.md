# How to use this after a Fedora reinstall

## Prerequisites

1. Fresh Fedora Workstation install (40+ recommended).
2. Working internet connection.
3. User account with `sudo`.
4. Steam and/or Heroic installed (can be done before or after these scripts).

Recommended base packages before or with this repo:

```bash
sudo dnf install -y steam gamemode
flatpak install -y flathub com.heroicgameslauncher.hgl
```

## Install

```bash
git clone https://github.com/johnycsf/fedora-gaming-opt.git
cd fedora-gaming-opt

sudo ./install.sh --system
# Log out / log in so the gamemode group applies

./install.sh --user
sudo reboot
```

### Flags

| Command | Purpose |
|---------|---------|
| `sudo ./install.sh --system` | Packages + system configs |
| `./install.sh --user` | Per-user configs (Heroic, MangoHud, etc.) |
| `./install.sh --all` | System then user (system half still needs sudo) |
| `./install.sh --dry-run` | Print actions without changing anything |
| `./scripts/audit.sh` | Fail if forbidden global env vars exist |

## Steam settings (manual, once)

**Steam → Settings:**

1. **Shader Pre-Caching**
   - Enable Steam Shader Pre-Caching
   - Allow background processing of Vulkan shaders
2. **Downloads** — set download threads close to your CPU core count (e.g. 6 on i5-9600K)
3. Launch Steam from the normal app menu — **never** with `gamemoderun`

### Per-game launch options

Right-click game → Properties → Launch Options:

| Goal | Launch options |
|------|----------------|
| Default | `gamemoderun %command%` |
| + FPS overlay | `gamemoderun mangohud %command%` |
| Gamescope (set refresh) | `gamemoderun gamescope -W 1920 -H 1080 -r 144 -f -- %command%` |
| First-run stutter help | `gamemoderun mangohud DXVK_ASYNC=1 %command%` |

Optional per-game RADV flag (AMD only, when needed):

```
RADV_PERFTEST=gpl gamemoderun %command%
```

## Heroic

The user script:

- Enables GameMode, esync, fsync, msync
- Sets download/shader workers to CPU core count
- Adds only safe env vars (`MESA_SHADER_CACHE_MAX_SIZE`, `OMP_NUM_THREADS`)

Install/update GE-Proton in Heroic as usual (GE-Proton-latest is fine).

## CoreCtrl (optional)

Open **CoreCtrl** for fan curves / power limit / mild overclock on the RX 6700 XT.

- Prefer conservative OC: +50–100 MHz core / +200–400 MHz VRAM
- Watch temps with MangoHud (`Shift+F12`)

## Verify

```bash
# GameMode daemon
systemctl --user status gamemoded
gamemoded -s

# AMD GPU profile (should be high after boot service)
cat /sys/class/drm/card*/device/power_dpm_force_performance_level

# Vulkan
vulkaninfo --summary | head -40

# Safety audit
./scripts/audit.sh
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Steam error `0x3008` | `./scripts/fix-steam.sh` — do not launch Steam via `gamemoderun` |
| Apps fail with Gamescope WSI / swapchain errors | Ensure `ENABLE_GAMESCOPE_WSI` is unset globally; re-run `./scripts/audit.sh` |
| GameMode inactive | Log out/in after system install; `systemctl --user enable --now gamemoded` |
| Heroic GameMode fails in Flatpak | Re-run `./install.sh --user` |
| Desktop feels “stuck” at max clocks | Normal with AMD `high` profile; use CoreCtrl or GameMode-only if you prefer auto |

## Full rollback

```bash
./uninstall.sh --user
sudo ./uninstall.sh --system
sudo reboot
```

Packages installed by the scripts (mangohud, gamescope, etc.) are **not** removed by uninstall, so Steam/games keep working. Remove them with `dnf` if you want a clean slate:

```bash
sudo dnf remove mangohud gamescope corectrl vkBasalt vulkan-tools
```
