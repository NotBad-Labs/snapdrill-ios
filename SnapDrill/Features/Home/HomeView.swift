import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query(sort: \MistakeItem.createdAt, order: .reverse) private var allMistakes: [MistakeItem]

    private var visibleSubjects: [Subject] {
        subjects.filter { subject in
            if subject.isUncategorizedBucket {
                return !subject.mistakes.isEmpty
            }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if allMistakes.isEmpty && visibleSubjects.allSatisfy({ $0.mistakeCount == 0 }) {
                    EmptyNotebookView()
                        .padding(.top, 48)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        NavigationLink {
                            MistakeListView(filter: .all)
                        } label: {
                            AllMistakesCard(count: allMistakes.count)
                        }
                        .buttonStyle(.plain)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(visibleSubjects.filter { !$0.isUncategorizedBucket }) { subject in
                                NavigationLink {
                                    MistakeListView(filter: .subject(subject))
                                } label: {
                                    SubjectCard(subject: subject)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(String(localized: "SnapDrill"))
            .paperBackground()
        }
    }
}

private struct AllMistakesCard: View {
    let count: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "All mistakes"))
                    .font(.headline)
                Text("\(count)")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SnapDrillTheme.inkBlue)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct SubjectCard: View {
    let subject: Subject

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Circle()
                .fill(Color(hex: subject.colorHex))
                .frame(width: 12, height: 12)
            Text(subject.name)
                .font(.headline)
                .foregroundStyle(SnapDrillTheme.inkBlack)
            Text("\(subject.mistakeCount)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct EmptyNotebookView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 48))
                .foregroundStyle(SnapDrillTheme.inkBlue.opacity(0.7))
            Text(String(localized: "Snap your first mistake"))
                .font(.title3.weight(.medium))
            Text(String(localized: "Tap Capture below — like taking a photo, not copying by hand."))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}