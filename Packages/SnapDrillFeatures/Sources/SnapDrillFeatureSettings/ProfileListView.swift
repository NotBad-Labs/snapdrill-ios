//
//  ProfileListView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/03/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  学习者管理页面，支持 Profile 的切换、新增和删除。
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
    let profileManager: ProfileManager

    @State private var showingAddSheet = false
    @State private var newProfileName = ""
    @State private var profileToDelete: Profile?
    /// 草稿存在时暂存目标 Profile ID，等用户确认后再切换
    @State private var pendingSwitchProfileId: UUID?
    /// 切换被阻塞时的错误提示
    @State private var switchError: String?

    var body: some View {
        List {
            Section {
                ForEach(profileManager.profiles) { profile in
                    profileRow(profile)
                }
                .onDelete(perform: confirmDelete)
            }

            Section {
                Button {
                    newProfileName = ""
                    showingAddSheet = true
                } label: {
                    Label(L10n.Settings.addLearner, systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle(L10n.Settings.switchLearner)
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.Common.delete, isPresented: .init(
            get: { profileToDelete != nil },
            set: { if !$0 { profileToDelete = nil } }
        )) {
            Button(L10n.Common.cancel, role: .cancel) { profileToDelete = nil }
            Button(L10n.Common.delete, role: .destructive) {
                if let profile = profileToDelete {
                    try? profileManager.deleteProfile(id: profile.id)
                    profileToDelete = nil
                }
            }
        } message: {
            if let profile = profileToDelete {
                Text("\"\(profile.name)\" " + L10n.Settings.deleteLearnerConfirm)
            }
        }
        .confirmationDialog(
            L10n.Settings.draftExistsTitle,
            isPresented: .init(
                get: { pendingSwitchProfileId != nil },
                set: { if !$0 { pendingSwitchProfileId = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.Settings.discardDraft, role: .destructive) {
                discardDraftAndSwitch()
            }
            Button(L10n.Common.cancel, role: .cancel) {
                pendingSwitchProfileId = nil
            }
        } message: {
            Text(L10n.Settings.draftExistsMessage)
        }
        .alert(L10n.Settings.addLearner, isPresented: $showingAddSheet) {
            TextField(L10n.Settings.learnerName, text: $newProfileName)
            Button(L10n.Common.cancel, role: .cancel) {}
            Button(L10n.Common.ok) {
                let name = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                if profileManager.createProfile(name: name) == nil {
                    SnapDrillLogger.data.error("ProfileListView: Profile 创建失败")
                }
            }
        }
        .alert(L10n.Common.error, isPresented: .init(
            get: { switchError != nil },
            set: { if !$0 { switchError = nil } }
        )) {
            Button(L10n.Common.ok, role: .cancel) {}
        } message: {
            Text(switchError ?? "")
        }
    }

    // MARK: - Private

    @ViewBuilder
    private func profileRow(_ profile: Profile) -> some View {
        Button {
            switchToProfile(profile.id)
        } label: {
            HStack {
                Image(systemName: profile.avatar)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)

                Text(profile.name)
                    .foregroundStyle(.primary)

                Spacer()

                if profile.id == profileManager.activeProfileId {
                    Text(L10n.Settings.currentLearner)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
        .accessibilityLabel(profile.name)
        .accessibilityHint(profile.id == profileManager.activeProfileId ? "当前学习者" : "点击切换到此学习者")
    }

    /// 切换前检查草稿状态和进行中操作
    private func switchToProfile(_ profileId: UUID) {
        guard profileId != profileManager.activeProfileId else { return }
        if CaptureDraftService.shared.hasDraft {
            pendingSwitchProfileId = profileId
        } else {
            do {
                try profileManager.switchProfile(to: profileId)
                dismiss()
            } catch {
                switchError = error.localizedDescription
            }
        }
    }

    /// 放弃草稿后执行切换（先切换再清草稿，避免切换失败时草稿已丢）
    private func discardDraftAndSwitch() {
        if let profileId = pendingSwitchProfileId {
            do {
                try profileManager.switchProfile(to: profileId)
                CaptureDraftService.shared.clearDraft()
                pendingSwitchProfileId = nil
                dismiss()
            } catch {
                switchError = error.localizedDescription
            }
        }
    }

    private func confirmDelete(at offsets: IndexSet) {
        guard profileManager.profiles.count > 1 else { return }
        if let index = offsets.first {
            profileToDelete = profileManager.profiles[index]
        }
    }
}
