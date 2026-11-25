import SwiftData
import SwiftUI

/// Multi-dimensional filter sheet (causes, custom causes, tags, mastery, and date range) (PRD F-32).
struct MistakeListFilterSheet: View {
    @Binding var criteria: MistakeFilterCriteria

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MistakeTag.name) private var tags: [MistakeTag]
    @Query(sort: \CustomCause.sortOrder) private var customCauses: [CustomCause]

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    Picker("Date Range", selection: $criteria.dateRange) {
                        ForEach(DateRangeFilter.allCases) { range in
                            Text(range.localizedTitle).tag(range)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                .listRowBackground(SnapDrillTheme.cardSurface)

                Section("Mastery Level") {
                    ForEach(MasteryLevel.allCases) { level in
                        let selected = criteria.masteryLevels.contains(level)
                        Button {
                            toggle(level, in: &criteria.masteryLevels)
                        } label: {
                            HStack {
                                Label(level.localizedTitle, systemImage: level.symbolName)
                                    .foregroundStyle(SnapDrillTheme.inkBlack)
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(SnapDrillTheme.inkBlue)
                                }
                            }
                        }
                    }
                }
                .listRowBackground(SnapDrillTheme.cardSurface)

                Section("Error Causes") {
                    ForEach(MistakeCause.allCases) { cause in
                        let selected = criteria.causes.contains(cause)
                        Button {
                            toggle(cause, in: &criteria.causes)
                        } label: {
                            HStack {
                                Text(cause.localizedTitle)
                                    .foregroundStyle(SnapDrillTheme.inkBlack)
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(SnapDrillTheme.inkBlue)
                                }
                            }
                        }
                    }

                    ForEach(customCauses) { custom in
                        let selected = criteria.customCauseNames.contains(custom.name)
                        Button {
                            toggle(custom.name, in: &criteria.customCauseNames)
                        } label: {
                            HStack {
                                Text(custom.name)
                                    .foregroundStyle(SnapDrillTheme.inkBlack)
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(SnapDrillTheme.inkBlue)
                                }
                            }
                        }
                    }
                }
                .listRowBackground(SnapDrillTheme.cardSurface)

                if !tags.isEmpty {
                    Section("Tags") {
                        ForEach(tags) { tag in
                            let selected = criteria.tagNames.contains(tag.name)
                            Button {
                                toggle(tag.name, in: &criteria.tagNames)
                            } label: {
                                HStack {
                                    Text("#\(tag.name)")
                                        .foregroundStyle(SnapDrillTheme.inkBlack)
                                    Spacer()
                                    if selected {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(SnapDrillTheme.inkBlue)
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(SnapDrillTheme.cardSurface)
                }
            }
            .scrollContentBackground(.hidden)
            .paperBackground()
            .navigationTitle(String(localized: "Filter Mistakes"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        let preservedSubjects = criteria.subjectIDs
                        let preservedOCR = criteria.includeOCRTextSearch
                        criteria = MistakeFilterCriteria(
                            subjectIDs: preservedSubjects,
                            includeOCRTextSearch: preservedOCR
                        )
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func toggle<T: Hashable>(_ element: T, in set: inout Set<T>) {
        if set.contains(element) {
            set.remove(element)
        } else {
            set.insert(element)
        }
    }
}
