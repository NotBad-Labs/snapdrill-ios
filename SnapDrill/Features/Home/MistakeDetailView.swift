import SwiftData
import SwiftUI

struct MistakeDetailView: View {
    @Bindable var item: MistakeItem
    @State private var showOriginal = false
    @State private var showDeleteUndo = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(height: 280)
                    .overlay {
                        VStack {
                            Image(systemName: showOriginal ? "photo" : "wand.and.stars")
                            Text(showOriginal ? String(localized: "Original") : String(localized: "Cleaned"))
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }

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