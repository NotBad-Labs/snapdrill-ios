import SwiftData
import SwiftUI

private enum MistakeListLayout: String {
    case list
    case grid
}

/// Browseable, filterable, multi-selectable list/grid of mistakes inside a subject or across all subjects (PRD §8.3, F-31..34).
struct MistakeListView: View {
    let subject: Subject?

    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var environment

    @Query(sort: \MistakeItem.createdAt, order: .reverse) private var allMistakes: [MistakeItem]
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]

    @State private var criteria = MistakeFilterCriteria()
    @State private var layout: MistakeListLayout = .list
    @State private var showingFilterSheet = false
    @State private var isSelecting = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var showingBatchMoveSheet = false
    @State private var exportBatchMistakes: [MistakeItem]?
    @State private var reviewBatchMistakes: [MistakeItem]?

    private var filteredMistakes: [MistakeItem] {
        var active = criteria
        if let subject {
            active.subjectIDs = [subject.id]
        }
        active.includeOCRTextSearch = environment.proStore.isPro
        let nonDeleted = allMistakes.filter { !environment.pendingDeletionIDs.contains($0.id) }
        return MistakeFilterEngine.filter(nonDeleted, using: active)
    }

    private var selectedMistakes: [MistakeItem] {
        filteredMistakes.filter { selectedIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterControlStrip
                .padding(.horizontal, SnapDrillTheme.screenPadding)
                .padding(.vertical, 8)

            if filteredMistakes.isEmpty {
                Spacer()
                PaperCard(padding: 24) {
                    VStack(spacing: 12) {
                        PandaMascotView(mood: .welcoming, size: 96)
                        Text("No mistakes match these filters")
                            .font(.headline)
                            .foregroundStyle(SnapDrillTheme.inkBlack)
                        if criteria.hasActiveModifiers {
                            Button("Clear Filters") {
                                criteria = MistakeFilterCriteria()
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SnapDrillTheme.inkBlue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, SnapDrillTheme.screenPadding)
                Spacer()
            } else {
                contentView
            }

            if isSelecting && !selectedMistakes.isEmpty {
                batchActionBar
            }
        }
        .paperBackground()
        .navigationTitle(subject?.name ?? String(localized: "All Mistakes"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $criteria.searchQuery,
            prompt: environment.proStore.isPro
                ? Text("Search question text, notes, or tags")
                : Text("Search notes or tags")
        )
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !filteredMistakes.isEmpty && !isSelecting {
                    Button {
                        // PRD §8.4: Inherit exact current list filter results directly into review
                        reviewBatchMistakes = filteredMistakes
                    } label: {
                        Label("Review", systemImage: "play.rectangle.fill")
                    }
                    .accessibilityLabel(String(localized: "Review Current List"))
                }

                Menu {
                    Button {
                        layout = layout == .list ? .grid : .list
                    } label: {
                        Label(
                            layout == .list ? String(localized: "Grid View") : String(localized: "List View"),
                            systemImage: layout == .list ? "square.grid.2x2" : "list.bullet"
                        )
                    }

                    Button {
                        isSelecting.toggle()
                        if !isSelecting { selectedIDs.removeAll() }
                    } label: {
                        Label(
                            isSelecting ? String(localized: "Done Selecting") : String(localized: "Select Multiple"),
                            systemImage: isSelecting ? "checkmark.circle" : "checkmark.circle.badge.plus"
                        )
                    }

                    if !filteredMistakes.isEmpty {
                        Button {
                            exportBatchMistakes = filteredMistakes
                        } label: {
                            Label("Export All Filtered as PDF", systemImage: "doc.richtext")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel(String(localized: "More Actions"))
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            MistakeListFilterSheet(criteria: $criteria)
        }
        .sheet(isPresented: Binding(
            get: { exportBatchMistakes != nil },
            set: { if !$0 { exportBatchMistakes = nil } }
        )) {
            if let items = exportBatchMistakes {
                PDFExportPreviewView(
                    mistakes: items,
                    defaultTitle: PDFExportOptions.defaultTitle(subjectName: subject?.name)
                )
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { reviewBatchMistakes != nil },
            set: { if !$0 { reviewBatchMistakes = nil } }
        )) {
            if let items = reviewBatchMistakes {
                ReviewSessionView(mistakes: items) {
                    reviewBatchMistakes = nil
                }
            }
        }
        .confirmationDialog(
            String(localized: "Move Selected to Subject"),
            isPresented: $showingBatchMoveSheet,
            titleVisibility: .visible
        ) {
            ForEach(subjects.filter { !$0.isUncategorizedBucket }) { target in
                Button(target.name) {
                    for item in selectedMistakes {
                        item.subject = target
                    }
                    try? modelContext.save()
                    selectedIDs.removeAll()
                    isSelecting = false
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Subviews

    private var filterControlStrip: some View {
        HStack(spacing: 8) {
            Button {
                showingFilterSheet = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("Filter")
                    if criteria.activeFilterBadgeCount > 0 {
                        Text("\(criteria.activeFilterBadgeCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(SnapDrillTheme.inkBlue, in: Capsule())
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(SnapDrillTheme.inkBlack)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(SnapDrillTheme.cardSurface, in: Capsule())
                .overlay(Capsule().strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1))
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(MasteryLevel.allCases) { level in
                        let active = criteria.masteryLevels.contains(level)
                        Button {
                            if active { criteria.masteryLevels.remove(level) }
                            else { criteria.masteryLevels.insert(level) }
                        } label: {
                            Label(level.localizedTitle, systemImage: level.symbolName)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(active ? .white : SnapDrillTheme.inkSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(active ? SnapDrillTheme.inkBlue : SnapDrillTheme.cardSurface)
                                )
                                .overlay(
                                    Capsule().strokeBorder(active ? Color.clear : SnapDrillTheme.ruledLine, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if layout == .list {
            List {
                ForEach(filteredMistakes) { mistake in
                    HStack(spacing: 10) {
                        if isSelecting {
                            Image(systemName: selectedIDs.contains(mistake.id) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(selectedIDs.contains(mistake.id) ? SnapDrillTheme.inkBlue : SnapDrillTheme.inkSecondary)
                        }

                        if isSelecting {
                            MistakeRowCard(mistake: mistake, imageStore: environment.imageStore)
                                .onTapGesture { toggleSelection(mistake.id) }
                        } else {
                            NavigationLink {
                                MistakeDetailView(mistake: mistake)
                            } label: {
                                MistakeRowCard(mistake: mistake, imageStore: environment.imageStore)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            environment.scheduleSoftDelete([mistake], in: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        } else {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                    spacing: 10
                ) {
                    ForEach(filteredMistakes) { mistake in
                        if isSelecting {
                            gridCard(mistake)
                                .onTapGesture { toggleSelection(mistake.id) }
                        } else {
                            NavigationLink {
                                MistakeDetailView(mistake: mistake)
                            } label: {
                                gridCard(mistake)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, SnapDrillTheme.screenPadding)
                .padding(.bottom, 108)
            }
        }
    }

    private func gridCard(_ mistake: MistakeItem) -> some View {
        PaperCard(padding: 8) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    MistakeThumbnailImage(
                        mistake: mistake,
                        imageStore: environment.imageStore
                    )
                    .frame(height: 112)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    if isSelecting {
                        Image(systemName: selectedIDs.contains(mistake.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedIDs.contains(mistake.id) ? SnapDrillTheme.inkBlue : .white)
                            .padding(6)
                    }
                }

                Text(mistake.notes.isEmpty ? (mistake.subject?.name ?? String(localized: "Mistake")) : mistake.notes)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SnapDrillTheme.inkBlack)
                    .lineLimit(2)

                HStack {
                    Text(mistake.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                    Spacer()
                    Image(systemName: mistake.mastery.symbolName)
                        .font(.caption2)
                        .foregroundStyle(SnapDrillTheme.inkBlue)
                }
            }
        }
    }

    private var batchActionBar: some View {
        HStack(spacing: 16) {
            Button {
                exportBatchMistakes = selectedMistakes
            } label: {
                Label("PDF", systemImage: "doc.richtext")
            }

            Spacer()

            Button {
                showingBatchMoveSheet = true
            } label: {
                Label("Move", systemImage: "folder")
            }

            Spacer()

            Button(role: .destructive) {
                environment.scheduleSoftDelete(selectedMistakes, in: modelContext)
                selectedIDs.removeAll()
                isSelecting = false
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(SnapDrillTheme.cardSurface)
        .overlay(alignment: .top) { RuledDivider() }
        .padding(.bottom, 54)
    }

    private func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
}
