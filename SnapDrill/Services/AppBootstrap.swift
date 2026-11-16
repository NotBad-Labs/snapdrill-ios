import Foundation
import SwiftData

@MainActor
final class AppBootstrap {
    private let lastSubjectKey = "snapdrill.lastSubjectID"

    func seedIfNeeded(context: ModelContext) async {
        let descriptor = FetchDescriptor<Subject>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let defaults = SubjectCatalog.defaultSubjects()
        for (index, item) in defaults.enumerated() {
            let subject = Subject(
                name: item.name,
                colorHex: item.colorHex,
                sortOrder: index,
                isBuiltin: true
            )
            context.insert(subject)
        }

        let uncategorized = Subject(
            name: SubjectCatalog.uncategorizedName,
            colorHex: "9CA3AF",
            sortOrder: 999,
            isBuiltin: true,
            isUncategorizedBucket: true
        )
        context.insert(uncategorized)

        try? context.save()
    }

    func rememberLastSubject(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: lastSubjectKey)
    }

    func lastSubjectID() -> UUID? {
        guard let raw = UserDefaults.standard.string(forKey: lastSubjectKey) else { return nil }
        return UUID(uuidString: raw)
    }
}