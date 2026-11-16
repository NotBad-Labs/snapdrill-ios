import SwiftUI

/// PRD §7.2 — 纸与笔配色
enum SnapDrillTheme {
    static let paperBackground = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let paperBackgroundDark = Color(red: 0.14, green: 0.14, blue: 0.15)
    static let inkBlue = Color(red: 0.18, green: 0.35, blue: 0.55)
    static let inkBlack = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let gradingRed = Color(red: 0.85, green: 0.28, blue: 0.28)
    static let pencilYellow = Color(red: 0.95, green: 0.82, blue: 0.35)

    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? paperBackgroundDark : paperBackground
    }
}

struct PaperBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(SnapDrillTheme.background(for: colorScheme))
    }
}

extension View {
    func paperBackground() -> some View {
        modifier(PaperBackgroundModifier())
    }
}