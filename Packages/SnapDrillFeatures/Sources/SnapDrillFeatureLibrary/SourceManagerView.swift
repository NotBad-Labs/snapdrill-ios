//
//  SourceManagerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  来源管理视图，允许用户添加、删除或重命名来源。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData

public struct SourceManagerView: View {

    // MARK: - Properties

    @Environment(\.repositories) private var repositories

    @State private var viewModel: SourceManagerViewModel?

    @State private var showingAddSheet = false
    @State private var editingSource: SourceModel?

    public init() {}

    // MARK: - Body

    public var body: some View {
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
                Text(L10n.Library.sourceHasItems(viewModel?.pendingDeletionName ?? ""))
            }
            .navigationTitle(L10n.Library.sourceManager)
            .toolbar {
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

#Preview {
    SourceManagerView()
}
