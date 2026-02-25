//
//  SourceManagerView.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/01/01.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  来源管理视图，允许用户添加、删除或重命名来源。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

struct SourceManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.repositories) private var repos
    
    @State private var viewModel: SourceManagerViewModel?
    
    @State private var showingAddSheet = false
    @State private var editingSource: SourceModel?
    
    var body: some View {
        NavigationStack {
            List {
                if let vm = viewModel {
                    ForEach(vm.sources) { source in
                        Button {
                            editingSource = source
                        } label: {
                            HStack {
                                Image(systemName: source.icon)
                                    .foregroundStyle(Color(hex: source.colorHex))
                                    .frame(width: 24)
                                Text(source.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onDelete(perform: { offsets in vm.delete(at: offsets) })
                }
            }
            .navigationTitle("管理来源")
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
                EditSourceView(source: nil)
            }
            .sheet(item: $editingSource) { source in
                EditSourceView(source: source)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = SourceManagerViewModel(repository: repos.source)
                }
                viewModel?.loadData()
            }
        }
    }
}

struct EditSourceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.repositories) private var repos
    
    /// 如果为 nil，则为添加模式；否则为编辑模式
    let source: SourceModel?
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "doc.text" // Default icon for source
    @State private var selectedColorHex: String = "#808080" // Default gray
    @State private var customColor: Color = .gray
    @State private var useCustomColor: Bool = false
    @State private var showSymbolPicker: Bool = false
    
    let colors = ["#E57373", "#4FC3F7", "#AED581", "#7986CB", "#F06292", "#FFB74D", "#9575CD", "#90A4AE", "#808080"]
    // Source related icons
    let icons = [
        "doc.text", "pencil.and.list.clipboard", "book.closed", "xmark.bin",
        "questionmark.circle", "desktopcomputer", "video", "person.2",
        "building.columns", "graduationcap", "globe", "bubble.left"
    ]
    
    private var isEditing: Bool { source != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("来源名称") {
                    TextField("例如：网课", text: $name)
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
            .navigationTitle(isEditing ? "编辑来源" : "添加来源")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveSource()
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
                if let source {
                    name = source.name
                    selectedIcon = source.icon
                    selectedColorHex = source.colorHex
                    
                    // 检查是否为预设颜色
                    if !colors.contains(source.colorHex) {
                        // 非预设颜色，设置为自定义颜色
                        customColor = Color(hex: source.colorHex)
                        useCustomColor = true
                    }
                    // 如果是默认未设置颜色，可能是旧数据，初始化
                    if source.colorHex.isEmpty {
                        selectedColorHex = "#808080"
                    }
                }
            }
        }
    }
    
    /// 获取最终选择的颜色 Hex
    private var finalColorHex: String {
        if useCustomColor {
            return customColor.toHex() ?? "#808080"
        } else {
            return selectedColorHex
        }
    }
    
    func saveSource() {
        let repo = repos.source
        if let source {
            // 编辑模式：更新现有来源
            do {
                try repo.update(source, name: name.trimmingCharacters(in: .whitespaces), icon: selectedIcon, colorHex: finalColorHex)
            } catch {
                SnapDrillLogger.generic.info("Failed to update source: \(error.localizedDescription)")
            }
        } else {
            // 添加模式：创建新来源
            do {
                try repo.add(name: name.trimmingCharacters(in: .whitespaces), icon: selectedIcon, colorHex: finalColorHex)
            } catch {
                // 如果失败（如重复），静默失败或显示错误
                SnapDrillLogger.generic.info("Failed to add source: \(error.localizedDescription)")
            }
        }
    }
}

#Preview("Manager") {
    // Mock Env
    Text("Need Context")
}
