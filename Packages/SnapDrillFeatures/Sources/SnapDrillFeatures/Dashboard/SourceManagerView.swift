//
//  SourceManagerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/01/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  来源管理视图，允许用户添加、删除或重命名来源。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

struct SourceManagerView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(\.repositories) private var repositories

    @State private var viewModel: SourceManagerViewModel?

    @State private var showingAddSheet = false
    @State private var editingSource: SourceModel?

    // MARK: - Body

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
            .alert("无法删除", isPresented: Binding(
                get: { viewModel?.isDeletingInUse ?? false },
                set: { newValue in viewModel?.isDeletingInUse = newValue }
            )) {
                Button("好", role: .cancel) { }
            } message: {
                Text("来源「\(viewModel?.pendingDeletionName ?? "")」下仍有题目，请先将题目移动到其他来源或删除对应题目。")
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
                EditSourceView(source: nil, viewModel: viewModel)
            }
            .sheet(item: $editingSource) { source in
                EditSourceView(source: source, viewModel: viewModel)
            }
            .task {
                if viewModel == nil {
                    viewModel = SourceManagerViewModel(repositories: repositories)
                }
                viewModel?.loadData()
            }
        }
    }
}

struct EditSourceView: View {
    @Environment(\.dismiss) private var dismiss

    /// 如果为 nil，则为添加模式；否则为编辑模式
    let source: SourceModel?
    let viewModel: SourceManagerViewModel?

    @State private var name: String = ""
    @State private var selectedIcon: String = "doc.text"
    @State private var selectedColorHex: String = "#808080"
    @State private var customColor: Color = .gray
    @State private var useCustomColor: Bool = false
    @State private var showSymbolPicker: Bool = false

    let colors = ["#E57373", "#4FC3F7", "#AED581", "#7986CB", "#F06292", "#FFB74D", "#9575CD", "#90A4AE", "#808080"]

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
                if let source {
                    name = source.name
                    selectedIcon = source.icon
                    selectedColorHex = source.colorHex

                    if !colors.contains(source.colorHex) {
                        customColor = Color(hex: source.colorHex)
                        useCustomColor = true
                    }
                    if source.colorHex.isEmpty {
                        selectedColorHex = "#808080"
                    }
                }
            }
        }
    }

    private var finalColorHex: String {
        if useCustomColor {
            return customColor.toHex() ?? "#808080"
        } else {
            return selectedColorHex
        }
    }

    func saveSource() {
        viewModel?.saveSource(
            source: source,
            name: name.trimmingCharacters(in: .whitespaces),
            selectedIcon: selectedIcon,
            finalColorHex: finalColorHex
        )
    }
}

#Preview {
    SourceManagerView()
}
