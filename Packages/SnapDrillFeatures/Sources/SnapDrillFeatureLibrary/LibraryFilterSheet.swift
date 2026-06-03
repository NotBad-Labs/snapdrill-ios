//
//  LibraryFilterSheet.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  题库筛选页，提供多维度（学科、标签、日期）过滤能力。
//

import SwiftUI
import SnapDrillUI
import SnapDrillCore

struct LibraryFilterSheet: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: LibraryViewModel
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // 动态维度（学科/来源/年级/标签 + 用户自定义），每维度一段；维度间 AND、维度内 OR
                ForEach(viewModel.dimensions) { dimension in
                    Section(dimension.name) {
                        let values = viewModel.valuesByDimension[dimension.id] ?? []
                        if values.isEmpty {
                            Text(L10n.Library.noItems).foregroundStyle(.secondary)
                        } else {
                            ForEach(values) { value in
                                Button {
                                    viewModel.toggleFilter(value.id, inDimension: dimension.id)
                                } label: {
                                    HStack {
                                        Image(systemName: value.icon)
                                            .foregroundStyle(Color(hex: value.colorHex))
                                            .frame(width: 20)
                                        Text(value.name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if viewModel.isFilterSelected(value.id, inDimension: dimension.id) {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(
                                    viewModel.isFilterSelected(value.id, inDimension: dimension.id) ? .isSelected : []
                                )
                            }
                        }
                    }
                }

                // Section: Difficulty
                Section(L10n.Library.filterDifficulty) {
                    ForEach(Difficulty.allCases) { difficulty in
                        Button {
                            if viewModel.selectedDifficulties.contains(difficulty.rawValue) {
                                viewModel.selectedDifficulties.remove(difficulty.rawValue)
                            } else {
                                viewModel.selectedDifficulties.insert(difficulty.rawValue)
                            }
                        } label: {
                            HStack(spacing: 2) {
                                ForEach(0..<difficulty.starCount, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.orange)
                                        .font(.caption)
                                }
                                Spacer()
                                if viewModel.selectedDifficulties.contains(difficulty.rawValue) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(L10n.Accessibility.starRating(
                            difficulty: difficulty.starCount,
                            maxStars: Difficulty.allCases.count
                        ))
                        .accessibilityAddTraits(viewModel.selectedDifficulties.contains(difficulty.rawValue) ? .isSelected : [])
                    }
                }
            }
            .navigationTitle(L10n.Library.filter)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.reset) {
                        viewModel.resetFilters()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// #Preview {
//     LibraryFilterSheet(
//         viewModel: LibraryViewModel(
//             reviewRepo: PreviewRepositoryContainer().review,
//             subjectRepo: PreviewRepositoryContainer().subject,
//             tagRepo: PreviewRepositoryContainer().tag
//         )
//     )
// }
