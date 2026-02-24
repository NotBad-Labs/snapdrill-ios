//
//  SubjectManagerView.swift
//  NotBadFeatureDashboard
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  学科管理视图，允许用户添加、删除或重命名学科。
//

import SwiftUI
import SwiftData
import NotBadData
import NotBadUI

// Keep existing SubjectManagerView ...
struct SubjectManagerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: \SubjectModel.sortOrder) var subjects: [SubjectModel]
    
    @State private var showingAddSheet = false
    @State private var editingSubject: SubjectModel?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(subjects) { subject in
                    Button {
                        editingSubject = subject
                    } label: {
                        HStack {
                            Image(systemName: subject.icon)
                                .foregroundStyle(Color(hex: subject.colorHex))
                                .frame(width: 24)
                            Text(subject.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .onDelete(perform: deleteSubject)
            }
            .navigationTitle("管理学科")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }, label: {
                        Image(systemName: "plus")
                    })
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                EditSubjectView(subject: nil)
            }
            .sheet(item: $editingSubject) { subject in
                EditSubjectView(subject: subject)
            }
        }
    }
    
    func deleteSubject(at offsets: IndexSet) {
        for index in offsets {
            let subject = subjects[index]
            modelContext.delete(subject)
        }
    }
}

/// 统一的添加/编辑学科视图
struct EditSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    /// 如果为 nil，则为添加模式；否则为编辑模式
    let subject: SubjectModel?
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "book"
    @State private var selectedColorHex: String = "#4FC3F7"
    @State private var customColor: Color = .blue
    @State private var useCustomColor: Bool = false
    @State private var showSymbolPicker: Bool = false
    
    let colors = ["#E57373", "#4FC3F7", "#AED581", "#7986CB", "#F06292", "#FFB74D", "#9575CD", "#90A4AE"]
    let icons = [
        "book", "text.book.closed", "function", "character.book.closed",
        "atom", "flask", "leaf", "scroll", "globe", "paintbrush",
        "music.note", "sportscourt", "gamecontroller", "camera", "heart", "star"
    ]
    
    private var isEditing: Bool { subject != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("学科名称") {
                    TextField("例如：微积分", text: $name)
                }
                
                Section("选择图标") {
                    Button {
                        showSymbolPicker = true
                    } label: {
                        HStack {
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .frame(width: 32, height: 32)
                                .foregroundStyle(useCustomColor ? customColor : Color(hex: selectedColorHex))
                            
                            Text(selectedIcon)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text("更多图标")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                
                Section("选择颜色") {
                    // 预设颜色
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: (!useCustomColor && selectedColorHex == hex) ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColorHex = hex
                                    useCustomColor = false
                                }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // 自定义颜色
                    HStack {
                        Text("自定义颜色")
                        Spacer()
                        ColorPicker("", selection: $customColor, supportsOpacity: false)
                            .labelsHidden()
                            .onChange(of: customColor) { _, _ in
                                useCustomColor = true
                            }
                        
                        if useCustomColor {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑学科" : "添加学科")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveSubject()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showSymbolPicker) {
                SFSymbolPickerView(selectedSymbol: $selectedIcon)
            }
            .onAppear {
                // 如果是编辑模式，加载现有数据
                if let subject {
                    name = subject.name
                    selectedIcon = subject.icon
                    selectedColorHex = subject.colorHex
                    
                    // 检查是否为预设颜色
                    if !colors.contains(subject.colorHex) {
                        // 非预设颜色，设置为自定义颜色
                        customColor = Color(hex: subject.colorHex)
                        useCustomColor = true
                    }
                }
            }
        }
    }
    
    /// 获取最终选择的颜色 Hex
    private var finalColorHex: String {
        if useCustomColor {
            return customColor.toHex() ?? "#4FC3F7"
        } else {
            return selectedColorHex
        }
    }
    
    func saveSubject() {
        if let subject {
            // 编辑模式：更新现有学科
            subject.name = name.trimmingCharacters(in: .whitespaces)
            subject.icon = selectedIcon
            subject.colorHex = finalColorHex
        } else {
            // 添加模式：创建新学科
            let repo = SubjectRepository(modelContext: modelContext)
            do {
                try repo.add(name: name.trimmingCharacters(in: .whitespaces), icon: selectedIcon, colorHex: finalColorHex)
            } catch {
                // 如果失败（如重复），静默失败或显示错误
                print("Failed to add subject: \(error.localizedDescription)")
            }
        }
    }
}

#Preview("Manager") {
    SubjectManagerView()
        .modelContainer(for: SubjectModel.self, inMemory: true)
}

#Preview("Add Subject") {
    EditSubjectView(subject: nil)
}

#Preview("Edit Subject") {
    let subject = SubjectModel(name: "数学", icon: "function", colorHex: "#4FC3F7", sortOrder: 0)
    EditSubjectView(subject: subject)
}
