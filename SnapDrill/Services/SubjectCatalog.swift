import Foundation

/// PRD §3.1 — 按语言/地区预置科目（AC-01）
enum SubjectCatalog {
    static func defaultSubjects(for locale: Locale = .current) -> [(name: String, colorHex: String)] {
        let language = locale.language.languageCode?.identifier ?? "en"
        let region = locale.region?.identifier ?? ""

        switch (language, region) {
        case ("ja", _):
            return japaneseDefaults
        case ("ko", _):
            return koreanDefaults
        case ("zh", "TW"), ("zh", "HK"), ("zh", "MO"):
            return traditionalChineseDefaults
        case ("zh", _):
            return simplifiedChineseDefaults
        default:
            return englishDefaults
        }
    }

    private static let englishDefaults: [(String, String)] = [
        ("Math", "3B82F6"),
        ("English", "8B5CF6"),
        ("Science", "10B981"),
        ("History", "F59E0B"),
        ("Other", "6B7280"),
    ]

    private static let simplifiedChineseDefaults: [(String, String)] = [
        ("语文", "EF4444"),
        ("数学", "3B82F6"),
        ("英语", "8B5CF6"),
        ("物理", "10B981"),
        ("化学", "14B8A6"),
        ("其他", "6B7280"),
    ]

    private static let traditionalChineseDefaults: [(String, String)] = [
        ("國文", "EF4444"),
        ("數學", "3B82F6"),
        ("英文", "8B5CF6"),
        ("自然", "10B981"),
        ("社會", "F59E0B"),
        ("其他", "6B7280"),
    ]

    private static let japaneseDefaults: [(String, String)] = [
        ("国語", "EF4444"),
        ("数学", "3B82F6"),
        ("英語", "8B5CF6"),
        ("理科", "10B981"),
        ("社会", "F59E0B"),
    ]

    private static let koreanDefaults: [(String, String)] = [
        ("국어", "EF4444"),
        ("수학", "3B82F6"),
        ("영어", "8B5CF6"),
        ("과학", "10B981"),
        ("사회", "F59E0B"),
    ]

    static let uncategorizedName = String(localized: "Uncategorized")
}