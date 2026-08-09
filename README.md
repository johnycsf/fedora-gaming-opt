# Fedora Gaming Optimizations

Reusable setup for a Fedora Workstation gaming PC with Steam and Heroic.

Tuned and battle-tested on:

- **CPU:** Intel Core i5-9600K (6 cores)
- **GPU:** AMD Radeon RX 6700 XT (RADV)
- **RAM:** 32 GB
- **Desktop:** GNOME Wayland
- **Distro:** Fedora Workstation 40+

After a fresh Fedora install, clone this repo and run the install scripts.

## Quick start (after reinstall)

```bash
# Optional: install GitHub CLI if you want it later
# sudo dnf install -y gh

git clone https://github.com/johnycsf/fedora-gaming-opt.git
cd fedora-gaming-opt

# 1) System packages + configs (needs sudo)
sudo ./install.sh --system

# 2) Log out and back in (gamemode group)

# 3) User configs (Steam/Heroic/MangoHud) — no sudo
./install.sh --user

# 4) Reboot so kernel GPU args apply
sudo reboot
```

Or do both halves in one go (still log out/reboot afterward):

```bash
sudo ./install.sh --system
./install.sh --user
```

## What this installs

| Layer | Changes |
|-------|---------|
| Packages | GameMode, MangoHud, gamescope, CoreCtrl, vulkan-tools, vkBasalt, lm_sensors |
| GameMode | Performance governor, AMD GPU high perf, core pinning |
| AMDGPU | Boot service + `amdgpu.ppfeaturemask` for full feature unlock |
| Sysctl | Gaming-friendly memory / Proton map count tweaks |
| Global env | **Only** `MESA_SHADER_CACHE_MAX_SIZE=512MB` |
| Heroic | GameMode, esync/fsync/msync, safe env only |
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

## Rollback

```bash
./uninstall.sh --user
sudo ./uninstall.sh --system
sudo reboot
```

## Audit (optional)

Check that forbidden global env vars are not present:

```bash
./scripts/audit.sh
```

## License

MIT — see [LICENSE](LICENSE).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
