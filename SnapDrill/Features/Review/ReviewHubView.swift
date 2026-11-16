import SwiftData
import SwiftUI

struct ReviewHubView: View {
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query private var mistakes: [MistakeItem]
    @State private var selectedSubjectIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Subjects")) {
                    ForEach(subjects.filter { !$0.isUncategorizedBucket }) { subject in
                        Toggle(subject.name, isOn: binding(for: subject.id))
                    }
                }
                Section {
                    NavigationLink {
                        ReviewSessionView(items: filteredMistakes)
                    } label: {
                        Text(String(localized: "Start review (\(filteredMistakes.count))"))
                    }
                    .disabled(filteredMistakes.isEmpty)
                }
            }
            .navigationTitle(String(localized: "Review"))
            .onAppear {
                if selectedSubjectIDs.isEmpty {
                    selectedSubjectIDs = Set(subjects.map(\.id))
                }
            }
            .paperBackground()
        }
    }

    private var filteredMistakes: [MistakeItem] {
        mistakes.filter { item in
            guard let id = item.subject?.id else { return false }
            return selectedSubjectIDs.contains(id)
        }
    }

    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedSubjectIDs.contains(id) },
            set: { on in
                if on { selectedSubjectIDs.insert(id) }
                else { selectedSubjectIDs.remove(id) }
            }
        )
    }
}