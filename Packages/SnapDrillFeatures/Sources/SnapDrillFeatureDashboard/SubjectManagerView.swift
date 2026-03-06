//
//  SubjectManagerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  学科管理视图，允许用户添加、删除或重命名学科。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

public struct SubjectManagerView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(\.repositories) private var repositories

    @State private var viewModel: SubjectManagerViewModel?

    @State private var showingAddSheet = false
    @State private var editingSubject: SubjectModel?

    public init() {}

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            List {
                if let vm = viewModel {
                    ForEach(vm.subjects) { subject in
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
                Text("学科「\(viewModel?.pendingDeletionName ?? "")」下仍有题目，请先将题目移动到其他学科或删除对应题目。")
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
                EditSubjectView(subject: nil, viewModel: viewModel)
            }
            .sheet(item: $editingSubject) { subject in
                EditSubjectView(subject: subject, viewModel: viewModel)
            }
            .task {
                if viewModel == nil {
                    viewModel = SubjectManagerViewModel(repositories: repositories)
                }
                viewModel?.loadData()
            }
        }
    }
}

/// 统一的添加/编辑学科视图
struct EditSubjectView: View {
    @Environment(\.dismiss) private var dismiss

    /// 如果为 nil，则为添加模式；否则为编辑模式
    let subject: SubjectModel?
    let viewModel: SubjectManagerViewModel?

    @State private var name: String = ""
    @State private var selectedIcon: String = "book"
    @State private var selectedColorHex: String = "#4FC3F7"
    @State private var customColor: Color = .blue
    @State private var useCustomColor: Bool = false
    @State private var showSymbolPicker: Bool = false

    let colors = ["#E57373", "#4FC3F7", "#AED581", "#7986CB", "#F06292", "#FFB74D", "#9575CD", "#90A4AE"]

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
                if let subject {
                    name = subject.name
                    selectedIcon = subject.icon
                    selectedColorHex = subject.colorHex

                    if !colors.contains(subject.colorHex) {
                        customColor = Color(hex: subject.colorHex)
                        useCustomColor = true
                    }
                }
            }
        }
    }

    private var finalColorHex: String {
        if useCustomColor {
            return customColor.toHex() ?? "#4FC3F7"
        } else {
            return selectedColorHex
        }
    }

    func saveSubject() {
        viewModel?.saveSubject(
            subject: subject,
            name: name.trimmingCharacters(in: .whitespaces),
            selectedIcon: selectedIcon,
            finalColorHex: finalColorHex
        )
    }
}

#Preview {
    SubjectManagerView()
}
