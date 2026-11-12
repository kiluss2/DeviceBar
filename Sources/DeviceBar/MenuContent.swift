import SwiftUI

/// The menu bar panel. Settings rows (iPhone picker, Refresh, the screenshot ticks) keep it open;
/// one-shot commands close it once clicked so they cannot be fired twice by accident.
/// Esc or a click outside also closes it.
struct MenuContent: View {
    @Bindable var store: DeviceStore

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(store.busyAction.map { "Running: \($0)…" } ?? store.lastMessage)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .textSelection(.enabled)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

            Divider().padding(.vertical, 4)

            Picker("iPhone", selection: $store.selectedID) {
                ForEach(store.devices) { device in
                    Text(device.menuTitle).tag(Optional(device.id))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)

            commandRow("Copy iPhone Name, iOS and UDID", action: store.copyDeviceReference)
            row("Refresh Devices") {
                Task { await store.refreshDevices() }
            }

            Divider().padding(.vertical, 4)

            commandRow("Take Screenshot", shortcut: "⌘S", action: store.takeScreenshot)
                .keyboardShortcut("s")
            Toggle("Copy Screenshot to Clipboard", isOn: $store.copyScreenshot)
                .toggleStyle(.menuCheck)
            Toggle("Save Screenshot to Downloads", isOn: $store.saveScreenshot)
                .toggleStyle(.menuCheck)

            Divider().padding(.vertical, 4)

            commandRow("Open Clipboard Link in Safari") {
                store.openClipboardLink(bundleID: "com.apple.mobilesafari", appName: "Safari")
            }
            commandRow("Open Clipboard Link in Shortcuts") {
                store.openClipboardLink(bundleID: "com.apple.shortcuts", appName: "Shortcuts")
            }

            Divider().padding(.vertical, 4)

            commandRow("Send Mac Clipboard to iPhone", action: store.pushClipboardToDevice)
            commandRow("Get iPhone Clipboard", action: store.pullClipboardFromDevice)

            Divider().padding(.vertical, 4)

            commandRow("Simulate Location (\(store.latitude), \(store.longitude))", action: store.simulateLocation)
            commandRow("Clear Simulated Location", action: store.clearLocation)

            Divider().padding(.vertical, 4)

            commandRow("Open DeviceBar Window…") {
                openWindow(id: MainWindow.id)
                NSApp.activate()
            }
            Button {
                NSApp.terminate(nil)
            } label: {
                MenuRowLabel(title: "Quit DeviceBar", shortcut: "⌘Q")
            }
            .buttonStyle(.menuRow)
            .keyboardShortcut("q")

            // Esc closes the panel, as it does a menu.
            Button("Close", action: closePanel)
                .keyboardShortcut(.cancelAction)
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        }
        .padding(6)
        .frame(width: 380)
    }

    /// A row that keeps the panel open, for settings you may click several times in a row.
    private func row(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MenuRowLabel(title: title)
        }
        .buttonStyle(.menuRow)
    }

    /// A one-shot command: closes the panel first, then runs, so a second click cannot repeat it.
    private func commandRow(_ title: String, shortcut: String? = nil, action: @escaping () -> Void) -> some View {
        Button {
            closePanel()
            action()
        } label: {
            MenuRowLabel(title: title, shortcut: shortcut)
        }
        .buttonStyle(.menuRow)
    }

    /// The panel is the key window while it is open; closing it is how a menu bar panel dismisses.
    private func closePanel() {
        NSApp.keyWindow?.close()
    }
}
