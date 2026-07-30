# Hard-won lessons

These rules are encoded in the install scripts. Do not “optimize harder” past them without understanding the failure modes.

## 1. Never wrap the Steam client in GameMode

**Bad:**

```bash
gamemoderun steam
# or a .desktop Exec=gamemoderun /usr/bin/steam
```

**Why it fails:** GameMode / `LD_PRELOAD` leaks into `steamwebhelper` inside Steam’s pressure-vessel runtime. That often produces:

- Steam error **0x3008**
- `libgamemode.so: cannot open shared object file`
- `D-Bus connection was disconnected. Aborting`

**Good:** Launch Steam normally. Put `gamemoderun` only in **per-game** launch options:

```
gamemoderun %command%
```

## 2. Never export `ENABLE_GAMESCOPE_WSI=1` globally

**Bad:** Putting this in `/etc/profile.d`, `~/.bashrc`, or Flatpak overrides for everything.

**Why it fails:** The Gamescope WSI Vulkan layer hooks non-Gamescope apps and shows:

```
CreateSwapchainKHR: Creating swapchain for non-Gamescope swapchain.
Hooking has failed somewhere!
You may have a bad Vulkan layer interfering.
```

Desktop apps, browsers, and Electron tools can break.

**Good:** Only use Gamescope when you intentionally launch with `gamescope ... -- %command%`.

## 3. Keep global environment variables minimal

**Bad globals:** `DXVK_ASYNC`, `RADV_PERFTEST`, `AMD_VULKAN_ICD`, `VKD3D_CONFIG`, `mesa_glthread`, Proton flags in `/etc/profile.d`.

**Why it fails:** Those affect every Vulkan/OpenGL process on the desktop, not just games.

**Good global (this repo):**

```bash
export MESA_SHADER_CACHE_MAX_SIZE=512MB
```

Put game-specific vars in Steam/Heroic launch options.

## 4. Prefer GameMode during games, not permanent overclock policies alone

GameMode + AMD `high` performance level is enough for most sessions. Permanent max clocks are fine on a desktop gaming box but raise idle power/heat. Adjust with CoreCtrl if needed.

## 5. Always keep a rollback path

System and user uninstall scripts reverse *this repo’s* config files and services. They do not wipe your games library.
