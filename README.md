# Fedora Gaming Optimizations

![Repobeats analytics image](https://repobeats.axiom.co/api/embed/fdf157b607e0037a5b96b3ca298b4c82e9225b93.svg "Repobeats analytics image")

[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-ea4aaa?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/johnycsf)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Issues](https://img.shields.io/badge/issues-welcome-lightgrey.svg)](../../issues/new/choose)

Personal Fedora Workstation gaming setup for Steam and Heroic.

## Disclaimer — read this first

**This is not a universal “optimize any PC” toolkit.**  
It was written for **one** machine and is published so others can learn from it or adapt it. You are responsible for what you run on your computer.

- Provided **as-is**, with **no warranty** (see [LICENSE](LICENSE)).
- Advanced options can change kernel parameters, CPU/GPU power behavior, and sysctl.
- May reduce battery life, raise temps, or cause instability on hardware that does not match the reference system.
- Always try `--dry-run` first, and keep [uninstall/rollback](#rollback) available.
- `manage.sh` is the only public command. Its supporting implementation and templates live under `internal/`.

If you want something safer/vendor-supported, use Fedora’s defaults or tools aimed at your GPU vendor — do not treat this repo as official advice.

## Hardware support

Validated on this reference system:

- **CPU:** Intel Core i5-9600K (6 cores)
- **GPU:** AMD Radeon RX 6700 XT (RADV)
- **RAM:** 32 GB
- **Desktop:** GNOME Wayland
- **Distro:** Fedora Workstation 40+ (desktop)

The script is not tied to that CPU or GPU model. Its generic Fedora gaming setup
works with **AMD or Intel CPUs** and with **AMD, NVIDIA, or Intel GPUs**. It
detects GPU vendors at install time and keeps vendor-specific steps separate:

- **All supported GPU vendors:** GameMode, MangoHud, Gamescope, Vulkan tools,
  vkBasalt, Steam shader-thread configuration, Heroic configuration, and the
  reversible `tuned` performance profile.
- **AMD GPUs using the `amdgpu` driver:** additionally install CoreCtrl and
  enable the AMD GPU policy portion of `./manage.sh performance on|off` when
  the driver exposes its standard performance-policy control.
- **NVIDIA or Intel GPUs:** skip only the AMD-specific CoreCtrl and AMD power
  policy steps; the rest of the setup remains available.

The default install avoids persistent GPU power/kernel tuning. The performance
toggle is reversible on every CPU; its GPU policy portion is AMD-only. Servers,
laptops, and unusual driver stacks remain less tested, so start with
`./manage.sh install --dry-run`.

## Support this work

**If this project helped you — or saved you time tuning your system — please consider [sponsoring or donating](https://github.com/sponsors/johnycsf).** Open-source tools only stay maintained when people chip in.

Your sponsorship funds:

- Keeping Fedora gaming scripts tested on current releases
- Documenting safe tweaks, rollbacks, and what each change actually does
- More desktop and homelab quality-of-life projects

[![Sponsor johnycsf](https://img.shields.io/badge/GitHub%20Sponsors-Donate-ea4aaa?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/johnycsf)

👉 **[github.com/sponsors/johnycsf](https://github.com/sponsors/johnycsf)** — even a small monthly sponsorship helps keep development going.

## Quick start (after reinstall)

```bash
# Optional: install GitHub CLI if you want it later
# sudo dnf install -y gh

git clone https://github.com/johnycsf/fedora-gaming-opt.git
cd fedora-gaming-opt

./manage.sh install
# Log out and back in once so the gamemode group applies.
```

Or do both halves in one go (still log out afterward):

```bash
./manage.sh install
```

## What this installs

| Layer | Changes |
|-------|---------|
| Packages | GameMode, MangoHud, gamescope, vulkan-tools, vkBasalt, lm_sensors, tuned; CoreCtrl on AMD GPUs using `amdgpu` |
| GameMode | Per-game governor and priority management; no core pinning by default |
| GPU controls | Reversible AMD GPU power toggle where `amdgpu` exposes the standard control; safely skipped on NVIDIA and Intel GPUs |
| Sysctl | Optional, conservative compatibility preset |
| Global env | **Only** `MESA_SHADER_CACHE_MAX_SIZE=512MB` |
| Steam | Uses every logical CPU thread for Vulkan shader background processing (native and Flatpak) |
| Heroic | GameMode + esync/fsync, bounded workers, safe env only |
| Overlays | MangoHud + subtle vkBasalt CAS |

## Hard rules (do not break these)

1. **Never** wrap the Steam *client* with `gamemoderun` — causes error `0x3008`.
2. **Never** export `ENABLE_GAMESCOPE_WSI=1` globally — breaks normal apps.
3. Keep aggressive DXVK/RADV/Proton vars in **per-game** launch options only.

See [docs/LESSONS.md](docs/LESSONS.md) for why.

## Steam after install

Use GameMode **per game**, not on Steam itself:

```
gamemoderun %command%
```

With FPS overlay (Shift+F12):

```
gamemoderun mangohud %command%
```

The installer writes Steam's `unShaderBackgroundProcessingThreads` setting using
all logical CPU threads detected by `nproc`. It supports both native Steam and
Steam Flatpak; restart Steam after installation for the setting to take effect.

Full guide: [docs/HOWTO.md](docs/HOWTO.md)

## Measure before changing advanced settings

Record a baseline, run the same game/scene with MangoHud logging, then compare
frametimes, 1% lows, temperatures, and power—not only average FPS:

```bash
./manage.sh status
./manage.sh benchmark before
# test a repeatable game scene
./manage.sh benchmark after
```

Advanced options are deliberately opt-in:

```bash
./manage.sh install --sysctl-tweaks
./manage.sh performance on
./manage.sh performance off
```

## Rollback

```bash
./manage.sh uninstall
```

## Audit (optional)

Check that forbidden global env vars are not present:

```bash
./manage.sh audit
```

When moving from the repository's older always-on tuning, run `./manage.sh performance off` once. It disables the old boot service that forced AMD clocks high, selects the persistent `balanced` tuned profile if no earlier profile was saved, returns AMD policy to automatic, and removes the old `amdgpu.ppfeaturemask` boot setting. Reboot once only when that legacy boot setting is removed.

## License

MIT — see [LICENSE](LICENSE).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Credits

This repo packages or configures upstream software. See [CREDITS.md](CREDITS.md) for the main developers and projects this work builds on.

## Disclaimer

This project is provided **as is**. The author is **not responsible** for any loss, damage, data corruption, downtime, security issues, or other consequences from using it. Full text: [DISCLAIMER.md](DISCLAIMER.md).

## Bug reports & contributions

If you hit an error, please [open a GitHub Issue](../../issues/new/choose) and follow [CONTRIBUTING.md](CONTRIBUTING.md). Fixes via Pull Request are welcome. GitHub Issues/PRs are the supported way to report problems—there is no private support channel.

## Security

See [SECURITY.md](SECURITY.md) for how to report vulnerabilities.
