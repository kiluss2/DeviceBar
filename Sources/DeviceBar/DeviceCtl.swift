import Foundation

/// Thin async wrapper over `xcrun devicectl`; every call runs one child process.
enum DeviceCtl {
    struct Output: Sendable {
        let status: Int32
        let stdout: Data
        let stderr: String
    }

    static func run(_ arguments: [String], stdin: Data? = nil) async throws -> Output {
        let workDir = FileManager.default.temporaryDirectory.appending(path: "DeviceBar-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: workDir) }

        let outURL = workDir.appending(path: "out")
        let errURL = workDir.appending(path: "err")
        FileManager.default.createFile(atPath: outURL.path, contents: nil)
        FileManager.default.createFile(atPath: errURL.path, contents: nil)

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/xcrun")
        process.arguments = ["devicectl"] + arguments
        process.standardOutput = try FileHandle(forWritingTo: outURL)
        process.standardError = try FileHandle(forWritingTo: errURL)
        if let stdin {
            let inURL = workDir.appending(path: "in")
            try stdin.write(to: inURL)
            process.standardInput = try FileHandle(forReadingFrom: inURL)
        }

        let status: Int32 = try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
            do {
                try process.run()
            } catch {
                process.terminationHandler = nil
                continuation.resume(throwing: error)
            }
        }

        let stdout = (try? Data(contentsOf: outURL)) ?? Data()
        let stderr = (try? String(contentsOf: errURL, encoding: .utf8)) ?? ""
        return Output(status: status, stdout: stdout, stderr: stderr)
    }

    /// Runs a command and throws its last error line when it exits non-zero.
    @discardableResult
    static func check(_ arguments: [String], stdin: Data? = nil) async throws -> Output {
        let output = try await run(arguments, stdin: stdin)
        guard output.status == 0 else {
            let text = output.stderr.isEmpty ? String(decoding: output.stdout, as: UTF8.self) : output.stderr
            let line = text
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .last { !$0.isEmpty } ?? "devicectl exit \(output.status)"
            throw CommandError(message: line)
        }
        return output
    }

    static func listDevices() async throws -> [Device] {
        let output = try await check(["list", "devices", "--quiet", "--json-output", "-"])
        guard
            let root = try JSONSerialization.jsonObject(with: output.stdout) as? [String: Any],
            let result = root["result"] as? [String: Any],
            let entries = result["devices"] as? [[String: Any]]
        else {
            throw CommandError(message: "Could not read the device list")
        }

        return entries.compactMap { entry -> Device? in
            let hardware = entry["hardwareProperties"] as? [String: Any] ?? [:]
            let properties = entry["deviceProperties"] as? [String: Any] ?? [:]
            let connection = entry["connectionProperties"] as? [String: Any] ?? [:]
            guard hardware["reality"] as? String != "simulated" else { return nil }

            let id = hardware["udid"] as? String ?? entry["identifier"] as? String ?? ""
            guard !id.isEmpty else { return nil }

            let status: Device.Status = switch connection["tunnelState"] as? String {
            case "connected": .connected
            case "unavailable": .unavailable
            default: properties["bootState"] as? String == "booted" ? .available : .unavailable
            }

            return Device(
                id: id,
                name: properties["name"] as? String ?? id,
                osVersion: properties["osVersionNumber"] as? String ?? "?",
                model: hardware["marketingName"] as? String ?? "",
                status: status
            )
        }
        .sorted { ($0.status, $0.name) < ($1.status, $1.name) }
    }
}
