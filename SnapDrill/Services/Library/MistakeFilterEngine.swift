import Foundation

/// Date range presets for combined mistake filtering (PRD F-32).
enum DateRangeFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case last7Days
    case last30Days
    case last90Days

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .all: return String(localized: "All Time")
        case .last7Days: return String(localized: "Last 7 Days")
        case .last30Days: return String(localized: "Last 30 Days")
        case .last90Days: return String(localized: "Last 90 Days")
        }
    }

    func cutoffDate(relativeTo reference: Date = .now) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .all: return nil
        case .last7Days: return calendar.date(byAdding: .day, value: -7, to: reference)
        case .last30Days: return calendar.date(byAdding: .day, value: -30, to: reference)
        case .last90Days: return calendar.date(byAdding: .day, value: -90, to: reference)
        }
    }
}

/// Shared filter criteria inherited smoothly from MistakeListView into ReviewSessionView (PRD §8.4, AC-06).
struct MistakeFilterCriteria: Equatable, Sendable {
    var subjectIDs: Set<UUID> = []
    var causes: Set<MistakeCause> = []
    var customCauseNames: Set<String> = []
    var tagNames: Set<String> = []
    var masteryLevels: Set<MasteryLevel> = []
    var dateRange: DateRangeFilter = .all
    var searchQuery: String = ""
    var includeOCRTextSearch: Bool = false

    var hasActiveModifiers: Bool {
        !causes.isEmpty ||
        !customCauseNames.isEmpty ||
        !tagNames.isEmpty ||
        !masteryLevels.isEmpty ||
        dateRange != .all ||
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var activeFilterBadgeCount: Int {
        var count = 0
        if !causes.isEmpty || !customCauseNames.isEmpty { count += 1 }
        if !tagNames.isEmpty { count += 1 }
        if !masteryLevels.isEmpty { count += 1 }
        if dateRange != .all { count += 1 }
        return count
    }
}

/// Pure shared filtering engine used by Home, List, Review, and unit tests.
enum MistakeFilterEngine {
    static func filter(
        _ items: [MistakeItem],
        using criteria: MistakeFilterCriteria,
        referenceDate: Date = .now
    ) -> [MistakeItem] {
        let query = criteria.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let cutoff = criteria.dateRange.cutoffDate(relativeTo: referenceDate)

        return items.filter { item in
            if !criteria.subjectIDs.isEmpty {
                guard let subjectID = item.subject?.id, criteria.subjectIDs.contains(subjectID) else {
                    return false
                }
            }

            if !criteria.causes.isEmpty || !criteria.customCauseNames.isEmpty {
                let matchesBuiltIn = !criteria.causes.isDisjoint(with: Set(item.causes))
                let matchesCustom = !criteria.customCauseNames.isDisjoint(with: Set(item.customCauseNames))
                if !(matchesBuiltIn || matchesCustom) {
                    return false
                }
            }

            if !criteria.tagNames.isEmpty {
                let itemTagNames = Set(item.tags.map(\.name))
                if criteria.tagNames.isDisjoint(with: itemTagNames) {
                    return false
                }
            }

            if !criteria.masteryLevels.isEmpty && !criteria.masteryLevels.contains(item.mastery) {
                return false
            }

            if let cutoff, item.createdAt < cutoff {
                return false
            }

            if !query.isEmpty {
                let matchesMetadata =
                    item.notes.localizedCaseInsensitiveContains(query) ||
                    item.answerText.localizedCaseInsensitiveContains(query) ||
                    item.sourceTitle.localizedCaseInsensitiveContains(query) ||
                    item.tags.contains { $0.name.localizedCaseInsensitiveContains(query) } ||
                    (item.subject?.name.localizedCaseInsensitiveContains(query) ?? false)

                let matchesOCR = criteria.includeOCRTextSearch && item.ocrText.localizedCaseInsensitiveContains(query)
                if !(matchesMetadata || matchesOCR) {
                    return false
                }
            }

            return true
        }
    }
}
