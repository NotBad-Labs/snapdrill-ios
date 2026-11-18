import SwiftUI

/// AC-05 筛选 UI 壳；组合查询在 Slice 4 持久化。
struct MistakeListFilterState: Equatable {
    var causeFilter: Set<MistakeCause> = []
    var masteryFilter: Set<MasteryLevel> = []
    var onlyDemo: Bool = false

    var isActive: Bool {
        !causeFilter.isEmpty || !masteryFilter.isEmpty || onlyDemo
    }
}

struct MistakeListFilterSheet: View {
    @Binding var state: MistakeListFilterState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Mistake causes")) {
                    ForEach(MistakeCause.allCases) { cause in
                        Toggle(cause.localizedTitle, isOn: bindingForCause(cause))
                    }
                }
                Section(String(localized: "Mastery")) {
                    ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
                        Toggle(level.localizedTitle, isOn: bindingForMastery(level))
                    }
                }
                Section(String(localized: "Demo")) {
                    Toggle(String(localized: "Only UI demo samples"), isOn: $state.onlyDemo)
                }
            }
            .navigationTitle(String(localized: "Filter"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Reset")) {
                        state = MistakeListFilterState()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
        }
    }

    private func bindingForCause(_ cause: MistakeCause) -> Binding<Bool> {
        Binding(
            get: { state.causeFilter.contains(cause) },
            set: { on in
                if on { state.causeFilter.insert(cause) }
                else { state.causeFilter.remove(cause) }
            }
        )
    }

    private func bindingForMastery(_ level: MasteryLevel) -> Binding<Bool> {
        Binding(
            get: { state.masteryFilter.contains(level) },
            set: { on in
                if on { state.masteryFilter.insert(level) }
                else { state.masteryFilter.remove(level) }
            }
        )
    }
}

extension MasteryLevel {
    var localizedTitle: String {
        switch self {
        case .unknown: String(localized: "Unknown")
        case .fuzzy: String(localized: "Fuzzy")
        case .mastered: String(localized: "Mastered")
        }
    }
}