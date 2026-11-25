import SwiftData
import SwiftUI

/// Manage subjects: add, rename, reorder, customize swatch, and delete non-empty subjects safely (PRD §8.6, F-61, AC-09).
struct SubjectManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var environment

    @Query(sort: \Subject.sortOrder) private var allSubjects: [Subject]

    @State private var showingAddSheet = false
    @State private var editingSubject: Subject?
    @State private var subjectPendingDeletion: Subject?
    @State private var showingNonEmptyOptions = false
    @State private var showingDeleteWithMistakesConfirm = false

    private var editableSubjects: [Subject] {
        allSubjects.filter { !$0.isUncategorizedBucket }
    }

    var body: some View {
        List {
            Section {
                ForEach(editableSubjects) { subject in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hexString: subject.colorHex))
                            .frame(width: 14, height: 14)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(subject.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SnapDrillTheme.inkBlack)
                            Text("\(subject.mistakeList.count) problems")
                                .font(.caption)
                                .foregroundStyle(SnapDrillTheme.inkSecondary)
                        }

                        Spacer()

                        Button {
                            editingSubject = subject
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(SnapDrillTheme.inkBlue)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "Edit \(subject.name)"))
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            requestDelete(subject)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onMove(perform: moveSubjects)
            } footer: {
                Text("Drag rows in Edit mode to reorder. Deleting a subject with saved mistakes lets you move them safely into Uncategorized.")
            }

            if let uncategorized = allSubjects.first(where: { $0.isUncategorizedBucket }) {
                Section("System Fallback") {
                    HStack {
                        Circle()
                            .fill(Color(hexString: uncategorized.colorHex))
                            .frame(width: 14, height: 14)
                        Text(uncategorized.name)
                        Spacer()
                        Text("\(uncategorized.mistakeList.count) · Protected")
                            .font(.caption)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .paperBackground()
        .navigationTitle(String(localized: "Subjects"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                EditButton()
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(String(localized: "Add Subject"))
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            SubjectEditorSheet(
                subject: nil,
                nextOrder: (editableSubjects.map(\.sortOrder).max() ?? 0) + 1
            )
        }
        .sheet(item: $editingSubject) { subject in
            SubjectEditorSheet(subject: subject, nextOrder: subject.sortOrder)
        }
        .confirmationDialog(
            String(localized: "Delete Subject"),
            isPresented: $showingNonEmptyOptions,
            titleVisibility: .visible
        ) {
            if let target = subjectPendingDeletion {
                Button(String(localized: "Move \(target.mistakeList.count) Mistakes to Uncategorized")) {
                    try? environment.saveService.deleteSubject(target, strategy: .moveToUncategorized, in: modelContext)
                    subjectPendingDeletion = nil
                }

                Button(String(localized: "Delete Subject & \(target.mistakeList.count) Mistakes"), role: .destructive) {
                    showingDeleteWithMistakesConfirm = true
                }
            }
            Button("Cancel", role: .cancel) {
                subjectPendingDeletion = nil
            }
        } message: {
            if let target = subjectPendingDeletion {
                Text("\"\(target.name)\" contains \(target.mistakeList.count) mistakes. Choose how to handle them.")
            }
        }
        .alert("Permanently Delete Mistakes?", isPresented: $showingDeleteWithMistakesConfirm) {
            Button("Delete All", role: .destructive) {
                if let target = subjectPendingDeletion {
                    try? environment.saveService.deleteSubject(target, strategy: .deleteWithMistakes, in: modelContext)
                }
                subjectPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                subjectPendingDeletion = nil
            }
        } message: {
            Text("This will permanently erase the subject and all mistakes inside it.")
        }
    }

    private func requestDelete(_ subject: Subject) {
        if subject.mistakeList.isEmpty {
            try? environment.saveService.deleteSubject(subject, strategy: .moveToUncategorized, in: modelContext)
        } else {
            subjectPendingDeletion = subject
            showingNonEmptyOptions = true
        }
    }

    private func moveSubjects(from source: IndexSet, to destination: Int) {
        var reordered = editableSubjects
        reordered.move(fromOffsets: source, toOffset: destination)
        for (idx, subj) in reordered.enumerated() {
            subj.sortOrder = idx
        }
        try? modelContext.save()
    }
}

private struct SubjectEditorSheet: View {
    let subject: Subject?
    let nextOrder: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var colorHex = "2C5689"

    var body: some View {
        NavigationStack {
            Form {
                Section("Subject Name") {
                    TextField("e.g. Biology, History", text: $name)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(Array(SnapDrillTheme.subjectPaletteHexes.enumerated()), id: \.element) { idx, hex in
                            Button {
                                colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hexString: hex))
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: colorHex == hex ? 3 : 0)
                                            .padding(3)
                                    )
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color(hexString: hex), lineWidth: colorHex == hex ? 2 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(String(localized: "Color \(idx + 1)"))
                            .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle(subject == nil ? String(localized: "New Subject") : String(localized: "Edit Subject"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if let subject {
                            subject.name = trimmed
                            subject.colorHex = colorHex
                        } else {
                            let created = Subject(name: trimmed, colorHex: colorHex, sortOrder: nextOrder)
                            modelContext.insert(created)
                        }
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let subject {
                    name = subject.name
                    colorHex = subject.colorHex
                }
            }
        }
    }
}
