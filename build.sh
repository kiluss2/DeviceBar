#!/bin/bash
# Builds DeviceBar and installs it as ~/Applications/DeviceBar.app (menu bar only, no Dock icon).
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
APP="$HOME/Applications/DeviceBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/DeviceBar" "$APP/Contents/MacOS/DeviceBar"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>local.sonmacmini.DeviceBar</string>
    <key>CFBundleName</key><string>DeviceBar</string>
    <key>CFBundleExecutable</key><string>DeviceBar</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>15.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST
codesign --force --sign - "$APP"
echo "Installed $APP"
