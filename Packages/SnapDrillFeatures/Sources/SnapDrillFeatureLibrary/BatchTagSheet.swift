//
//  BatchTagSheet.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  批量打标签 Sheet，为选中的题目批量添加标签。
//

import SwiftUI
import SnapDrillCore

/// 批量打标签选择面板
///
/// 列出所有已有标签，用户选择后批量添加到选中题目。
struct BatchTagSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: LibraryViewModel
    let selectedItemIDs: Set<UUID>

    @State private var selectedTagNames: Set<String> = []

    var body: some View {
        NavigationStack {
            Form {
                if viewModel.tagValues.isEmpty {
                    Section {
                        Text(L10n.Library.noTags)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        ForEach(viewModel.tagValues) { tag in
                            Button {
                                if selectedTagNames.contains(tag.name) {
                                    selectedTagNames.remove(tag.name)
                                } else {
                                    selectedTagNames.insert(tag.name)
                                }
                            } label: {
                                HStack {
                                    Text(tag.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedTagNames.contains(tag.name) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("library.batchTag.value.\(tag.name)")
                            .accessibilityAddTraits(selectedTagNames.contains(tag.name) ? .isSelected : [])
                        }
                    } header: {
                        Text(L10n.Library.batchTagHint(selectedItemIDs.count))
                    }
                }
            }
            .accessibilityIdentifier("library.batchTag.root")
            .navigationTitle(L10n.Library.batchTag)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        Task {
                            await viewModel.addTagsToItems(ids: selectedItemIDs, tagNames: selectedTagNames)
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("library.batchTag.done")
                    .disabled(selectedTagNames.isEmpty)
                }
            }
        }
    }
}
