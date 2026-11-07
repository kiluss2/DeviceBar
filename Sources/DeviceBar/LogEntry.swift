import Foundation

struct LogEntry: Identifiable, Equatable {
    let id = UUID()
    let date = Date.now
    let text: String
    let isError: Bool
}
