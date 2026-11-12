import SwiftUI

/// A toggle drawn as a menu row with a checkmark; clicking it flips the value and keeps the panel open.
struct MenuCheckToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .opacity(configuration.isOn ? 1 : 0)
                    .accessibilityHidden(true)
                configuration.label
                Spacer(minLength: 12)
            }
        }
        .buttonStyle(.menuRow)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
    }
}

extension ToggleStyle where Self == MenuCheckToggleStyle {
    static var menuCheck: MenuCheckToggleStyle { MenuCheckToggleStyle() }
}
