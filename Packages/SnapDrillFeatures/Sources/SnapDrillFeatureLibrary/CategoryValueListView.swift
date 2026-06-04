//
//  CategoryValueListView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  维度详情视图（L3）：维度级开关（录入页可见性 / 单值多值）+ 该维度下的值增删改。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData

/// 单个维度的详情与值管理视图
struct CategoryValueListView: View {

    @Environment(\.repositories) private var repositories

    let dimension: CategoryDimensionModel

    @State private var viewModel: CategoryValueListViewModel?
    @State private var showingAddSheet = false
    @State private var editingValue: CategoryValueModel?

    init(dimension: CategoryDimensionModel) {
        self.dimension = dimension
    }

    var body: some View {
        List {
            if let vm = viewModel {
                settingsSection(vm: vm)
                valuesSection(vm: vm)
            }
        }
        .navigationTitle(dimension.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSheet = true }, label: {
                    Image(systemName: "plus")
                })
                .accessibilityIdentifier("dimValue.add")
            }
        }
        .alert(L10n.Library.cannotDeleteInUse, isPresented: Binding(
            get: { viewModel?.isDeletingInUse ?? false },
            set: { newValue in viewModel?.isDeletingInUse = newValue }
        )) {
            Button(L10n.Common.ok, role: .cancel) { }
        } message: {
            Text(L10n.Library.valueHasItems(viewModel?.pendingDeletionName ?? ""))
        }
        .sheet(isPresented: $showingAddSheet) {
            EditCategoryValueView(value: nil, viewModel: viewModel)
        }
        .sheet(item: $editingValue) { value in
            EditCategoryValueView(value: value, viewModel: viewModel)
        }
        .task {
            if viewModel == nil {
                viewModel = CategoryValueListViewModel(dimension: dimension, repositories: repositories)
            }
            viewModel?.loadData()
        }
    }

    // MARK: - Subviews

    private func settingsSection(vm: CategoryValueListViewModel) -> some View {
        Section {
            Toggle(L10n.Library.showInCapture, isOn: Binding(
                get: { vm.isVisibleInCapture },
                set: { vm.isVisibleInCapture = $0 }
            ))

            Toggle(L10n.Library.multiValue, isOn: Binding(
                get: { vm.isMultiValue },
                set: { vm.isMultiValue = $0 }
            ))
            .disabled(dimension.isBuiltIn)
            .accessibilityIdentifier("dim.multiToggle")
        } header: {
            Text(L10n.Library.dimensionSettings)
        } footer: {
            Text(dimension.isBuiltIn ? L10n.Library.showInCaptureDescription : L10n.Library.multiValueDescription)
        }
    }

    private func valuesSection(vm: CategoryValueListViewModel) -> some View {
        Section(L10n.Library.valuesSection) {
            if vm.values.isEmpty {
                Text(L10n.Library.noValues)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vm.values) { value in
                    Button {
                        editingValue = value
                    } label: {
                        HStack {
                            Image(systemName: value.icon)
                                .foregroundStyle(Color(hex: value.colorHex))
                                .frame(width: 24)
                            Text(value.name)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                    .accessibilityIdentifier("dimValue.\(value.name)")
                }
                .onDelete(perform: { offsets in vm.delete(at: offsets) })
            }
        }
    }
}
