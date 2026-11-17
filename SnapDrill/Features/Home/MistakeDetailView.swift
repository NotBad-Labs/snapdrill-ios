import SwiftData
import SwiftUI

struct MistakeDetailView: View {
    @Bindable var item: MistakeItem
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

                if !item.notes.isEmpty {
                    GroupBox(String(localized: "Notes")) {
                        Text(item.notes)
                    }
                }

                if !item.answerText.isEmpty {
                    GroupBox(String(localized: "Answer")) {
                        Text(item.answerText)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(item.createdAt.formatted(date: .abbreviated, time: .omitted))
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    // PRD §8.3 — 5 秒撤销条在 Slice 4 接持久化
                    showDeleteUndo = true
                } label: {
                    Label(String(localized: "Delete"), systemImage: "trash")
                }
            }
        }
        .paperBackground()
        .overlay(alignment: .bottom) {
            if showDeleteUndo {
                UndoDeleteBar()
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut, value: showDeleteUndo)
    }
}

private struct UndoDeleteBar: View {
    var body: some View {
        HStack {
            Text(String(localized: "Deleted · Undo"))
            Spacer()
            Button(String(localized: "Undo")) {}
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}