import SwiftData
import SwiftUI

enum MistakeListFilter: Hashable {
    case all
    case subject(Subject)
}

struct MistakeListView: View {
    let filter: MistakeListFilter

    @Environment(\.modelContext) private var context
    @Query(sort: \MistakeItem.createdAt, order: .reverse) private var mistakes: [MistakeItem]
    @State private var viewMode: ViewMode = .grid
    @State private var filterState = MistakeListFilterState()
    @State private var showFilters = false

    private var scoped: [MistakeItem] {
        switch filter {
        case .all:
            return mistakes
        case .subject(let subject):
            return mistakes.filter { $0.subject?.id == subject.id }
        }
    }

    private var filtered: [MistakeItem] {
        scoped.filter { item in
            if filterState.onlyDemo, !item.isDemoSample { return false }
            if !filterState.causeFilter.isEmpty {
                guard item.causes.contains(where: { filterState.causeFilter.contains($0) }) else { return false }
            }
            if !filterState.masteryFilter.isEmpty, !filterState.masteryFilter.contains(item.mastery) {
                return false
            }
            return true
        }
    }

    var body: some View {
        Group {
            if filtered.isEmpty {
                ContentUnavailableView(
                    String(localized: "No mistakes yet"),
                    systemImage: "doc.text",
                    description: Text(String(localized: "Capture from the camera button."))
                )
            } else {
                switch viewMode {
                case .list:
                    List(filtered) { item in
                        NavigationLink {
                            MistakeDetailView(item: item)
                        } label: {
                            MistakeRow(item: item)
                        }
                    }
                case .grid:
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                            ForEach(filtered) { item in
                                NavigationLink {
                                    MistakeDetailView(item: item)
                                } label: {
                                    MistakeGridCell(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: filterState.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewMode.toggle()
                } label: {
                    Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    NavigationLink {
                        ReviewSessionView(items: filtered)
                    } label: {
                        Label(String(localized: "Review list"), systemImage: "rectangle.stack")
                    }
                    NavigationLink {
                        PDFExportShellView(mistakeCount: filtered.count)
                    } label: {
                        Label(String(localized: "Export PDF"), systemImage: "doc.richtext")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(filtered.isEmpty)
            }
        }
        .sheet(isPresented: $showFilters) {
            MistakeListFilterSheet(state: $filterState)
        }
        .paperBackground()
    }

    private var title: String {
        switch filter {
        case .all: String(localized: "All mistakes")
        case .subject(let subject): subject.name
        }
    }
}

private enum ViewMode {
    case list
    case grid

    mutating func toggle() {
        self = self == .list ? .grid : .list
    }
}

private struct MistakeRow: View {
    let item: MistakeItem

    var body: some View {
        HStack(spacing: 12) {
            MistakeThumbnail(item: item)
                .frame(width: 52, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(item.subject?.name ?? SubjectCatalog.uncategorizedName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
            }
        }
    }
}

private struct MistakeGridCell: View {
    let item: MistakeItem

    var body: some View {
        VStack(spacing: 8) {
            MistakeThumbnail(item: item)
                .aspectRatio(3 / 4, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(item.subject?.name ?? "—")
                .font(.caption)
                .lineLimit(1)
        }
    }
}