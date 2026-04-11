import SwiftUI

// MARK: - Design Tokens

enum TB {
    // Colors
    static let accent = Color.blue
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.25, green: 0.48, blue: 1.0), Color(red: 0.35, green: 0.55, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Corner radii
    static let cornerLG: CGFloat = 14
    static let cornerMD: CGFloat = 10
    static let cornerSM: CGFloat = 8
    static let cornerXS: CGFloat = 6

    // Spacing
    static let spacingXL: CGFloat = 24
    static let spacingLG: CGFloat = 20
    static let spacingMD: CGFloat = 16
    static let spacingSM: CGFloat = 12
    static let spacingXS: CGFloat = 8
}

// MARK: - Card Style

struct CardStyle: ViewModifier {
    var padding: CGFloat = TB.spacingSM

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.background.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: TB.cornerMD, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}

extension View {
    func cardStyle(padding: CGFloat = TB.spacingSM) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

// MARK: - Keyboard Shortcut Badge

struct KeyBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.quaternary.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: TB.cornerXS, style: .continuous))
    }
}
