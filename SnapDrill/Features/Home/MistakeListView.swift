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

    private var filtered: [MistakeItem] {
        switch filter {
        case .all:
            return mistakes
        case .subject(let subject):
            return mistakes.filter { $0.subject?.id == subject.id }
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
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewMode.toggle()
                } label: {
                    Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ReviewSessionView(items: filtered)
                } label: {
                    Text(String(localized: "Review list"))
                }
            }
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
        VStack(alignment: .leading, spacing: 4) {
            Text(item.subject?.name ?? SubjectCatalog.uncategorizedName)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
        }
    }
}

private struct MistakeGridCell: View {
    let item: MistakeItem

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.15))
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay {
                    Image(systemName: "doc.text.image")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            Text(item.subject?.name ?? "—")
                .font(.caption)
                .lineLimit(1)
        }
    }
}