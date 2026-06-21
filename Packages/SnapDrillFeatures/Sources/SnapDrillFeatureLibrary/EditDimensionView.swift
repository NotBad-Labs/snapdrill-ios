//
//  EditDimensionView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  新建维度视图（L3）：名称 + 单值/多值 + 图标。仅用于创建用户自定义维度
//  （内置维度由 seed 生成、不在此创建；编辑维度的开关在维度详情页）。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

/// 新建用户维度视图
struct EditDimensionView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: CategoryManagerViewModel?

    @State private var name: String = ""
    @State private var isMultiValue: Bool = false
    @State private var selectedIcon: String = "tag"
    @State private var showSymbolPicker: Bool = false

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Library.name) {
                    TextField(L10n.Library.dimensionNamePlaceholder, text: $name)
                        .accessibilityIdentifier("dimEdit.nameField")
                }

                Section(L10n.Library.icon) {
                    Button {
                        showSymbolPicker = true
                    } label: {
                        HStack {
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .frame(width: 32, height: 32)
                            Text(selectedIcon)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(L10n.Library.iconPicker)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("dimEdit.iconPicker")
                }

                Section {
                    Toggle(L10n.Library.multiValue, isOn: $isMultiValue)
                        .accessibilityIdentifier("dimEdit.multiToggle")
                } footer: {
                    Text(L10n.Library.multiValueDescription)
                }
            }
            .accessibilityIdentifier("dimEdit.root")
            .navigationTitle(L10n.Library.addDimension)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                        .accessibilityIdentifier("dimEdit.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
                        if saveDimension() {
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("dimEdit.save")
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
            .alert(L10n.Common.error, isPresented: Binding(
                get: { viewModel?.operationError != nil },
                set: { if !$0 { viewModel?.operationError = nil } }
            )) {
                Button(L10n.Common.ok, role: .cancel) { viewModel?.operationError = nil }
            } message: {
                Text(viewModel?.operationError ?? L10n.Errors.saveFailed)
            }
            .sheet(isPresented: $showSymbolPicker) {
                SFSymbolPickerView(selectedSymbol: $selectedIcon)
            }
        }
    }

    @discardableResult
    private func saveDimension() -> Bool {
        viewModel?.addDimension(
            name: name.trimmingCharacters(in: .whitespaces),
            isMultiValue: isMultiValue,
            icon: selectedIcon
        ) ?? false
    }
}
