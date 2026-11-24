import SwiftData
import SwiftUI

/// Card-based hidden-answer review flow supporting cleaned/original toggle and mastery grading (PRD §8.4, AC-06).
struct ReviewSessionView: View {
    let mistakes: [MistakeItem]
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var environment

    @State private var sessionQueue: [MistakeItem]
    @State private var currentIndex: Int = 0
    @State private var isAnswerRevealed: Bool = false
    @State private var showOriginal: Bool = false
    @State private var isCompleted: Bool = false

    init(mistakes: [MistakeItem], onDismiss: @escaping () -> Void) {
        self.mistakes = mistakes
        self.onDismiss = onDismiss
        _sessionQueue = State(initialValue: mistakes)
    }

    private var currentItem: MistakeItem? {
        guard sessionQueue.indices.contains(currentIndex) else { return nil }
        return sessionQueue[currentIndex]
    }

    var body: some View {
        NavigationStack {
            Group {
                if isCompleted || sessionQueue.isEmpty {
                    completionView
                } else if let item = currentItem {
                    activeCardView(item: item)
                }
            }
            .paperBackground()
            .navigationTitle(isCompleted ? String(localized: "Session Complete") : "\(currentIndex + 1) / \(sessionQueue.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(String(localized: "Exit Review"))
                }

                if !isCompleted && currentItem != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showOriginal.toggle()
                        } label: {
                            Label(
                                showOriginal ? String(localized: "Original") : String(localized: "Cleaned"),
                                systemImage: showOriginal ? "photo" : "wand.and.stars"
                            )
                            .font(.caption.weight(.semibold))
                        }
                        .accessibilityLabel(String(localized: "Toggle Original or Cleaned Image"))
                    }
                }
            }
        }
    }

    // MARK: - Active Review Card

    private func activeCardView(item: MistakeItem) -> some View {
        VStack(spacing: 14) {
            // Subtle progress bar
            ProgressView(value: Double(currentIndex + 1), total: Double(max(1, sessionQueue.count)))
                .tint(SnapDrillTheme.inkBlue)
                .padding(.horizontal, SnapDrillTheme.screenPadding)

            ScrollView {
                VStack(spacing: 14) {
                    // Upper half: Problem stem image (hidden answer mode)
                    PaperCard(padding: 10) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                if let subj = item.subject {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(Color(hexString: subj.colorHex))
                                            .frame(width: 8, height: 8)
                                        Text(subj.name)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(SnapDrillTheme.inkBlue)
                                    }
                                }
                                if !item.sourceTitle.isEmpty {
                                    Text("· \(item.sourceTitle)")
                                        .font(.caption)
                                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                                }
                                Spacer()
                            }

                            if let imgData = showOriginal
                                ? item.resolvedOriginalImageData(imageStore: environment.imageStore)
                                : item.resolvedCleanedImageData(imageStore: environment.imageStore),
                               let img = UIImage(data: imgData) {
                                ZoomableImageView(image: img)
                                    .frame(height: 270)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }

                    // Lower half: Answer concealed until tapped (PRD §8.4, AC-06)
                    if !isAnswerRevealed {
                        Button {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                isAnswerRevealed = true
                            }
                        } label: {
                            PaperCard(padding: 28, background: SnapDrillTheme.elevatedSurface) {
                                VStack(spacing: 10) {
                                    Image(systemName: "eye.fill")
                                        .font(.title2)
                                        .foregroundStyle(SnapDrillTheme.inkBlue)
                                    Text("Tap to Reveal Answer & Notes")
                                        .font(.headline)
                                        .foregroundStyle(SnapDrillTheme.inkBlack)
                                    Text("Try solving it on scratch paper before checking.")
                                        .font(.caption)
                                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "Tap to Reveal Answer"))
                    } else {
                        revealedAnswerCard(item: item)
                    }
                }
                .padding(.horizontal, SnapDrillTheme.screenPadding)
                .padding(.bottom, 16)
            }

            // Bottom navigation / mastery buttons
            bottomControls(item: item)
                .padding(.horizontal, SnapDrillTheme.screenPadding)
                .padding(.bottom, 16)
        }
    }

    private func revealedAnswerCard(item: MistakeItem) -> some View {
        PaperCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Answer & Reflection")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SnapDrillTheme.inkBlue)
                    Spacer()
                    Button("Hide") {
                        withAnimation { isAnswerRevealed = false }
                    }
                    .font(.caption.weight(.medium))
                }

                RuledDivider()

                if !item.answerText.isEmpty {
                    Text(item.answerText)
                        .font(.subheadline)
                        .foregroundStyle(SnapDrillTheme.inkBlack)
                }

                let resolvedAnswerDatas = item.resolvedAnswerImageDatas(imageStore: environment.imageStore)
                if !resolvedAnswerDatas.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(resolvedAnswerDatas.enumerated()), id: \.offset) { _, data in
                                if let img = UIImage(data: data) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }

                if !item.causes.isEmpty || !item.customCauseNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(item.causes) { cause in
                                Text(cause.localizedTitle)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(SnapDrillTheme.gradingRed)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(SnapDrillTheme.gradingRedSoft, in: Capsule())
                            }
                            ForEach(item.customCauseNames, id: \.self) { custom in
                                Text(custom)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(SnapDrillTheme.gradingRed)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(SnapDrillTheme.gradingRedSoft, in: Capsule())
                            }
                        }
                    }
                }

                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.caption)
                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                }

                if item.answerText.isEmpty && resolvedAnswerDatas.isEmpty && item.notes.isEmpty && item.causes.isEmpty && item.customCauseNames.isEmpty {
                    Text("No answer or notes saved for this problem yet.")
                        .font(.subheadline)
                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func bottomControls(item: MistakeItem) -> some View {
        VStack(spacing: 10) {
            if isAnswerRevealed {
                HStack(spacing: 10) {
                    masteryActionButton(title: MasteryLevel.unknown.localizedTitle, color: SnapDrillTheme.gradingRed) {
                        recordMastery(.unknown, for: item)
                    }
                    masteryActionButton(title: MasteryLevel.fuzzy.localizedTitle, color: SnapDrillTheme.pencilYellow, foreground: Color(hexString: "1F1F22")) {
                        recordMastery(.fuzzy, for: item)
                    }
                    masteryActionButton(title: MasteryLevel.mastered.localizedTitle, color: SnapDrillTheme.masteryGreen) {
                        recordMastery(.mastered, for: item)
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    goPrevious()
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(SnapDrillTheme.cardSurface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1))
                }
                .disabled(currentIndex == 0)

                Button {
                    goNext()
                } label: {
                    Label(currentIndex == sessionQueue.count - 1 ? String(localized: "Finish") : String(localized: "Next"), systemImage: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func masteryActionButton(
        title: String,
        color: Color,
        foreground: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(color, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completion Screen (PRD §8.4)

    private var completionView: some View {
        VStack(spacing: 20) {
            Spacer()
            PandaMascotView(mood: .celebrating, size: 130)

            Text("Finished this round (\(sessionQueue.count) problems)")
                .font(.title2.weight(.bold))
                .foregroundStyle(SnapDrillTheme.inkBlack)
                .multilineTextAlignment(.center)

            Text("Take a breather—steady review builds lasting memory.")
                .font(.subheadline)
                .foregroundStyle(SnapDrillTheme.inkSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button {
                    currentIndex = 0
                    isAnswerRevealed = false
                    showOriginal = false
                    isCompleted = false
                } label: {
                    Text("Practice Again")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 14))
                }

                let unmastered = mistakes.filter { $0.mastery != .mastered }
                if !unmastered.isEmpty && unmastered.count < sessionQueue.count {
                    Button {
                        sessionQueue = unmastered
                        currentIndex = 0
                        isAnswerRevealed = false
                        showOriginal = false
                        isCompleted = false
                    } label: {
                        Text("Drill Unmastered Only (\(unmastered.count))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SnapDrillTheme.inkBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(SnapDrillTheme.inkBlueSoft, in: RoundedRectangle(cornerRadius: 14))
                    }
                }

                Button("Return") {
                    onDismiss()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SnapDrillTheme.inkSecondary)
                .padding(.top, 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)

            Spacer()
        }
        .padding(20)
    }

    // MARK: - Actions

    private func recordMastery(_ level: MasteryLevel, for item: MistakeItem) {
        item.mastery = level
        item.reviewCount += 1
        item.lastReviewedAt = .now
        try? modelContext.save()
        goNext()
    }

    private func goPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        isAnswerRevealed = false
        showOriginal = false
    }

    private func goNext() {
        if currentIndex < sessionQueue.count - 1 {
            currentIndex += 1
            isAnswerRevealed = false
            showOriginal = false
        } else {
            withAnimation {
                isCompleted = true
            }
        }
    }
}
