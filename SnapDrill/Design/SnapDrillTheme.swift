import SwiftUI
import UIKit

/// User-selectable interface appearance mode.
enum AppAppearanceMode: String, CaseIterable, Identifiable, Sendable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .system: return String(localized: "Follow System")
        case .light: return String(localized: "Paper Light")
        case .dark: return String(localized: "Warm Dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// PRD §7.2 — "Paper & Pen" visual design tokens.
enum SnapDrillTheme {
    // MARK: - Paper & Surface Palette
    static let paperBackground = Color.adaptive(lightHex: 0xFAF7F0, darkHex: 0x222225)
    static let cardSurface = Color.adaptive(lightHex: 0xFFFFFF, darkHex: 0x2B2B2F)
    static let elevatedSurface = Color.adaptive(lightHex: 0xF3EFE4, darkHex: 0x343439)
    static let ruledLine = Color.adaptive(lightHex: 0xE7E1D3, darkHex: 0x3D3D43)

    // MARK: - Ink & Semantic Accents
    static let inkBlack = Color.adaptive(lightHex: 0x1F1F22, darkHex: 0xF4F1EA)
    static let inkSecondary = Color.adaptive(lightHex: 0x6B6860, darkHex: 0xA8A49B)
    static let inkBlue = Color.adaptive(lightHex: 0x2C5689, darkHex: 0x5A90CE)
    static let inkBlueSoft = inkBlue.opacity(0.13)
    static let gradingRed = Color.adaptive(lightHex: 0xD54B46, darkHex: 0xEE6D68)
    static let gradingRedSoft = gradingRed.opacity(0.13)
    static let pencilYellow = Color.adaptive(lightHex: 0xEEBE37, darkHex: 0xF5CB54)
    static let pencilYellowSoft = pencilYellow.opacity(0.18)
    static let masteryGreen = Color.adaptive(lightHex: 0x3D7A5A, darkHex: 0x62AC85)
    static let masteryGreenSoft = masteryGreen.opacity(0.14)

    // MARK: - Subject Preset Swatches
    static let subjectPaletteHexes: [String] = [
        "2C5689", // Ink Blue
        "D54B46", // Grading Red
        "3D7A5A", // Sage Chalk
        "C67A28", // Ochre Pencil
        "6D5696", // Plum Ink
        "2B7A78", // Teal Ink
        "8A5A44", // Kraft Brown
        "4E5D6C"  // Slate Ink
    ]

    // MARK: - Geometry
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 12
    static let screenPadding: CGFloat = 16
}

extension Color {
    /// Creates an adaptive color from 24-bit RGB hex values for light and dark mode.
    static func adaptive(lightHex: UInt32, darkHex: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? darkHex : lightHex
            return UIColor(hex: hex)
        })
    }

    /// Parses a 6-character RGB hex string with fallback to ink blue.
    init(hexString: String) {
        let cleaned = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if cleaned.count == 6, let value = UInt32(cleaned, radix: 16) {
            let r = Double((value >> 16) & 0xFF) / 255.0
            let g = Double((value >> 8) & 0xFF) / 255.0
            let b = Double(value & 0xFF) / 255.0
            self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
        } else {
            self = SnapDrillTheme.inkBlue
        }
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

/// Paper-textured container card with subtle hairline stroke.
struct PaperCard<Content: View>: View {
    var padding: CGFloat = 14
    var background: Color = SnapDrillTheme.cardSurface
    private let content: Content

    init(
        padding: CGFloat = 14,
        background: Color = SnapDrillTheme.cardSurface,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.background = background
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: SnapDrillTheme.cornerRadius, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SnapDrillTheme.cornerRadius, style: .continuous)
                    .strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

/// Subtle horizontal notebook rule divider.
struct RuledDivider: View {
    var body: some View {
        Rectangle()
            .fill(SnapDrillTheme.ruledLine)
            .frame(height: 1)
    }
}

/// Applies the adaptive PaperBackground color across a screen.
struct PaperBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(SnapDrillTheme.paperBackground.ignoresSafeArea())
    }
}

extension View {
    func paperBackground() -> some View {
        modifier(PaperBackgroundModifier())
    }
}

/// Paper-toned inset text field replacing the legacy rounded-border style (Apple HIG grouped input look).
struct PaperInputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(SnapDrillTheme.elevatedSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1)
            )
    }
}

extension View {
    func paperInputField() -> some View {
        modifier(PaperInputFieldModifier())
    }
}

/// Pinned bottom action container for `.safeAreaInset(edge: .bottom)` primary actions that must never scroll away.
struct BottomActionBarContainer<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, SnapDrillTheme.screenPadding)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    SnapDrillTheme.paperBackground.opacity(0.88)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .overlay(alignment: .top) { RuledDivider() }
    }
}
