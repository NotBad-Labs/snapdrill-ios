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

    private var allFilteredSelected: Bool {
        !filteredMistakes.isEmpty && filteredMistakes.allSatisfy { selectedIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterControlStrip
                .padding(.horizontal, SnapDrillTheme.screenPadding)
                .padding(.vertical, 4)

            if filteredMistakes.isEmpty {
                emptyContent
            } else {
                contentView
            }
        }
        .paperBackground()
        .navigationTitle(subject?.name ?? String(localized: "All Mistakes"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .searchable(
            text: $criteria.searchQuery,
            prompt: environment.proStore.isPro
                ? Text("Search question text, notes, or tags")
                : Text("Search notes or tags")
        )
        .toolbar {
            if isSelecting {
                ToolbarItem(placement: .topBarLeading) {
                    Button(allFilteredSelected ? String(localized: "Deselect All") : String(localized: "Select All")) {
                        if allFilteredSelected {
                            selectedIDs.removeAll()
                        } else {
                            selectedIDs = Set(filteredMistakes.map(\.id))
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isSelecting = false
                        selectedIDs.removeAll()
                    }
                    .fontWeight(.semibold)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        exportBatchMistakes = selectedMistakes
                    } label: {
                        Label("PDF", systemImage: "doc.richtext")
                    }
                    .disabled(selectedMistakes.isEmpty)

                    Spacer()

                    Button {
                        showingBatchMoveSheet = true
                    } label: {
                        Label("Move", systemImage: "folder")
                    }
                    .disabled(selectedMistakes.isEmpty)

                    Spacer()

                    Button(role: .destructive) {
                        environment.scheduleSoftDelete(selectedMistakes, in: modelContext)
                        selectedIDs.removeAll()
                        isSelecting = false
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(selectedMistakes.isEmpty)
                }
            }

            if !isSelecting {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        environment.requestCapture(
                            mode: .cameraDefault,
                            preferredSubjectID: subject?.id
                        )
                    } label: {
                        Label(String(localized: "Capture Mistakes"), systemImage: "camera.viewfinder")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(SnapDrillTheme.inkBlue)
                    .accessibilityLabel(String(localized: "Capture Mistakes"))
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !filteredMistakes.isEmpty {
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
                            isSelecting = true
                        } label: {
                            Label(String(localized: "Select Multiple"), systemImage: "checkmark.circle.badge.plus")
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
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TransientStatusBanners()
        }
        .sheet(isPresented: $showingFilterSheet) {
            MistakeListFilterSheet(criteria: $criteria)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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

    @ViewBuilder
    private var emptyContent: some View {
        if !criteria.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ContentUnavailableView.search(text: criteria.searchQuery)
        } else if criteria.hasActiveModifiers {
            ContentUnavailableView {
                Label("No mistakes match these filters", systemImage: "line.3.horizontal.decrease.circle")
            } actions: {
                Button("Clear Filters") {
                    criteria = MistakeFilterCriteria()
                }
                .buttonStyle(.bordered)
                .tint(SnapDrillTheme.inkBlue)
            }
        } else {
            ContentUnavailableView {
                VStack(spacing: 8) {
                    PandaMascotView(mood: .welcoming, size: 96)
                    Text("No mistakes yet")
                        .font(.title3.weight(.semibold))
                }
            } description: {
                Text("Snap a homework or exam page to add the first one here.")
            } actions: {
                Button {
                    environment.requestCapture(
                        mode: .cameraDefault,
                        preferredSubjectID: subject?.id
                    )
                } label: {
                    Label("Snap a Mistake", systemImage: "camera.viewfinder")
                }
                .buttonStyle(.glassProminent)
                .tint(SnapDrillTheme.inkBlue)
            }
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
                .frame(minHeight: 44)
                .contentShape(Rectangle())
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
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(active ? .isSelected : [])
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
                .padding(.bottom, 16)
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

    private func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
}
