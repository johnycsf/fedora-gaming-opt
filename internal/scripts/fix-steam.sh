#!/usr/bin/env bash
# Fix Steam 0x3008 caused by gamemoderun wrapping the Steam client.
set -euo pipefail

echo "==> Stopping Steam..."
steam -shutdown 2>/dev/null || true
sleep 2
pkill -9 -f 'steamwebhelper|ubuntu12_32/steam|ubuntu12_64/steam' 2>/dev/null || true

echo "==> Removing gamemoderun Steam launcher overrides..."
rm -f "${HOME}/.local/share/applications/steam.desktop"
rm -f "${HOME}/.local/bin/steam-gaming"
update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true

echo "==> Resetting Steam webhelper cache..."
if [[ -d "${HOME}/.local/share/Steam/config/htmlcache" ]]; then
  backup="${HOME}/.local/share/Steam/config/htmlcache.bak.$(date +%Y%m%d-%H%M%S)"
  mv "${HOME}/.local/share/Steam/config/htmlcache" "${backup}"
  mkdir -p "${HOME}/.local/share/Steam/config/htmlcache"
  echo "    Backed up to ${backup}"
fi

# Clear sticky bad env from this session if present
systemctl --user unset-environment ENABLE_GAMESCOPE_WSI 2>/dev/null || true

echo "==> Done."
echo "Launch Steam from the app menu (NOT with gamemoderun)."
echo "Use gamemoderun only in per-game launch options."
