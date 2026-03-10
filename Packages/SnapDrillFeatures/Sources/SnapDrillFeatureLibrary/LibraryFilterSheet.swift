//
//  LibraryFilterSheet.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
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
                // Section: Subjects (动态从 SwiftData 获取)
                Section(L10n.Library.filterSubjects) {
                    if viewModel.subjects.isEmpty {
                        Text(L10n.Library.noItems).foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.subjects) { subject in
                            Button {
                                if viewModel.selectedSubjects.contains(subject.name) {
                                    viewModel.selectedSubjects.remove(subject.name)
                                } else {
                                    viewModel.selectedSubjects.insert(subject.name)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: subject.icon)
                                        .foregroundStyle(Color(hex: subject.colorHex))
                                        .frame(width: 20)
                                    Text(subject.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if viewModel.selectedSubjects.contains(subject.name) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Section: Tags
                Section(L10n.Library.filterTags) {
                    if viewModel.allTags.isEmpty {
                        Text(L10n.Library.noItems).foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.allTags) { tag in
                            Button {
                                if viewModel.selectedTags.contains(tag.name) {
                                    viewModel.selectedTags.remove(tag.name)
                                } else {
                                    viewModel.selectedTags.insert(tag.name)
                                }
                            } label: {
                                HStack {
                                    Text(tag.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if viewModel.selectedTags.contains(tag.name) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
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
