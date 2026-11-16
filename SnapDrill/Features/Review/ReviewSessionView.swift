import SwiftUI

struct ReviewSessionView: View {
    let items: [MistakeItem]
    @State private var index = 0
    @State private var revealAnswer = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(String(localized: "Exit")) { dismiss() }
                Spacer()
                Text("\(min(index + 1, max(items.count, 1))) / \(items.count)")
                    .font(.subheadline.monospacedDigit())
            }
            .padding()

            if items.isEmpty {
                ContentUnavailableView(String(localized: "Nothing to review"), systemImage: "checkmark.circle")
            } else if index >= items.count {
                ReviewCompleteView(count: items.count) {
                    index = 0
                    revealAnswer = false
                } onDone: {
                    dismiss()
                }
            } else {
                reviewCard(for: items[index])
            }
        }
        .paperBackground()
        .navigationBarBackButtonHidden(index > 0 && index < items.count)
    }

    @ViewBuilder
    private func reviewCard(for item: MistakeItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(height: 240)
                    .overlay {
                        Image(systemName: "doc.text.image")
                            .foregroundStyle(.secondary)
                    }

                if revealAnswer {
                    VStack(alignment: .leading, spacing: 8) {
                        if !item.answerText.isEmpty {
                            Text(item.answerText)
                        } else {
                            Text(String(localized: "No answer yet"))
                                .foregroundStyle(.secondary)
                        }
                        if !item.notes.isEmpty {
                            Text(item.notes)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Button(String(localized: "Tap to reveal answer")) {
                        revealAnswer = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SnapDrillTheme.inkBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }

        HStack {
            Button(String(localized: "Previous")) {
                guard index > 0 else { return }
                index -= 1
                revealAnswer = false
            }
            .disabled(index == 0)

            Spacer()

            Button(index + 1 >= items.count ? String(localized: "Finish") : String(localized: "Next")) {
                if index + 1 >= items.count {
                    index = items.count
                } else {
                    index += 1
                    revealAnswer = false
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(SnapDrillTheme.inkBlue)
        }
        .padding()
    }
}

private struct ReviewCompleteView: View {
    let count: Int
    let onAgain: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 44))
                .foregroundStyle(SnapDrillTheme.inkBlue)
            Text(String(localized: "Finished \(count) mistakes this round"))
                .font(.title3.weight(.medium))
            HStack {
                Button(String(localized: "Again"), action: onAgain)
                    .buttonStyle(.bordered)
                Button(String(localized: "Done"), action: onDone)
                    .buttonStyle(.borderedProminent)
                    .tint(SnapDrillTheme.inkBlue)
            }
        }
        .padding()
    }
}