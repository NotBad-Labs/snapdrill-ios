//
//  CustomSubjectEditorView.swift
//  NotBad
//
//  自定义学科编辑视图
//

import SwiftUI

// MARK: - CustomSubjectEditorView

/// 自定义学科编辑视图
///
/// 用于创建或编辑自定义学科。
struct CustomSubjectEditorView: View {
    
    // MARK: - Mode
    
    enum Mode: Identifiable {
        case add
        case edit(CustomSubject)
        
        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let subject): return subject.id.uuidString
            }
        }
    }
    
    // MARK: - Properties
    
    let mode: Mode
    
    @StateObject private var profileManager = UserProfileManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "book.fill"
    @State private var selectedColor: Color = .blue
    @State private var selectedCategory: SubjectCategory = .humanities
    @State private var applicableStages: Set<GradeStage> = Set(GradeStage.allCases)
    
    @State private var showingIconPicker = false
    
    // MARK: - Available Icons
    
    private let availableIcons: [String] = [
        // 书籍和学习
        "book.fill", "books.vertical.fill", "text.book.closed.fill",
        "bookmark.fill", "graduationcap.fill", "backpack.fill",
        
        // 科学
        "atom", "flask.fill", "testtube.2", "chart.bar.fill",
        "function", "sum", "divide", "multiply",
        
        // 艺术
        "paintbrush.fill", "paintpalette.fill", "music.note",
        "guitars.fill", "pianokeys", "theatermasks.fill",
        
        // 运动
        "figure.run", "sportscourt.fill", "basketball.fill",
        "soccerball", "tennis.racket", "figure.swimming",
        
        // 语言
        "globe", "character.book.closed.fill", "abc",
        "textformat.abc", "bubble.left.and.bubble.right.fill",
        
        // 技术
        "desktopcomputer", "laptopcomputer", "keyboard.fill",
        "cpu.fill", "memorychip.fill", "network",
        
        // 自然
        "leaf.fill", "tree.fill", "cloud.sun.fill",
        "mountain.2.fill", "water.waves", "sparkles",
        
        // 其他
        "star.fill", "heart.fill", "lightbulb.fill",
        "puzzlepiece.fill", "flag.fill", "mappin.and.ellipse"
    ]
    
    // MARK: - Available Colors
    
    private let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown
    ]
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !applicableStages.isEmpty
    }
    
    private var navigationTitle: LocalizedStringKey {
        switch mode {
        case .add: return "custom_subject_add_title"
        case .edit: return "custom_subject_edit_title"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // 名称输入
                Section {
                    TextField("custom_subject_name_placeholder", text: $name)
                        .onSubmit {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                } header: {
                    Text("custom_subject_name_section")
                }
                
                // 图标选择
                Section {
                    Button {
                        showingIconPicker = true
                    } label: {
                        HStack {
                            Text("custom_subject_icon")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .foregroundStyle(selectedColor)
                                .frame(width: DesignTokens.IconSize.xl, height: DesignTokens.IconSize.xl)
                                .background(selectedColor.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                } header: {
                    Text("custom_subject_appearance_section")
                }
                
                // 颜色选择
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedColor = color
                                }
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: DesignTokens.IconSize.md, height: DesignTokens.IconSize.md)
                                    .overlay {
                                        if color == selectedColor {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("custom_subject_color_section")
                }
                
                // 分类选择
                Section {
                    Picker("custom_subject_category", selection: $selectedCategory) {
                        ForEach(SubjectCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                } header: {
                    Text("custom_subject_category_section")
                }
                
                // 适用学段选择
                Section {
                    ForEach(GradeStage.allCases) { stage in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                if applicableStages.contains(stage) {
                                    // 至少保留一个学段
                                    if applicableStages.count > 1 {
                                        applicableStages.remove(stage)
                                    }
                                } else {
                                    applicableStages.insert(stage)
                                }
                            }
                        } label: {
                            HStack {
                                Text(stage.displayName)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if applicableStages.contains(stage) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.brand.primary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("custom_subject_stages_section")
                } footer: {
                    Text("custom_subject_stages_footer")
                        .font(.caption)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("common_save") {
                        saveSubject()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(
                    availableIcons: availableIcons,
                    selectedIcon: $selectedIcon,
                    selectedColor: selectedColor
                )
            }
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadExistingData() {
        if case .edit(let subject) = mode {
            name = subject.name
            selectedIcon = subject.icon
            selectedColor = subject.color
            selectedCategory = subject.category
            applicableStages = subject.applicableStages
        }
    }
    
    private func saveSubject() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch mode {
        case .add:
            let newSubject = CustomSubject(
                name: trimmedName,
                icon: selectedIcon,
                colorHex: selectedColor.toHex() ?? "#007AFF",
                category: selectedCategory,
                applicableStages: applicableStages
            )
            profileManager.addCustomSubject(newSubject)
            
        case .edit(var existingSubject):
            existingSubject.name = trimmedName
            existingSubject.icon = selectedIcon
            existingSubject.colorHex = selectedColor.toHex() ?? "#007AFF"
            existingSubject.category = selectedCategory
            existingSubject.applicableStages = applicableStages
            profileManager.updateCustomSubject(existingSubject)
        }
    }
}

// MARK: - IconPickerView

/// 图标选择视图
private struct IconPickerView: View {
    let availableIcons: [String]
    @Binding var selectedIcon: String
    let selectedColor: Color
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedIcon = icon
                            }
                            dismiss()
                        } label: {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(icon == selectedIcon ? .white : selectedColor)
                                .frame(width: 50, height: 50)
                                .background(icon == selectedIcon ? selectedColor : selectedColor.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay {
                                    if icon == selectedIcon {
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(selectedColor, lineWidth: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("custom_subject_icon_picker_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common_done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview("Add") {
    CustomSubjectEditorView(mode: .add)
}

#Preview("Edit") {
    CustomSubjectEditorView(mode: .edit(CustomSubject(
        name: "信息技术",
        icon: "desktopcomputer",
        colorHex: "#007AFF",
        category: .science,
        applicableStages: [.junior, .senior]
    )))
}
