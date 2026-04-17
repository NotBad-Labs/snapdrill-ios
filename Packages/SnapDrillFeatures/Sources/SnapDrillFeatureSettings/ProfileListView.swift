//
//  ProfileListView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/03/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  学习者管理页面，支持 Profile 的切换、新增和删除。
//  逻辑见 ProfileListViewModel；本 View 只做渲染。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData

/// 学习者管理视图
///
/// 列出所有 Profile，支持切换、新增和删除。
/// 参考 Obsidian Vault 切换的轻量模式。
struct ProfileListView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ProfileListViewModel

    init(profileManager: ProfileManager) {
        _viewModel = State(initialValue: ProfileListViewModel(profileManager: profileManager))
    }

    var body: some View {
        List {
            Section {
                ForEach(viewModel.profiles) { profile in
                    profileRow(profile)
                }
                .onDelete(perform: viewModel.confirmDelete)
            }

            Section {
                Button {
                    viewModel.newProfileName = ""
                    viewModel.showingAddSheet = true
                } label: {
                    Label(L10n.Settings.addLearner, systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle(L10n.Settings.switchLearner)
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.Common.delete, isPresented: .init(
            get: { viewModel.profileToDelete != nil },
            set: { if !$0 { viewModel.profileToDelete = nil } }
        )) {
            Button(L10n.Common.cancel, role: .cancel) { viewModel.profileToDelete = nil }
            Button(L10n.Common.delete, role: .destructive) {
                viewModel.executeDelete()
            }
        } message: {
            if let profile = viewModel.profileToDelete {
                Text("\"\(profile.name)\" " + L10n.Settings.deleteLearnerConfirm)
            }
        }
        .confirmationDialog(
            L10n.Settings.draftExistsTitle,
            isPresented: .init(
                get: { viewModel.pendingSwitchProfileId != nil },
                set: { if !$0 { viewModel.pendingSwitchProfileId = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.Settings.discardDraft, role: .destructive) {
                if viewModel.discardDraftAndSwitch() {
                    dismiss()
                }
            }
            Button(L10n.Common.cancel, role: .cancel) {
                viewModel.pendingSwitchProfileId = nil
            }
        } message: {
            Text(L10n.Settings.draftExistsMessage)
        }
        .alert(L10n.Settings.addLearner, isPresented: $viewModel.showingAddSheet) {
            TextField(L10n.Settings.learnerName, text: $viewModel.newProfileName)
            Button(L10n.Common.cancel, role: .cancel) {}
            Button(L10n.Common.ok) {
                viewModel.createProfile()
            }
        }
        .alert(L10n.Common.error, isPresented: .init(
            get: { viewModel.switchError != nil },
            set: { if !$0 { viewModel.switchError = nil } }
        )) {
            Button(L10n.Common.ok, role: .cancel) {}
        } message: {
            Text(viewModel.switchError ?? "")
        }
        .alert(L10n.Common.error, isPresented: .init(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )) {
            Button(L10n.Common.ok, role: .cancel) {}
        } message: {
            Text(viewModel.deleteError ?? "")
        }
    }

    // MARK: - Private

    @ViewBuilder
    private func profileRow(_ profile: Profile) -> some View {
        Button {
            if viewModel.switchToProfile(profile.id) {
                dismiss()
            }
        } label: {
            HStack {
                Image(systemName: profile.avatar)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)

                Text(profile.name)
                    .foregroundStyle(.primary)

                Spacer()

                if profile.id == viewModel.activeProfileId {
                    Text(L10n.Settings.currentLearner)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
        .accessibilityLabel(profile.name)
        .accessibilityHint(profile.id == viewModel.activeProfileId ? "当前学习者" : "点击切换到此学习者")
    }
}
