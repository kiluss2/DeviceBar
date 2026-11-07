import SwiftUI

struct MenuContent: View {
    @Bindable var store: DeviceStore

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(store.busyAction.map { "Running: \($0)…" } ?? store.lastMessage)

        Divider()

        Picker("iPhone: \(store.selectedDevice?.name ?? "none")", selection: $store.selectedID) {
            ForEach(store.devices) { device in
                Text(device.menuTitle).tag(Optional(device.id))
            }
        }
        Button("Copy iPhone Name, iOS and UDID", action: store.copyDeviceReference)
        Button("Refresh Devices") {
            Task { await store.refreshDevices() }
        }

        Divider()

        Button("Take Screenshot", action: store.takeScreenshot)
            .keyboardShortcut("s")
        Toggle("Copy Screenshot to Clipboard", isOn: $store.copyScreenshot)
        Toggle("Save Screenshot to Downloads", isOn: $store.saveScreenshot)

        Divider()

        Button("Open Clipboard Link in Safari") {
            store.openClipboardLink(bundleID: "com.apple.mobilesafari", appName: "Safari")
        }
        Button("Open Clipboard Link in Shortcuts") {
            store.openClipboardLink(bundleID: "com.apple.shortcuts", appName: "Shortcuts")
        }

        Divider()

        Button("Send Mac Clipboard to iPhone", action: store.pushClipboardToDevice)
        Button("Get iPhone Clipboard", action: store.pullClipboardFromDevice)

        Divider()

        Button("Simulate Location (\(store.latitude), \(store.longitude))", action: store.simulateLocation)
        Button("Clear Simulated Location", action: store.clearLocation)

        Divider()

        Button("Open DeviceBar Window…") {
            openWindow(id: MainWindow.id)
            NSApp.activate()
        }
        Button("Quit DeviceBar") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
