//
//  SubjectSettingsView.swift
//  NotBad
//
//  学科偏好设置视图
//

import SwiftUI

// MARK: - SubjectSettingsView

/// 学科偏好设置视图
///
/// 允许用户选择在题库筛选栏中显示哪些学科。
struct SubjectSettingsView: View {
    
    // MARK: - Properties
    
    @StateObject private var profileManager = UserProfileManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCustomSubject = false
    @State private var editingCustomSubject: CustomSubject?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // 说明
                Section {
                    Text("subject_settings_description")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // 按分类显示预设学科
                ForEach(SubjectCategory.allCases) { category in
                    let subjectsInCategory = Subject.allCases.filter { $0.category == category }
                    
                    if !subjectsInCategory.isEmpty {
                        Section(category.displayName) {
                            ForEach(subjectsInCategory) { subject in
                                SubjectToggleRow(
                                    subject: subject,
                                    isEnabled: profileManager.isSubjectEnabled(subject),
                                    canDisable: profileManager.enabledSubjects.count > 1 || !profileManager.isSubjectEnabled(subject)
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        profileManager.toggleSubject(subject)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 自定义学科
                Section {
                    ForEach(profileManager.customSubjects) { customSubject in
                        CustomSubjectToggleRow(
                            customSubject: customSubject,
                            isEnabled: profileManager.isCustomSubjectEnabled(customSubject)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                profileManager.toggleCustomSubject(customSubject)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                withAnimation {
                                    profileManager.deleteCustomSubject(id: customSubject.id)
                                }
                            } label: {
                                Label("common_delete", systemImage: "trash")
                            }
                            
                            Button {
                                editingCustomSubject = customSubject
                            } label: {
                                Label("common_edit", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                    .onMove { source, destination in
                        var subjects = profileManager.customSubjects
                        subjects.move(fromOffsets: source, toOffset: destination)
                        profileManager.reorderCustomSubjects(subjects)
                    }
                    
                    // 添加自定义学科按钮
                    Button {
                        showingAddCustomSubject = true
                    } label: {
                        Label("custom_subject_add", systemImage: "plus.circle")
                            .foregroundStyle(Color.brand.primary)
                    }
                } header: {
                    Text("custom_subject_section_title")
                } footer: {
                    Text("custom_subject_section_footer")
                        .font(.caption)
                }
                
                // 快捷操作
                Section {
                    Button {
                        withAnimation {
                            profileManager.resetToDefaultSubjects()
                        }
                    } label: {
                        Label("subject_settings_reset", systemImage: "arrow.counterclockwise")
                    }
                    
                    Button {
                        withAnimation {
                            profileManager.enabledSubjects = Set(Subject.allCases)
                        }
                    } label: {
                        Label("subject_settings_enable_all", systemImage: "checkmark.circle")
                    }
                }
            }
            .navigationTitle("subject_settings_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common_done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddCustomSubject) {
                CustomSubjectEditorView(mode: .add)
            }
            .sheet(item: $editingCustomSubject) { subject in
                CustomSubjectEditorView(mode: .edit(subject))
            }
        }
    }
}

// MARK: - SubjectToggleRow

/// 学科开关行
private struct SubjectToggleRow: View {
    let subject: Subject
    let isEnabled: Bool
    let canDisable: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // 学科图标和名称
                Label {
                    Text(subject.displayName)
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: subject.icon)
                        .foregroundStyle(subject.color)
                }
                
                Spacer()
                
                // 选中状态
                if isEnabled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.brand.primary)
                        .imageScale(.large)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.tertiary)
                        .imageScale(.large)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(canDisable ? 1 : 0.5)
        .disabled(!canDisable && isEnabled)
    }
}

// MARK: - CustomSubjectToggleRow

/// 自定义学科开关行
private struct CustomSubjectToggleRow: View {
    let customSubject: CustomSubject
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // 学科图标和名称
                Label {
                    Text(customSubject.name)
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: customSubject.icon)
                        .foregroundStyle(customSubject.color)
                }
                
                Spacer()
                
                // 选中状态
                if isEnabled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.brand.primary)
                        .imageScale(.large)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.tertiary)
                        .imageScale(.large)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SubjectSettingsView()
}
