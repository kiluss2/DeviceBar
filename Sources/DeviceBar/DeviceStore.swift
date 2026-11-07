import AppKit
import Observation

@MainActor
@Observable
final class DeviceStore {
    private enum Key {
        static let selectedID = "selectedDeviceID"
        static let copyScreenshot = "copyScreenshot"
        static let saveScreenshot = "saveScreenshot"
        static let latitude = "latitude"
        static let longitude = "longitude"
    }

    private let defaults = UserDefaults.standard

    var devices: [Device] = []
    var busyAction: String?
    var log: [LogEntry] = []

    var selectedID: String? {
        didSet { defaults.set(selectedID, forKey: Key.selectedID) }
    }

    var copyScreenshot: Bool {
        didSet { defaults.set(copyScreenshot, forKey: Key.copyScreenshot) }
    }

    var saveScreenshot: Bool {
        didSet { defaults.set(saveScreenshot, forKey: Key.saveScreenshot) }
    }

    var latitude: Double {
        didSet { defaults.set(latitude, forKey: Key.latitude) }
    }

    var longitude: Double {
        didSet { defaults.set(longitude, forKey: Key.longitude) }
    }

    var selectedDevice: Device? {
        devices.first { $0.id == selectedID }
    }

    var lastMessage: String {
        log.first?.text ?? "Ready"
    }

    init() {
        defaults.register(defaults: [
            Key.copyScreenshot: true,
            Key.saveScreenshot: true,
            Key.latitude: 16.0608744,
            Key.longitude: 108.2227773
        ])
        selectedID = defaults.string(forKey: Key.selectedID)
        copyScreenshot = defaults.bool(forKey: Key.copyScreenshot)
        saveScreenshot = defaults.bool(forKey: Key.saveScreenshot)
        latitude = defaults.double(forKey: Key.latitude)
        longitude = defaults.double(forKey: Key.longitude)
    }

    func startAutoRefresh() async {
        while !Task.isCancelled {
            await refreshDevices(quiet: true)
            try? await Task.sleep(for: .seconds(30))
        }
    }

    func refreshDevices(quiet: Bool = false) async {
        do {
            devices = try await DeviceCtl.listDevices()
            if selectedDevice == nil {
                selectedID = devices.first { $0.status == .connected }?.id ?? devices.first?.id
            }
            if !quiet { record("Refreshed: \(devices.count) devices") }
        } catch {
            record("Device list failed: \(error.localizedDescription)", isError: true)
        }
    }

    func copyDeviceReference() {
        guard let device = selectedDevice else {
            record("No iPhone selected", isError: true)
            return
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(device.agentReference, forType: .string)
        record("Copied: \(device.agentReference)")
    }

    func takeScreenshot() {
        perform("Screenshot") { device in
            guard self.copyScreenshot || self.saveScreenshot else {
                return "Neither Copy nor Save is ticked"
            }
            let temp = FileManager.default.temporaryDirectory.appending(path: "DeviceBar-shot-\(UUID().uuidString).png")
            defer { try? FileManager.default.removeItem(at: temp) }
            try await DeviceCtl.check(["device", "capture", "screenshot", "--device", device.id, "--destination", temp.path])
            let data = try Data(contentsOf: temp)

            var done: [String] = []
            if self.copyScreenshot {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setData(data, forType: .png)
                done.append("copied")
            }
            if self.saveScreenshot {
                let stamp = Date.now.formatted(.verbatim("\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased))\(minute: .twoDigits)\(second: .twoDigits)", timeZone: .current, calendar: .current))
                let file = URL.downloadsDirectory.appending(path: "\(device.name) \(stamp).png")
                try data.write(to: file)
                done.append("saved \(file.lastPathComponent)")
            }
            return "Screenshot of \(device.name): \(done.joined(separator: ", "))"
        }
    }

    func openClipboardLink(bundleID: String, appName: String) {
        perform("Open link in \(appName)") { device in
            let text = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard let url = URL(string: text), url.scheme != nil else {
                throw CommandError(message: "The Mac clipboard holds no link")
            }
            try await DeviceCtl.check(["device", "process", "launch", "--device", device.id, "--payload-url", url.absoluteString, bundleID])
            return "Opened in \(appName) on \(device.name): \(url.absoluteString)"
        }
    }

    func pushClipboardToDevice() {
        perform("Mac clipboard → iPhone") { device in
            let pasteboard = NSPasteboard.general
            if let text = pasteboard.string(forType: .string) {
                try await DeviceCtl.check(
                    ["device", "pasteboard", "copy", "--device", device.id, "--type", "public.utf8-plain-text"],
                    stdin: Data(text.utf8)
                )
                return "Sent text (\(text.count) chars) to \(device.name)"
            }
            if let png = Self.pngData(from: pasteboard) {
                try await DeviceCtl.check(["device", "pasteboard", "copy", "--device", device.id, "--type", "public.png"], stdin: png)
                return "Sent image to \(device.name)"
            }
            throw CommandError(message: "The Mac clipboard is empty or not text/image")
        }
    }

    func pullClipboardFromDevice() {
        perform("iPhone clipboard → Mac") { device in
            let info = try await DeviceCtl.check(["device", "pasteboard", "info", "--device", device.id])
            let types = String(decoding: info.stdout, as: UTF8.self) + info.stderr
            let pasteboard = NSPasteboard.general

            for imageType in ["public.png", "public.jpeg", "public.heic"] where types.contains(imageType) {
                let output = try await DeviceCtl.check(["device", "pasteboard", "paste", "--device", device.id, "--type", imageType])
                guard let image = NSImage(data: output.stdout) else { continue }
                pasteboard.clearContents()
                pasteboard.writeObjects([image])
                return "Copied image from \(device.name) to the Mac clipboard"
            }

            let output = try await DeviceCtl.check(["device", "pasteboard", "paste", "--device", device.id])
            let text = String(decoding: output.stdout, as: UTF8.self)
            guard !text.isEmpty else { throw CommandError(message: "The clipboard on \(device.name) is empty") }
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            return "Copied text (\(text.count) chars) from \(device.name)"
        }
    }

    func simulateLocation() {
        let latitude = latitude
        let longitude = longitude
        perform("Simulate location") { device in
            try await DeviceCtl.check([
                "device", "simulate", "location", "coordinate", "--device", device.id,
                "--latitude", String(latitude), "--longitude", String(longitude)
            ])
            return "\(device.name) is now at \(latitude), \(longitude)"
        }
    }

    func clearLocation() {
        perform("Clear simulated location") { device in
            try await DeviceCtl.check(["device", "simulate", "location", "clear", "--device", device.id])
            return "\(device.name) is back to its real location"
        }
    }

    private func perform(_ name: String, _ work: @escaping @MainActor (Device) async throws -> String) {
        guard busyAction == nil else {
            record("Busy: \(busyAction ?? "")", isError: true)
            return
        }
        guard let device = selectedDevice else {
            record("No iPhone selected", isError: true)
            return
        }
        busyAction = name
        Task {
            defer { busyAction = nil }
            do {
                record(try await work(device))
            } catch {
                record("\(name) failed: \(error.localizedDescription)", isError: true)
                NSSound.beep()
            }
        }
    }

    private func record(_ text: String, isError: Bool = false) {
        log.insert(LogEntry(text: text, isError: isError), at: 0)
        if log.count > 50 { log.removeLast(log.count - 50) }
    }

    private static func pngData(from pasteboard: NSPasteboard) -> Data? {
        if let png = pasteboard.data(forType: .png) { return png }
        guard let tiff = pasteboard.data(forType: .tiff), let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
