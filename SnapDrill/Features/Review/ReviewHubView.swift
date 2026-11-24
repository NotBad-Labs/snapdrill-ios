import SwiftData
import SwiftUI

/// Tab 2: Filter and launch calm, self-paced mistake review sessions (PRD §8.4, F-40).
struct ReviewHubView: View {
    @Environment(AppEnvironment.self) private var environment

    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query(sort: \MistakeItem.createdAt, order: .reverse) private var allMistakes: [MistakeItem]
    @Query(sort: \MistakeTag.name) private var tags: [MistakeTag]

    @State private var criteria = MistakeFilterCriteria()
    @State private var activeSessionMistakes: [MistakeItem]?

    private var visibleMistakes: [MistakeItem] {
        allMistakes.filter { !environment.pendingDeletionIDs.contains($0.id) }
    }

    private var matchingMistakes: [MistakeItem] {
        MistakeFilterEngine.filter(visibleMistakes, using: criteria)
    }

    private var displayedSubjects: [Subject] {
        subjects.filter { subj in
            if subj.isUncategorizedBucket {
                return visibleMistakes.contains { $0.subject?.id == subj.id }
            }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 11) {
                    summaryCard
                    subjectFilterCard
                    masteryAndCauseFilterCard

                    if !tags.isEmpty {
                        tagFilterCard
                    }

                    startReviewButton
                }
                .padding(.horizontal, SnapDrillTheme.screenPadding)
                .padding(.top, 4)
                .padding(.bottom, 140)
            }
            .paperBackground()
            .navigationTitle(String(localized: "Review"))
            .fullScreenCover(isPresented: Binding(
                get: { activeSessionMistakes != nil },
                set: { if !$0 { activeSessionMistakes = nil } }
            )) {
                if let items = activeSessionMistakes {
                    ReviewSessionView(mistakes: items) {
                        activeSessionMistakes = nil
                    }
                }
            }
        }
    }

    // MARK: - Cards

    private var summaryCard: some View {
        PaperCard(padding: 13) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ready to Practice")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SnapDrillTheme.inkSecondary)

                    Text("\(matchingMistakes.count) questions")
                        .font(.title.weight(.bold).monospacedDigit())
                        .foregroundStyle(SnapDrillTheme.inkBlack)

                    let unmasteredCount = matchingMistakes.filter { $0.mastery != .mastered }.count
                    Text("\(unmasteredCount) still need review")
                        .font(.caption)
                        .foregroundStyle(SnapDrillTheme.inkBlue)
                }

                Spacer()

                Image(systemName: "rectangle.stack.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SnapDrillTheme.inkBlue)
                    .frame(width: 56, height: 56)
                    .background(SnapDrillTheme.inkBlueSoft, in: Circle())
                    .accessibilityHidden(true)
            }
        }
    }

    private var subjectFilterCard: some View {
        PaperCard(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Subjects")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SnapDrillTheme.inkBlack)
                    Spacer()
                    if !criteria.subjectIDs.isEmpty {
                        Button("All") { criteria.subjectIDs.removeAll() }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SnapDrillTheme.inkBlue)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(displayedSubjects) { subj in
                            let selected = criteria.subjectIDs.contains(subj.id)
                            Button {
                                if selected { criteria.subjectIDs.remove(subj.id) }
                                else { criteria.subjectIDs.insert(subj.id) }
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(selected ? Color.white : Color(hexString: subj.colorHex))
                                        .frame(width: 8, height: 8)
                                    Text(subj.name)
                                        .font(.caption.weight(.medium))
                                }
                                .foregroundStyle(selected ? .white : SnapDrillTheme.inkBlack)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule().fill(selected ? SnapDrillTheme.inkBlue : SnapDrillTheme.elevatedSurface)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var masteryAndCauseFilterCard: some View {
        PaperCard(padding: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mastery Level")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SnapDrillTheme.inkBlack)

                HStack(spacing: 8) {
                    ForEach(MasteryLevel.allCases) { level in
                        let selected = criteria.masteryLevels.contains(level)
                        Button {
                            if selected { criteria.masteryLevels.remove(level) }
                            else { criteria.masteryLevels.insert(level) }
                        } label: {
                            Label(level.localizedTitle, systemImage: level.symbolName)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(selected ? .white : SnapDrillTheme.inkBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(selected ? SnapDrillTheme.inkBlue : SnapDrillTheme.elevatedSurface)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                RuledDivider()

                Text("Error Causes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SnapDrillTheme.inkBlack)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MistakeCause.allCases) { cause in
                            let selected = criteria.causes.contains(cause)
                            Button {
                                if selected { criteria.causes.remove(cause) }
                                else { criteria.causes.insert(cause) }
                            } label: {
                                Text(cause.localizedTitle)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(selected ? .white : SnapDrillTheme.inkBlack)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule().fill(selected ? SnapDrillTheme.gradingRed : SnapDrillTheme.elevatedSurface)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var tagFilterCard: some View {
        PaperCard(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Tags")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SnapDrillTheme.inkBlack)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags) { tag in
                            let selected = criteria.tagNames.contains(tag.name)
                            Button {
                                if selected { criteria.tagNames.remove(tag.name) }
                                else { criteria.tagNames.insert(tag.name) }
                            } label: {
                                Text("#\(tag.name)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(selected ? .white : SnapDrillTheme.inkBlack)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule().fill(selected ? SnapDrillTheme.inkBlue : SnapDrillTheme.elevatedSurface)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var startReviewButton: some View {
        Button {
            activeSessionMistakes = matchingMistakes
        } label: {
            Label("Start Review (\(matchingMistakes.count))", systemImage: "play.fill")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    matchingMistakes.isEmpty ? SnapDrillTheme.inkSecondary.opacity(0.4) : SnapDrillTheme.inkBlue,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
        }
        .disabled(matchingMistakes.isEmpty)
        .buttonStyle(.plain)
    }
}
