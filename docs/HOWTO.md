# How to use this after a Fedora reinstall

## Before you start

This setup targets an **AMD Radeon Fedora desktop** similar to the hardware listed in the README. It is not guaranteed on other machines. Use `--dry-run`, read the disclaimer in the README, and keep rollback available.

## Prerequisites

1. Fresh Fedora Workstation install (40+ recommended), preferably a desktop with an AMD GPU.
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

./manage.sh install
# Log out / log in once so the gamemode group applies.
```

### Flags

| Command | Purpose |
|---------|---------|
| `./manage.sh install` | Install packages plus system/user configuration |
| `./manage.sh install --dry-run` | Print installation actions without changing anything |
| `./manage.sh install --sysctl-tweaks` | Opt in to conservative sysctl compatibility settings |
| `./manage.sh performance on` | Enable desktop CPU/GPU performance mode before gaming |
| `./manage.sh performance off` | Restore the prior tuned profile and AMD automatic mode |
| `./manage.sh audit` | Fail if forbidden global gaming environment variables exist |
| `./manage.sh status` | Check readiness and current performance mode |
| `./manage.sh benchmark before` | Record a baseline system snapshot for a repeatable game test |

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

- Enables GameMode, esync, and fsync
- Caps download/shader workers at four by default so they do not compete with games
- Leaves msync and NVAPI as per-game opt-ins
- Adds only a conservative shader-cache setting

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

# Non-destructive readiness and baseline capture
./manage.sh status
./manage.sh benchmark before

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
| Desktop feels “stuck” at max clocks | Run `./performance.sh off` to restore AMD automatic mode |

## Full rollback

```bash
./manage.sh uninstall
```

Packages installed by the scripts (mangohud, gamescope, etc.) are **not** removed by uninstall, so Steam/games keep working. Remove them with `dnf` if you want a clean slate:

```bash
sudo dnf remove mangohud gamescope corectrl vkBasalt vulkan-tools
```
