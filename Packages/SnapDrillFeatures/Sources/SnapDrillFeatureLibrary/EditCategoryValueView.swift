//
//  EditCategoryValueView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  维度值的添加/编辑视图（L3）。取代 EditSubjectView/EditSourceView 同构表单，
//  结构与 EditSubjectView 对等：名称 + 图标 + 颜色。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

/// 统一的添加/编辑维度值视图
struct EditCategoryValueView: View {
    @Environment(\.dismiss) private var dismiss

    /// nil = 添加模式；否则编辑模式
    let value: CategoryValueModel?
    let viewModel: CategoryValueListViewModel?

    @State private var name: String = ""
    @State private var selectedIcon: String = "circle"
    @State private var selectedColorHex: String = "#4FC3F7"
    @State private var customColor: Color = .blue
    @State private var useCustomColor: Bool = false
    @State private var showSymbolPicker: Bool = false

    private let colors = ["#E57373", "#4FC3F7", "#AED581", "#7986CB", "#F06292", "#FFB74D", "#9575CD", "#90A4AE"]

    private var isEditing: Bool { value != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Library.name) {
                    TextField(L10n.Library.namePlaceholder, text: $name)
                        .accessibilityIdentifier("dimValueEdit.nameField")
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
                    .accessibilityIdentifier("dimValueEdit.iconPicker")
                }

                Section(L10n.Library.color) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(colors, id: \.self) { hex in
                            Button {
                                selectedColorHex = hex
                                useCustomColor = false
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 30, height: 30)

                                    if !useCustomColor && selectedColorHex == hex {
                                        Circle()
                                            .strokeBorder(Color.accentColor, lineWidth: 2.5)
                                            .frame(width: 38, height: 38)

                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                            .shadow(color: .black.opacity(0.32), radius: 1, x: 0, y: 1)
                                            .accessibilityHidden(true)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.Library.color)
                            .accessibilityIdentifier("dimValueEdit.color.\(hex.replacingOccurrences(of: "#", with: ""))")
                            .accessibilityAddTraits((!useCustomColor && selectedColorHex == hex) ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 8)

                    HStack {
                        Text(L10n.Library.customColor)
                        Spacer()
                        ColorPicker("", selection: $customColor, supportsOpacity: false)
                            .labelsHidden()
                            .accessibilityIdentifier("dimValueEdit.customColor")
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
            .accessibilityIdentifier("dimValueEdit.root")
            .navigationTitle(isEditing ? L10n.Library.editValue : L10n.Library.addValue)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
                        if saveValue() {
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
            .onAppear {
                if let value {
                    name = value.name
                    selectedIcon = value.icon
                    selectedColorHex = value.colorHex
                    if !colors.contains(value.colorHex) {
                        customColor = Color(hex: value.colorHex)
                        useCustomColor = true
                    }
                }
            }
        }
    }

    private var finalColorHex: String {
        useCustomColor ? (customColor.toHex() ?? "#4FC3F7") : selectedColorHex
    }

    @discardableResult
    private func saveValue() -> Bool {
        viewModel?.saveValue(
            value: value,
            name: name.trimmingCharacters(in: .whitespaces),
            icon: selectedIcon,
            colorHex: finalColorHex
        ) ?? false
    }
}
