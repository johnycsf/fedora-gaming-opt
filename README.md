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

## Who this is for

Tuned and battle-tested on:

- **CPU:** Intel Core i5-9600K (6 cores)
- **GPU:** AMD Radeon RX 6700 XT (RADV)
- **RAM:** 32 GB
- **Desktop:** GNOME Wayland
- **Distro:** Fedora Workstation 40+ (desktop)

**Reasonable fit:** similar AMD Radeon + Fedora desktop gaming PCs.  
**Poor fit / skip:** NVIDIA-primary systems, Intel-only iGPU laptops, servers, or anyone who needs maximum stability over FPS.

The default install avoids persistent AMD power/kernel tuning. Desktop
performance mode is an explicit, reversible toggle on AMD hardware.

After a fresh Fedora install on matching hardware, clone this repo and run the install scripts.

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
| Packages | GameMode, MangoHud, gamescope, CoreCtrl, vulkan-tools, vkBasalt, lm_sensors |
| GameMode | Per-game governor and priority management; no core pinning by default |
| AMDGPU | Reversible high-performance toggle on AMD hardware |
| Sysctl | Optional, conservative compatibility preset |
| Global env | **Only** `MESA_SHADER_CACHE_MAX_SIZE=512MB` |
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
