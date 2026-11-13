#!/bin/bash
# Remove DeviceBar (from ~/Applications and /Applications) and quit it first.
# Settings stay in UserDefaults; clear them with: defaults delete local.sonmacmini.DeviceBar
set -euo pipefail

pkill -x DeviceBar 2>/dev/null || true
for _ in $(seq 50); do pgrep -x DeviceBar >/dev/null || break; sleep 0.1; done
for APP in "$HOME/Applications/DeviceBar.app" /Applications/DeviceBar.app; do
  [ -e "$APP" ] || continue
  if command -v trash >/dev/null; then trash "$APP"; else rm -rf "$APP"; fi
done
echo "removed DeviceBar"
