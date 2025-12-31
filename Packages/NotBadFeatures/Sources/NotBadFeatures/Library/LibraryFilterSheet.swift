//
//  LibraryFilterSheet.swift
//  NotBadFeatures
//
//  Created by NotBad Architect on 2025/12/31.
//

import SwiftUI
import NotBadData
import NotBadCore
import SwiftData

struct LibraryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedSubjects: Set<String>
    @Binding var selectedTags: Set<String>
    
    @Query(sort: \TagModel.name) private var allTags: [TagModel]
    
    var onReset: () -> Void
    var onApply: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                // Section: Subjects
                Section("学科") {
                    ForEach(SubjectPreset.allCases) { subject in
                        HStack {
                            Text(subject.rawValue)
                            Spacer()
                            if selectedSubjects.contains(subject.rawValue) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedSubjects.contains(subject.rawValue) {
                                selectedSubjects.remove(subject.rawValue)
                            } else {
                                selectedSubjects.insert(subject.rawValue)
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
