import SwiftUI

struct MainWindow: View {
    static let id = "main"

    @Bindable var store: DeviceStore

    var body: some View {
        Form {
            Section("iPhone") {
                Picker("Current device", selection: $store.selectedID) {
                    ForEach(store.devices) { device in
                        Text(device.menuTitle).tag(Optional(device.id))
                    }
                }
                HStack {
                    Button("Copy Name, iOS and UDID", systemImage: "doc.on.doc", action: store.copyDeviceReference)
                    Button("Refresh Devices", systemImage: "arrow.clockwise") {
                        Task { await store.refreshDevices() }
                    }
                }
            }

            Section("Screenshot") {
                Toggle("Copy to clipboard", isOn: $store.copyScreenshot)
                Toggle("Save to Downloads", isOn: $store.saveScreenshot)
                Button("Take Screenshot", systemImage: "camera", action: store.takeScreenshot)
            }

            Section("Link and clipboard") {
                HStack {
                    Button("Open link in Safari", systemImage: "safari") {
                        store.openClipboardLink(bundleID: "com.apple.mobilesafari", appName: "Safari")
                    }
                    Button("Open link in Shortcuts", systemImage: "square.stack.3d.up") {
                        store.openClipboardLink(bundleID: "com.apple.shortcuts", appName: "Shortcuts")
                    }
                }
                HStack {
                    Button("Mac → iPhone", systemImage: "arrow.down.doc", action: store.pushClipboardToDevice)
                    Button("iPhone → Mac", systemImage: "arrow.up.doc", action: store.pullClipboardFromDevice)
                }
            }

            Section("Simulated location") {
                TextField("Latitude", value: $store.latitude, format: .number.precision(.fractionLength(0...7)))
                TextField("Longitude", value: $store.longitude, format: .number.precision(.fractionLength(0...7)))
                HStack {
                    Button("Simulate", systemImage: "location", action: store.simulateLocation)
                    Button("Clear", systemImage: "location.slash", action: store.clearLocation)
                }
            }

            Section("Log") {
                if let busy = store.busyAction {
                    Label("Running: \(busy)…", systemImage: "hourglass")
                }
                ForEach(store.log) { entry in
                    HStack(alignment: .firstTextBaseline) {
                        Text(entry.date, format: .dateTime.hour().minute().second())
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        Text(entry.text)
                            .foregroundStyle(entry.isError ? .red : .primary)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 640)
        .disabled(store.busyAction != nil)
    }
}
