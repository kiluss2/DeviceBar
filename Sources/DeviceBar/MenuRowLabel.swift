import SwiftUI

/// Title with an empty checkmark column on the left (lines up with the toggles) and an optional shortcut hint on the right.
struct MenuRowLabel: View {
    let title: String
    var shortcut: String?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.caption.bold())
                .hidden()
            Text(title)
            Spacer(minLength: 12)
            if let shortcut {
                Text(shortcut)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }
}
