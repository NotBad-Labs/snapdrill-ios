//
//  CategoryManagerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  分类维度管理统一入口（L3）：维度列表 + 新建维度。点维度进详情管理其值与开关。
//  取代旧固定分类/来源/级别三个并列入口。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData

public struct CategoryManagerView: View {

    @Environment(\.repositories) private var repositories

    @State private var viewModel: CategoryManagerViewModel?
    @State private var showingAddDimension = false

    public init() {}

    public var body: some View {
        List {
            if let vm = viewModel {
                Section(L10n.Library.dimensionsSection) {
                    ForEach(vm.dimensions) { dimension in
                        NavigationLink {
                            CategoryValueListView(dimension: dimension)
                        } label: {
                            dimensionRow(dimension)
                        }
                        .accessibilityIdentifier("dim.row.\(dimension.systemKey ?? dimension.name)")
                        .deleteDisabled(dimension.isBuiltIn)
                    }
                    .onDelete(perform: { offsets in vm.delete(at: offsets) })
                }
            }
        }
        .accessibilityIdentifier("settings.categoryManager.root")
        .navigationTitle(L10n.Library.categoryManager)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddDimension = true }, label: {
                    Image(systemName: "plus")
                })
                .accessibilityIdentifier("dim.add")
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
        .sheet(isPresented: $showingAddDimension) {
            EditDimensionView(viewModel: viewModel)
        }
        .task {
            if viewModel == nil {
                viewModel = CategoryManagerViewModel(repositories: repositories)
            }
            viewModel?.loadData()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func dimensionRow(_ dimension: CategoryDimensionModel) -> some View {
        HStack {
            Image(systemName: dimension.icon)
                .foregroundStyle(.tint)
                .frame(width: 24)
            Text(dimension.name)
                .foregroundStyle(.primary)
            if dimension.isBuiltIn {
                Text(L10n.Library.builtInBadge)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15), in: Capsule())
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        CategoryManagerView()
    }
}
