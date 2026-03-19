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
            .alert(L10n.Library.cannotDeleteInUse, isPresented: Binding(
                get: { viewModel?.isDeletingInUse ?? false },
                set: { newValue in viewModel?.isDeletingInUse = newValue }
            )) {
                Button(L10n.Common.ok, role: .cancel) { }
            } message: {
                Text(L10n.Library.subjectHasItems(viewModel?.pendingDeletionName ?? ""))
            }
            .navigationTitle(L10n.Library.subjectManager)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.close) { dismiss() }
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
                Section(L10n.Library.name) {
                    TextField(L10n.Library.namePlaceholder, text: $name)
                }

                Section(L10n.Library.icon) {
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

                            Text(L10n.Library.iconPicker)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(L10n.Library.color) {
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
                        Text(L10n.Library.customColor)
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
            .navigationTitle(isEditing ? L10n.Library.editSubject : L10n.Library.addSubject)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
                        if saveSubject() {
                            dismiss()
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .alert(L10n.Library.duplicateName, isPresented: Binding(
                get: { viewModel?.isDuplicateName ?? false },
                set: { newValue in viewModel?.isDuplicateName = newValue }
            )) {
                Button(L10n.Common.ok, role: .cancel) { }
            } message: {
                Text(L10n.Library.duplicateNameMessage(viewModel?.duplicateNameValue ?? ""))
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

    @discardableResult
    func saveSubject() -> Bool {
        viewModel?.saveSubject(
            subject: subject,
            name: name.trimmingCharacters(in: .whitespaces),
            selectedIcon: selectedIcon,
            finalColorHex: finalColorHex
        ) ?? false
    }
}

#Preview {
    SubjectManagerView()
}
