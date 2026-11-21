import Foundation
import SwiftData

/// Seeds locale-appropriate default subjects and maintains the hidden fallback "Uncategorized" bucket (PRD §3.1, §8.6).
@MainActor
enum SubjectCatalog {
    struct PresetSpec: Sendable {
        let name: String
        let colorHex: String
    }

    static func defaultSubjects(for locale: Locale = .current) -> [PresetSpec] {
        let language = locale.language.languageCode?.identifier ?? "en"
        let script = locale.language.script?.identifier ?? ""
        let region = locale.region?.identifier.uppercased() ?? ""

        if language == "ja" {
            return [
                PresetSpec(name: "数学", colorHex: "2C5689"),
                PresetSpec(name: "英語", colorHex: "D54B46"),
                PresetSpec(name: "国語", colorHex: "3D7A5A"),
                PresetSpec(name: "理科", colorHex: "C67A28"),
                PresetSpec(name: "社会", colorHex: "6D5696")
            ]
        }

        if language == "ko" {
            return [
                PresetSpec(name: "수학", colorHex: "2C5689"),
                PresetSpec(name: "영어", colorHex: "D54B46"),
                PresetSpec(name: "국어", colorHex: "3D7A5A"),
                PresetSpec(name: "과학", colorHex: "C67A28"),
                PresetSpec(name: "사회", colorHex: "6D5696")
            ]
        }

        if language == "zh" && (script == "Hant" || region == "TW" || region == "HK" || region == "MO") {
            return [
                PresetSpec(name: "數學", colorHex: "2C5689"),
                PresetSpec(name: "英文", colorHex: "D54B46"),
                PresetSpec(name: "國文", colorHex: "3D7A5A"),
                PresetSpec(name: "物理", colorHex: "C67A28"),
                PresetSpec(name: "化學", colorHex: "6D5696")
            ]
        }

        if language == "zh" {
            return [
                PresetSpec(name: "数学", colorHex: "2C5689"),
                PresetSpec(name: "英语", colorHex: "D54B46"),
                PresetSpec(name: "语文", colorHex: "3D7A5A"),
                PresetSpec(name: "物理", colorHex: "C67A28"),
                PresetSpec(name: "化学", colorHex: "6D5696")
            ]
        }

        return [
            PresetSpec(name: "Math", colorHex: "2C5689"),
            PresetSpec(name: "English", colorHex: "D54B46"),
            PresetSpec(name: "Physics", colorHex: "C67A28"),
            PresetSpec(name: "Chemistry", colorHex: "6D5696"),
            PresetSpec(name: "Biology", colorHex: "3D7A5A")
        ]
    }

    static func uncategorizedTitle(for locale: Locale = .current) -> String {
        let language = locale.language.languageCode?.identifier ?? "en"
        let script = locale.language.script?.identifier ?? ""
        let region = locale.region?.identifier.uppercased() ?? ""

        if language == "ja" { return "未分類" }
        if language == "ko" { return "미분류" }
        if language == "zh" && (script == "Hant" || region == "TW" || region == "HK" || region == "MO") {
            return "未分類"
        }
        if language == "zh" { return "未分类" }
        return "Uncategorized"
    }

    /// Idempotently seeds built-in subjects and the hidden fallback bucket on first launch (AC-01).
    @discardableResult
    static func ensureSeeded(in context: ModelContext, locale: Locale = .current) -> [Subject] {
        let descriptor = FetchDescriptor<Subject>(sortBy: [SortDescriptor(\Subject.sortOrder)])
        let existing = (try? context.fetch(descriptor)) ?? []

        let hasRegularSubjects = existing.contains { !$0.isUncategorizedBucket }
        if !hasRegularSubjects {
            let specs = defaultSubjects(for: locale)
            for (index, spec) in specs.enumerated() {
                let subject = Subject(
                    name: spec.name,
                    colorHex: spec.colorHex,
                    sortOrder: index,
                    isBuiltin: true,
                    isUncategorizedBucket: false
                )
                context.insert(subject)
            }
        }

        if !existing.contains(where: { $0.isUncategorizedBucket }) {
            let fallback = Subject(
                name: uncategorizedTitle(for: locale),
                colorHex: "4E5D6C",
                sortOrder: 9_999,
                isBuiltin: true,
                isUncategorizedBucket: true
            )
            context.insert(fallback)
        }

        try? context.save()
        return (try? context.fetch(descriptor)) ?? []
    }

    static func fetchOrCreateUncategorized(in context: ModelContext, locale: Locale = .current) -> Subject {
        let descriptor = FetchDescriptor<Subject>()
        let all = (try? context.fetch(descriptor)) ?? []
        if let existing = all.first(where: { $0.isUncategorizedBucket }) {
            return existing
        }
        let created = Subject(
            name: uncategorizedTitle(for: locale),
            colorHex: "4E5D6C",
            sortOrder: 9_999,
            isBuiltin: true,
            isUncategorizedBucket: true
        )
        context.insert(created)
        return created
    }
}
