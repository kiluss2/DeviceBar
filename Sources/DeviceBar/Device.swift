import Foundation

struct Device: Identifiable, Equatable, Sendable {
    enum Status: Int, Comparable, Sendable {
        case connected, available, unavailable

        static func < (lhs: Status, rhs: Status) -> Bool { lhs.rawValue < rhs.rawValue }

        var label: String {
            switch self {
            case .connected: "connected"
            case .available: "available"
            case .unavailable: "unavailable"
            }
        }
    }

    let id: String
    let name: String
    let osVersion: String
    let model: String
    let status: Status

    var menuTitle: String {
        "\(name) · iOS \(osVersion) · \(status.label)"
    }

    var agentReference: String {
        "\(name) · iOS \(osVersion) · UDID \(id)"
    }
}
