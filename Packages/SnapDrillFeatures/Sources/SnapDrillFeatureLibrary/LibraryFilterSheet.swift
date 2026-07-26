//
//  LibraryFilterSheet.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  资料筛选页，提供动态维度过滤能力。
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
                // 动态维度（分类/来源/级别/标签 + 用户自定义），每维度一段；维度间 AND、维度内 OR
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
                                .accessibilityIdentifier("filter.value.\(value.name)")
                                .accessibilityAddTraits(
                                    viewModel.isFilterSelected(value.id, inDimension: dimension.id) ? .isSelected : []
                                )
                            }
                        }
                    }
                }
            }
            .accessibilityIdentifier("library.filter.root")
            .navigationTitle(L10n.Library.filter)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.reset) {
                        viewModel.resetFilters()
                        dismiss()
                    }
                    .accessibilityIdentifier("library.filter.reset")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        dismiss()
                    }
                    .accessibilityIdentifier("library.filter.done")
                }
            }
        }
    }
}
