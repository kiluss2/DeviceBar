# DeviceBar

A macOS menu bar app for driving a connected iPhone through `xcrun devicectl`:

- Pick the current iPhone and copy its name, iOS version and UDID
- Take a screenshot (copy to clipboard and/or save to Downloads), shortcut ⌘S
- Open the URL on the Mac clipboard in Safari or Shortcuts on the iPhone
- Send the Mac clipboard (text or image) to the iPhone, or pull the iPhone clipboard back
- Simulate a GPS location on the iPhone, or clear it

The app lives in the menu bar only (no Dock icon). "Open DeviceBar Window…" opens a window with
the same actions, editable coordinates and a log.

## Requirements

- macOS 15 or later
- Xcode 16 or later installed (DeviceBar calls `xcrun devicectl`, which ships with Xcode).
  Command Line Tools alone are not enough.
- An iPhone paired with this Mac, with Developer Mode on (Settings › Privacy & Security ›
  Developer Mode). Some actions, such as location and clipboard, need the iPhone unlocked.

## Install

### Quick install (one line)

```bash
curl -fsSL https://raw.githubusercontent.com/kiluss2/DeviceBar/main/scripts/install-release.sh | bash
```

Downloads the latest release (`DeviceBar.dmg`), installs `~/Applications/DeviceBar.app` and opens
it. Run the same line again to update. A file downloaded with `curl` is not marked as downloaded
from the internet, so macOS opens the app without the "Apple could not verify…" prompt.

Remove:

```bash
curl -fsSL https://raw.githubusercontent.com/kiluss2/DeviceBar/main/scripts/uninstall.sh | bash
```

### Install from a .dmg

1. Download `DeviceBar.dmg` (or build one yourself, see below) and open it.
2. Drag **DeviceBar** onto **Applications**.
3. Open DeviceBar from Applications. An iPhone icon appears in the menu bar.

The app is signed ad hoc, not with an Apple Developer ID, so on a Mac other than the one that
built it macOS blocks the first launch ("Apple could not verify…"). To allow it, either:

- open **System Settings › Privacy & Security**, scroll down and click **Open Anyway**, or
- run this once in Terminal:

  ```bash
  xattr -dr com.apple.quarantine /Applications/DeviceBar.app
  ```

## Build from source

Clone the repo, then choose one:

```bash
./build.sh
```

Builds a release version and installs it to `~/Applications/DeviceBar.app`. Open it from there.

```bash
./make-dmg.sh
```

Builds `build/DeviceBar.dmg`, a drag-to-Applications installer you can share with others. To
publish it, attach it to a release; the quick install always takes the latest release's
`DeviceBar.dmg`:

```bash
gh release create v0.3 build/DeviceBar.dmg --title "DeviceBar 0.3" --notes "..."
```

Both scripts need Xcode (Swift 6 toolchain). For development you can also run `swift run`.

## Start at login

System Settings › General › Login Items › click **+** under "Open at Login" and choose
DeviceBar.

## Uninstall

Run the remove line above, or quit DeviceBar from its menu and delete `DeviceBar.app` from
Applications (or `~/Applications`).
