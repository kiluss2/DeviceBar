import Foundation

struct CommandError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
