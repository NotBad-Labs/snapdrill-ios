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

public struct SubjectManagerView: View {

    // MARK: - Properties

    @Environment(\.repositories) private var repositories

    @State private var viewModel: SubjectManagerViewModel?

    @State private var showingAddSheet = false
    @State private var editingSubject: SubjectModel?

    public init() {}

    // MARK: - Body

    public var body: some View {
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
                // push 场景由系统 Back 按钮处理，不需要 dismiss 按钮
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

#Preview {
    SubjectManagerView()
}
