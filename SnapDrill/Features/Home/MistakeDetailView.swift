import SwiftData
import SwiftUI

struct MistakeDetailView: View {
    @Bindable var item: MistakeItem
    @Environment(\.modelContext) private var context

    @State private var showOriginal = false
    @State private var showDeleteUndo = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MistakeThumbnail(
                    item: item,
                    presentation: showOriginal ? .original : .cleaned
                )
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .background(Color.secondary.opacity(0.08))

                Button(showOriginal ? String(localized: "Show cleaned") : String(localized: "Show original")) {
                    showOriginal.toggle()
                }
                .buttonStyle(.bordered)

                GroupBox(String(localized: "Answer")) {
                    TextField(String(localized: "Correct answer"), text: $item.answerText, axis: .vertical)
                        .lineLimit(3...6)
                }

                GroupBox(String(localized: "Notes")) {
                    TextField(String(localized: "Your notes"), text: $item.notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                GroupBox(String(localized: "Causes")) {
                    FlowLayoutMistakeCauses(selection: causesBinding)
                }

                Picker(String(localized: "Mastery"), selection: masteryBinding) {
                    ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
                        Text(level.localizedTitle).tag(level)
                    }
                }
                .pickerStyle(.segmented)

                if item.isDemoSample {
                    Label(String(localized: "UI demo sample"), systemImage: "sparkles")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button(String(localized: "Recrop question (Slice 4)")) {}
                    .buttonStyle(.bordered)
                    .disabled(true)
            }
            .padding()
        }
        .navigationTitle(item.createdAt.formatted(date: .abbreviated, time: .omitted))
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteUndo = true
                } label: {
                    Label(String(localized: "Delete"), systemImage: "trash")
                }
            }
        }
        .paperBackground()
        .onChange(of: item.answerText) { _, _ in try? context.save() }
        .onChange(of: item.notes) { _, _ in try? context.save() }
        .overlay(alignment: .bottom) {
            if showDeleteUndo {
                UndoDeleteBar {
                    showDeleteUndo = false
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut, value: showDeleteUndo)
    }

    private var causesBinding: Binding<Set<MistakeCause>> {
        Binding(
            get: { Set(item.causes) },
            set: { newValue in
                item.causes = Array(newValue)
                try? context.save()
            }
        )
    }

    private var masteryBinding: Binding<MasteryLevel> {
        Binding(
            get: { item.mastery },
            set: { newValue in
                item.mastery = newValue
                try? context.save()
            }
        )
    }
}

private struct FlowLayoutMistakeCauses: View {
    @Binding var selection: Set<MistakeCause>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(MistakeCause.allCases) { cause in
                Toggle(cause.localizedTitle, isOn: binding(for: cause))
            }
        }
    }

    private func binding(for cause: MistakeCause) -> Binding<Bool> {
        Binding(
            get: { selection.contains(cause) },
            set: { on in
                if on { selection.insert(cause) }
                else { selection.remove(cause) }
            }
        )
    }
}

private struct UndoDeleteBar: View {
    let onUndo: () -> Void

    var body: some View {
        HStack {
            Text(String(localized: "Deleted · Undo"))
            Spacer()
            Button(String(localized: "Undo"), action: onUndo)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}