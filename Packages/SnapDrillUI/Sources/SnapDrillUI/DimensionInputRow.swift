//
//  DimensionInputRow.swift
//  SnapDrillUI
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  动态维度录入行：单值维度→Menu 单选，多值维度→chips 多选，均支持现场新建值。
//  纯值接口（不依赖 SnapDrillData）——ViewModel 负责把 @Model 映射成 DimensionInputModel。
//

import SwiftUI
import SnapDrillCore

/// 维度值的 UI 纯值表示（与 @Model 解耦，UI 层不依赖 SnapDrillData）
public struct DimensionValueOption: Identifiable, Equatable {
    public let id: UUID
    public let name: String

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

/// 一个维度的 UI 纯值描述（标题/图标/单多值/可选值）
public struct DimensionInputModel: Identifiable {
    public let id: UUID
    public let title: String
    public let icon: String
    public let isMultiValue: Bool
    public let options: [DimensionValueOption]

    public init(id: UUID, title: String, icon: String, isMultiValue: Bool, options: [DimensionValueOption]) {
        self.id = id
        self.title = title
        self.icon = icon
        self.isMultiValue = isMultiValue
        self.options = options
    }
}

/// 动态维度录入行：单值→Menu 单选、多值→chips 多选，均支持现场新建值。
/// `onToggle` 由 ViewModel 按维度单/多值语义解释（单值=替换选中、多值=切换）。
public struct DimensionInputRow: View {

    private let model: DimensionInputModel
    private let selectedIds: Set<UUID>
    private let onToggle: (UUID) -> Void
    private let onCreateValue: (String) -> Void

    @State private var showNewValueAlert = false
    @State private var newValueText = ""

    public init(
        model: DimensionInputModel,
        selectedIds: Set<UUID>,
        onToggle: @escaping (UUID) -> Void,
        onCreateValue: @escaping (String) -> Void
    ) {
        self.model = model
        self.selectedIds = selectedIds
        self.onToggle = onToggle
        self.onCreateValue = onCreateValue
    }

    public var body: some View {
        Group {
            if model.isMultiValue {
                multiValueSection
            } else {
                singleValueRow
            }
        }
        .alert(L10n.Capture.addValueTitle(model.title), isPresented: $showNewValueAlert) {
            TextField(L10n.Capture.addValuePlaceholder, text: $newValueText)
            Button(L10n.Common.cancel, role: .cancel) { newValueText = "" }
            Button(L10n.Common.create) {
                let trimmed = newValueText.trimmingCharacters(in: .whitespaces)
                newValueText = ""
                if !trimmed.isEmpty { onCreateValue(trimmed) }
            }
        }
    }

    // MARK: - 单值

    private var singleValueRow: some View {
        HStack {
            Label(model.title, systemImage: model.icon)
            Spacer()
            singleValueMenu
        }
        .accessibilityIdentifier("capture.dimRow.\(model.title)")
    }

    private var singleValueMenu: some View {
        Menu {
            ForEach(model.options) { option in
                Button { onToggle(option.id) } label: {
                    if selectedIds.contains(option.id) {
                        Label(option.name, systemImage: "checkmark")
                    } else {
                        Text(option.name)
                    }
                }
                .accessibilityIdentifier("capture.opt.\(option.name)")
            }
            Divider()
            Button { showNewValueAlert = true } label: {
                Label(L10n.Capture.addValueTitle(model.title), systemImage: "plus")
            }
        } label: {
            Text(selectedName ?? L10n.Capture.selectValue)
                .foregroundStyle(Color.primary)
        }
        // 注：单值菜单的稳定 id 落在外层 row（capture.dimRow.<title>）——
        // SwiftUI 把带 id 的 HStack 折叠成单一无障碍元素、内层 Menu 自身 id 不 surface（实证）。
    }

    // MARK: - 多值

    private var multiValueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(model.title, systemImage: model.icon)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(model.options) { option in
                        chip(option)
                    }
                    newValueChip
                }
            }
        }
        .accessibilityIdentifier("capture.dimRow.\(model.title)")
    }

    private func chip(_ option: DimensionValueOption) -> some View {
        let selected = selectedIds.contains(option.id)
        return Button { onToggle(option.id) } label: {
            Text(option.name)
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selected ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("capture.chip.\(option.name)")
    }

    private var newValueChip: some View {
        Button { showNewValueAlert = true } label: {
            Group {
                if model.options.isEmpty {
                    Label(L10n.Capture.addValueTitle(model.title), systemImage: "plus")
                } else {
                    Image(systemName: "plus")
                }
            }
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.secondary.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Capture.addValueTitle(model.title))
    }

    private var selectedName: String? {
        // 按 options 顺序取首个选中项（不用 Set.first——无序会导致同题多值残留时显示跳变）
        model.options.first { selectedIds.contains($0.id) }?.name
    }
}
