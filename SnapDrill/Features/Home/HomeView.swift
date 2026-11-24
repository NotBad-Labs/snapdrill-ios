import SwiftData
import SwiftUI

/// Tab 1: Home notebook overview displaying All Mistakes banner, keyword search, and 2-column subject cards (PRD §8.3, F-30).
struct HomeView: View {
    let onStartCapture: () -> Void

    @Environment(AppEnvironment.self) private var environment
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query(sort: \MistakeItem.createdAt, order: .reverse) private var allMistakes: [MistakeItem]

    @ScaledMetric private var headerBadgeSize: CGFloat = 44
    @ScaledMetric private var subjectDotSize: CGFloat = 12

    @State private var searchText = ""
    @State private var showingPaywall = false

    private var visibleMistakes: [MistakeItem] {
        allMistakes.filter { !environment.pendingDeletionIDs.contains($0.id) }
    }

    private var displayedSubjects: [Subject] {
        subjects.filter { subject in
            if subject.isUncategorizedBucket {
                return mistakeCount(for: subject) > 0
            }
            return true
        }
    }

    private var searchMatches: [MistakeItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        let criteria = MistakeFilterCriteria(
            searchQuery: query,
            includeOCRTextSearch: environment.proStore.isPro
        )
        return MistakeFilterEngine.filter(visibleMistakes, using: criteria)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        searchResultsSection
                    } else {
                        allMistakesCard
                        if visibleMistakes.isEmpty {
                            emptyNotebookCard
                        }
                        subjectGridSection
                    }
                }
                .padding(.horizontal, SnapDrillTheme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 108)
            }
            .paperBackground()
            .navigationTitle(String(localized: "Mistake Notebook"))
            .searchable(
                text: $searchText,
                prompt: environment.proStore.isPro
                    ? Text("Search questions, notes, or tags")
                    : Text("Search notes, tags, or subjects")
            )
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Sections

    private var allMistakesCard: some View {
        NavigationLink {
            MistakeListView(subject: nil)
        } label: {
            PaperCard(padding: 16) {
                HStack(spacing: 14) {
                    Image(systemName: "tray.full.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: headerBadgeSize, height: headerBadgeSize)
                        .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("All Mistakes")
                            .font(.headline)
                            .foregroundStyle(SnapDrillTheme.inkBlack)
                        Text("\(visibleMistakes.count) saved problems")
                            .font(.caption)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "All Mistakes, \(visibleMistakes.count) saved problems"))
    }

    private var emptyNotebookCard: some View {
        PaperCard(padding: 24) {
            VStack(spacing: 14) {
                PandaMascotView(mood: .welcoming, size: 112)

                Text("Your notebook is fresh and clean")
                    .font(.headline)
                    .foregroundStyle(SnapDrillTheme.inkBlack)
                    .multilineTextAlignment(.center)

                Text("Snap a homework or test page instead of copying by hand. SnapDrill cleans annotations right on your iPhone.")
                    .font(.subheadline)
                    .foregroundStyle(SnapDrillTheme.inkSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    onStartCapture()
                } label: {
                    Label("Snap Your First Mistake", systemImage: "camera.viewfinder")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(SnapDrillTheme.inkBlue, in: Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var subjectGridSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subjects")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SnapDrillTheme.inkSecondary)
                .padding(.leading, 4)

            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(displayedSubjects) { subject in
                    let count = mistakeCount(for: subject)
                    NavigationLink {
                        MistakeListView(subject: subject)
                    } label: {
                        PaperCard(padding: 14) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Circle()
                                        .fill(Color(hexString: subject.colorHex))
                                        .frame(width: subjectDotSize, height: subjectDotSize)
                                    Spacer()
                                    Text("\(count)")
                                        .font(.title3.weight(.bold).monospacedDigit())
                                        .foregroundStyle(SnapDrillTheme.inkBlack)
                                }

                                Text(subject.name)
                                    .font(.headline)
                                    .foregroundStyle(SnapDrillTheme.inkBlack)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                Text(count == 0 ? String(localized: "Empty") : String(localized: "\(count) problems"))
                                    .font(.caption)
                                    .foregroundStyle(SnapDrillTheme.inkSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(String(localized: "\(subject.name), \(count) saved problems"))
                }
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !environment.proStore.isPro {
                Button {
                    showingPaywall = true
                } label: {
                    PaperCard(padding: 12, background: SnapDrillTheme.inkBlueSoft) {
                        HStack(spacing: 10) {
                            Image(systemName: "text.magnifyingglass")
                                .foregroundStyle(SnapDrillTheme.inkBlue)
                            Text("Upgrade to Pro to search inside photographed question text (OCR)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(SnapDrillTheme.inkBlack)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(SnapDrillTheme.inkBlue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            if searchMatches.isEmpty {
                PaperCard(padding: 24) {
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                        Text("No matching mistakes found")
                            .font(.headline)
                            .foregroundStyle(SnapDrillTheme.inkBlack)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(searchMatches) { item in
                    NavigationLink {
                        MistakeDetailView(mistake: item)
                    } label: {
                        MistakeRowCard(mistake: item, imageStore: environment.imageStore)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func mistakeCount(for subject: Subject) -> Int {
        visibleMistakes.filter { $0.subject?.id == subject.id }.count
    }
}

/// Shared thumbnail + metadata row reused by Home search and MistakeListView.
struct MistakeRowCard: View {
    let mistake: MistakeItem
    let imageStore: MistakeImageStore

    var body: some View {
        PaperCard(padding: 12) {
            HStack(spacing: 12) {
                MistakeThumbnailImage(
                    mistake: mistake,
                    imageStore: imageStore
                )
                .frame(width: 82, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        if let subject = mistake.subject {
                            Circle()
                                .fill(Color(hexString: subject.colorHex))
                                .frame(width: 8, height: 8)
                            Text(subject.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SnapDrillTheme.inkBlue)
                        }

                        if !mistake.sourceTitle.isEmpty {
                            Text("· \(mistake.sourceTitle)")
                                .font(.caption)
                                .foregroundStyle(SnapDrillTheme.inkSecondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 4)

                        Image(systemName: mistake.mastery.symbolName)
                            .font(.caption)
                            .foregroundStyle(masteryColor)
                    }

                    if !mistake.notes.isEmpty {
                        Text(mistake.notes)
                            .font(.subheadline)
                            .foregroundStyle(SnapDrillTheme.inkBlack)
                            .lineLimit(2)
                    } else if !mistake.ocrText.isEmpty {
                        Text(mistake.ocrText.replacingOccurrences(of: "\n", with: " "))
                            .font(.subheadline)
                            .foregroundStyle(SnapDrillTheme.inkBlack)
                            .lineLimit(2)
                    } else {
                        Text("Tap to inspect or add notes")
                            .font(.subheadline)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    }

                    HStack(spacing: 6) {
                        if let firstCause = mistake.causes.first {
                            Text(firstCause.localizedTitle)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(SnapDrillTheme.gradingRed)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(SnapDrillTheme.gradingRedSoft, in: Capsule())
                        }
                        ForEach(mistake.tagList.prefix(2)) { tag in
                            Text("#\(tag.name)")
                                .font(.caption2)
                                .foregroundStyle(SnapDrillTheme.inkSecondary)
                        }
                        Spacer(minLength: 0)
                        Text(mistake.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    }
                }
            }
        }
    }

    private var masteryColor: Color {
        switch mistake.mastery {
        case .unknown: return SnapDrillTheme.inkSecondary
        case .fuzzy: return SnapDrillTheme.pencilYellow
        case .mastered: return SnapDrillTheme.masteryGreen
        }
    }
}

/// Thumbnail loader reading local disk cache or CloudKit-synced externalStorage bytes.
struct MistakeThumbnailImage: View {
    let mistake: MistakeItem
    let imageStore: MistakeImageStore

    var body: some View {
        Group {
            if let data = mistake.resolvedCleanedImageData(imageStore: imageStore),
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    SnapDrillTheme.elevatedSurface
                    Image(systemName: "doc.text.image")
                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                }
            }
        }
    }
}
