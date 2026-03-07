//
//  GradeManagerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/03/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  年级/学习阶段管理视图，与 SubjectManagerView 对等。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData

/// 年级管理视图
public struct GradeManagerView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(\.repositories) private var repositories

    @State private var viewModel: GradeManagerViewModel?
    @State private var showingAddSheet = false
    @State private var editingGrade: GradeModel?

    public init() {}

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            List {
                if let vm = viewModel {
                    ForEach(vm.grades) { grade in
                        Button {
                            editingGrade = grade
                        } label: {
                            HStack {
                                Text(grade.name)
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
                Text("年级「\(viewModel?.pendingDeletionName ?? "")」下仍有题目，请先将题目移动到其他年级或删除对应题目。")
            }
            .navigationTitle("管理年级")
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
                EditGradeView(grade: nil, viewModel: viewModel)
            }
            .sheet(item: $editingGrade) { grade in
                EditGradeView(grade: grade, viewModel: viewModel)
            }
            .task {
                if viewModel == nil {
                    viewModel = GradeManagerViewModel(repositories: repositories)
                }
                viewModel?.loadData()
            }
        }
    }
}

// MARK: - Edit Grade View

/// 统一的添加/编辑年级视图
private struct EditGradeView: View {

    @Environment(\.dismiss) private var dismiss

    let grade: GradeModel?
    let viewModel: GradeManagerViewModel?

    @State private var name: String = ""

    private var isEditing: Bool { grade != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("年级名称") {
                    TextField("例如：高三", text: $name)
                }
            }
            .navigationTitle(isEditing ? "编辑年级" : "添加年级")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel?.saveGrade(grade: grade, name: name.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if let grade {
                    name = grade.name
                }
            }
        }
    }
}

#Preview {
    GradeManagerView()
}
