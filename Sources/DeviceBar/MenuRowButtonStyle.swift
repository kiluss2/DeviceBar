import SwiftUI

/// A full-width row that highlights on hover like a menu item, for the menu bar panel.
struct MenuRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        MenuRow(configuration: configuration)
    }
}

extension ButtonStyle where Self == MenuRowButtonStyle {
    static var menuRow: MenuRowButtonStyle { MenuRowButtonStyle() }
}

private struct MenuRow: View {
    let configuration: ButtonStyleConfiguration

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    private var isHighlighted: Bool {
        isEnabled && (isHovered || configuration.isPressed)
    }

    var body: some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(isHighlighted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .background(isHighlighted ? Color.accentColor : .clear, in: .rect(cornerRadius: 6))
            .contentShape(.rect)
            .onHover { isHovered = $0 }
    }
}
