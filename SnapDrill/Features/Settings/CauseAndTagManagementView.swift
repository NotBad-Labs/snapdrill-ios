import SwiftData
import SwiftUI

/// Manage custom error causes and tags; deleting a tag or custom cause never deletes any MistakeItem (PRD §8.6, AC-09).
struct CauseAndTagManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var environment

    @Query(sort: \CustomCause.sortOrder) private var customCauses: [CustomCause]
    @Query(sort: \MistakeTag.name) private var tags: [MistakeTag]

    @State private var newCauseName = ""
    @State private var newTagName = ""

    var body: some View {
        List {
            Section("Built-in Error Causes") {
                ForEach(MistakeCause.allCases) { cause in
                    Text(cause.localizedTitle)
                        .foregroundStyle(SnapDrillTheme.inkBlack)
                }
            }

            Section {
                HStack {
                    TextField("Add custom cause (e.g. Time Out)", text: $newCauseName)
                    Button("Add") {
                        let trimmed = newCauseName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let created = CustomCause(
                            name: trimmed,
                            sortOrder: (customCauses.map(\.sortOrder).max() ?? 0) + 1
                        )
                        modelContext.insert(created)
                        try? modelContext.save()
                        newCauseName = ""
                    }
                    .disabled(newCauseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                ForEach(customCauses) { custom in
                    Text(custom.name)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                try? environment.saveService.deleteCustomCause(custom, in: modelContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            } header: {
                Text("Custom Error Causes")
            } footer: {
                Text("Removing a cause or tag only unlinks it from existing mistakes without deleting any questions.")
            }

            Section("Tags") {
                HStack {
                    TextField("Add tag (e.g. Final Exam)", text: $newTagName)
                    Button("Add") {
                        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if !tags.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                            let tag = MistakeTag(name: trimmed)
                            modelContext.insert(tag)
                            try? modelContext.save()
                        }
                        newTagName = ""
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                ForEach(tags) { tag in
                    HStack {
                        Text("#\(tag.name)")
                        Spacer()
                        Text("\(tag.mistakes.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            try? environment.saveService.deleteTag(tag, in: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .paperBackground()
        .navigationTitle(String(localized: "Causes & Tags"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
