#!/bin/bash
# Install or update DeviceBar from the latest GitHub release, in one line:
#   curl -fsSL https://raw.githubusercontent.com/kiluss2/DeviceBar/main/scripts/install-release.sh | bash
# Downloads DeviceBar.dmg, copies DeviceBar.app to ~/Applications (or replaces the copy already in
# /Applications) and opens it. A file downloaded by curl carries no quarantine flag, so macOS opens
# the app without the "cannot verify the developer" prompt.
# DEVICEBAR_DMG_URL overrides the download (for testing a local build: file:///path/DeviceBar.dmg).
# If the repository is private, curl fails and the script falls back to `gh release download`.
set -euo pipefail

REPO="kiluss2/DeviceBar"
URL="${DEVICEBAR_DMG_URL:-https://github.com/$REPO/releases/latest/download/DeviceBar.dmg}"
if [ -d /Applications/DeviceBar.app ]; then APP=/Applications/DeviceBar.app; else APP="$HOME/Applications/DeviceBar.app"; fi

WORK="$(mktemp -d)"
cleanup() {
  hdiutil detach -quiet "$WORK/mnt" 2>/dev/null || true
  rm -rf "$WORK"
}
trap cleanup EXIT

echo "Downloading DeviceBar…"
if ! curl -fL --progress-bar "$URL" -o "$WORK/DeviceBar.dmg"; then
  if [ -z "${DEVICEBAR_DMG_URL:-}" ] && command -v gh >/dev/null; then
    echo "curl failed (private repository?), trying gh…"
    gh release download --repo "$REPO" --pattern DeviceBar.dmg --dir "$WORK" --clobber
  else
    exit 1
  fi
fi
mkdir "$WORK/mnt"
hdiutil attach -quiet -nobrowse -readonly -mountpoint "$WORK/mnt" "$WORK/DeviceBar.dmg"
[ -d "$WORK/mnt/DeviceBar.app" ] || { echo "DeviceBar.app is missing from the download" >&2; exit 1; }

# Quit a running copy before replacing it.
osascript -e 'quit app "DeviceBar"' >/dev/null 2>&1 || true
for _ in $(seq 50); do pgrep -x DeviceBar >/dev/null || break; sleep 0.1; done
pkill -x DeviceBar 2>/dev/null || true

mkdir -p "$(dirname "$APP")"
rm -rf "$APP"
ditto "$WORK/mnt/DeviceBar.app" "$APP"
open "$APP"
VERSION="$(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "?")"
echo "DeviceBar $VERSION installed at $APP."
echo "Needs Xcode (xcrun devicectl) and an iPhone paired with this Mac, Developer Mode on."
