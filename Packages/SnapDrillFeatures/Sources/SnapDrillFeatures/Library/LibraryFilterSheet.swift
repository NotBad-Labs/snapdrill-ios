//
//  LibraryFilterSheet.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2025/12/31.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  题库筛选页，提供多维度（学科、标签、日期）过滤能力。
//

import SwiftUI
import SnapDrillUI
import SnapDrillCore

struct LibraryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: LibraryViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                // Section: Subjects (动态从 SwiftData 获取)
                Section("学科") {
                    if viewModel.subjects.isEmpty {
                        Text("暂无学科").foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.subjects) { subject in
                            HStack {
                                Image(systemName: subject.icon)
                                    .foregroundStyle(Color(hex: subject.colorHex))
                                    .frame(width: 20)
                                Text(subject.name)
                                Spacer()
                                if viewModel.selectedSubjects.contains(subject.name) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if viewModel.selectedSubjects.contains(subject.name) {
                                    viewModel.selectedSubjects.remove(subject.name)
                                } else {
                                    viewModel.selectedSubjects.insert(subject.name)
                                }
                            }
                        }
                    }
                }
                
                // Section: Tags
                Section("标签") {
                    if viewModel.allTags.isEmpty {
                        Text("暂无标签").foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.allTags) { tag in
                            HStack {
                                Text(tag.name)
                                Spacer()
                                if viewModel.selectedTags.contains(tag.name) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if viewModel.selectedTags.contains(tag.name) {
                                    viewModel.selectedTags.remove(tag.name)
                                } else {
                                    viewModel.selectedTags.insert(tag.name)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("重置") {
                        viewModel.resetFilters()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LibraryFilterSheet(
        viewModel: LibraryViewModel(
            reviewRepo: PreviewRepositoryContainer().review,
            subjectRepo: PreviewRepositoryContainer().subject,
            tagRepo: PreviewRepositoryContainer().tag
        )
    )
}
