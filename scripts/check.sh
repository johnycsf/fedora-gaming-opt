#!/usr/bin/env bash
# Non-destructive readiness check for this toolkit.
set -euo pipefail

failed=0
check() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "OK: $1"
  else
    echo "MISSING: $1"
    failed=1
  fi
}

echo "== Fedora gaming readiness =="
for cmd in gamemoded gamemoderun mangohud vulkaninfo; do check "${cmd}"; done
systemctl --user is-active --quiet gamemoded.service && echo "OK: gamemoded service active" || echo "INFO: gamemoded will start when a game requests it"

if grep -qw 'amdgpu.ppfeaturemask=0xfff7ffff' /proc/cmdline 2>/dev/null; then
  echo "INFO: advanced AMD ppfeaturemask is enabled"
else
  echo "OK: advanced AMD ppfeaturemask is not enabled"
fi

exit "${failed}"
