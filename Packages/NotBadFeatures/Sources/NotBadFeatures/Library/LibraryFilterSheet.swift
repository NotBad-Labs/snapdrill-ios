//
//  LibraryFilterSheet.swift
//  NotBadFeatures
//
//  Created by NotBad Architect on 2025/12/31.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  题库筛选页，提供多维度（学科、标签、日期）过滤能力。
//

import SwiftUI
import NotBadData
import NotBadCore
import SwiftData

struct LibraryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedSubjects: Set<String>
    @Binding var selectedTags: Set<String>
    
    @Query(sort: \SubjectModel.sortOrder) private var allSubjects: [SubjectModel]
    @Query(sort: \TagModel.name) private var allTags: [TagModel]
    
    var onReset: () -> Void
    var onApply: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                // Section: Subjects (动态从 SwiftData 获取)
                Section("学科") {
                    if allSubjects.isEmpty {
                        Text("暂无学科").foregroundStyle(.secondary)
                    } else {
                        ForEach(allSubjects) { subject in
                            HStack {
                                Image(systemName: subject.icon)
                                    .foregroundStyle(Color(hex: subject.colorHex))
                                    .frame(width: 20)
                                Text(subject.name)
                                Spacer()
                                if selectedSubjects.contains(subject.name) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedSubjects.contains(subject.name) {
                                    selectedSubjects.remove(subject.name)
                                } else {
                                    selectedSubjects.insert(subject.name)
                                }
                            }
                        }
                    }
                }
                
                // Section: Tags
                Section("标签") {
                    if allTags.isEmpty {
                        Text("暂无标签").foregroundStyle(.secondary)
                    } else {
                        ForEach(allTags) { tag in
                            HStack {
                                Text(tag.name)
                                Spacer()
                                if selectedTags.contains(tag.name) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedTags.contains(tag.name) {
                                    selectedTags.remove(tag.name)
                                } else {
                                    selectedTags.insert(tag.name)
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
                        onReset()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LibraryFilterSheet(
        selectedSubjects: .constant(["Math"]),
        selectedTags: .constant(["Important"]),
        onReset: {},
        onApply: {}
    )
    .modelContainer(for: TagModel.self, inMemory: true)
}
