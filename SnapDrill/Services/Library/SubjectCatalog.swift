import Foundation
import SwiftData

/// Seeds locale-appropriate default subjects and maintains the hidden fallback "Uncategorized" bucket (PRD §3.1, §8.6).
@MainActor
enum SubjectCatalog {
    static let uncategorizedUUID = UUID(uuidString: "A1B2C3D4-0000-4000-8000-000000000000")!
    static let builtinSlotUUIDs: [UUID] = [
        UUID(uuidString: "A1B2C3D4-0001-4000-8000-000000000001")!,
        UUID(uuidString: "A1B2C3D4-0002-4000-8000-000000000002")!,
        UUID(uuidString: "A1B2C3D4-0003-4000-8000-000000000003")!,
        UUID(uuidString: "A1B2C3D4-0004-4000-8000-000000000004")!,
        UUID(uuidString: "A1B2C3D4-0005-4000-8000-000000000005")!
    ]

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

    /// Idempotently seeds built-in subjects with deterministic IDs and deduplicates any CloudKit merge duplicates (M5, AC-01).
    @discardableResult
    static func ensureSeeded(in context: ModelContext, locale: Locale = .current) -> [Subject] {
        let descriptor = FetchDescriptor<Subject>(sortBy: [SortDescriptor(\Subject.sortOrder)])
        let existing = (try? context.fetch(descriptor)) ?? []

        deduplicateSubjectsIfNeeded(existing: existing, in: context)

        let afterDedup = (try? context.fetch(descriptor)) ?? existing
        let existingIDs = Set(afterDedup.map(\.id))

        let hasRegularSubjects = afterDedup.contains { !$0.isUncategorizedBucket }
        if !hasRegularSubjects {
            let specs = defaultSubjects(for: locale)
            for (index, spec) in specs.enumerated() {
                let deterministicID = builtinSlotUUIDs.indices.contains(index) ? builtinSlotUUIDs[index] : UUID()
                guard !existingIDs.contains(deterministicID) else { continue }
                let subject = Subject(
                    id: deterministicID,
                    name: spec.name,
                    colorHex: spec.colorHex,
                    sortOrder: index,
                    isBuiltin: true,
                    isUncategorizedBucket: false
                )
                context.insert(subject)
            }
        }

        if !afterDedup.contains(where: { $0.isUncategorizedBucket || $0.id == uncategorizedUUID }) {
            let fallback = Subject(
                id: uncategorizedUUID,
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
        deduplicateSubjectsIfNeeded(existing: all, in: context)
        let refreshed = (try? context.fetch(descriptor)) ?? all
        if let existing = refreshed.first(where: { $0.isUncategorizedBucket }) {
            return existing
        }
        let created = Subject(
            id: uncategorizedUUID,
            name: uncategorizedTitle(for: locale),
            colorHex: "4E5D6C",
            sortOrder: 9_999,
            isBuiltin: true,
            isUncategorizedBucket: true
        )
        context.insert(created)
        return created
    }

    /// Deduplicates any CloudKit-merged duplicate subjects without re-seeding user-deleted subjects (M5).
    static func deduplicateExisting(in context: ModelContext) {
        let descriptor = FetchDescriptor<Subject>(sortBy: [SortDescriptor(\Subject.sortOrder)])
        guard let existing = try? context.fetch(descriptor), existing.count > 1 else { return }
        let removedAny = deduplicateSubjectsIfNeeded(existing: existing, in: context)
        if removedAny {
            try? context.save()
        }
    }

    /// Merges duplicate Subjects (e.g., two CloudKit devices seeding before initial sync completes) onto the canonical record.
    @discardableResult
    static func deduplicateSubjectsIfNeeded(existing: [Subject], in context: ModelContext) -> Bool {
        var didModify = false
        let uncategorizedRecords = existing
            .filter { $0.isUncategorizedBucket || $0.id == uncategorizedUUID }
            .sorted { lhs, rhs in
                if (lhs.id == uncategorizedUUID) != (rhs.id == uncategorizedUUID) {
                    return lhs.id == uncategorizedUUID
                }
                return lhs.createdAt < rhs.createdAt
            }

        if let canonicalUncat = uncategorizedRecords.first, uncategorizedRecords.count > 1 {
            for duplicate in uncategorizedRecords.dropFirst() {
                for mistake in duplicate.mistakeList {
                    mistake.subject = canonicalUncat
                }
                context.delete(duplicate)
                didModify = true
            }
        }

        let regularRecords = existing.filter { !$0.isUncategorizedBucket && $0.id != uncategorizedUUID }
        let groupedByID = Dictionary(grouping: regularRecords, by: \.id)
        for (_, bucket) in groupedByID where bucket.count > 1 {
            let sorted = bucket.sorted { $0.createdAt < $1.createdAt }
            guard let canonical = sorted.first else { continue }
            for duplicate in sorted.dropFirst() {
                for mistake in duplicate.mistakeList {
                    mistake.subject = canonical
                }
                context.delete(duplicate)
                didModify = true
            }
        }
        return didModify
    }
}
