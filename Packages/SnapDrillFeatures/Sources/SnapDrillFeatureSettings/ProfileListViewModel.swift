//
//  ProfileListViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ProfileListView ViewModel：把 switch / delete / draft 检查逻辑从 View 抽出，
//  以便单测覆盖 deleteProfile 错误路径（Issue #638）。
//

import Foundation
import SwiftUI
import SnapDrillCore
import SnapDrillData

/// 资料空间管理 ViewModel
///
/// 把切换/删除/草稿检查逻辑从 ProfileListView 抽出，
/// View 层只做渲染，逻辑分支在此处可单测。
@Observable
final class ProfileListViewModel {

    // MARK: - Published State

    var showingAddSheet = false
    var newProfileName = ""
    var profileToDelete: Profile?
    /// 草稿存在时暂存目标 Profile ID，等用户确认后再切换
    var pendingSwitchProfileId: UUID?
    private var pendingDraftRevision: CaptureDraftRevision?
    /// 切换被阻塞时的错误提示
    var switchError: String?
    /// 删除失败时的错误提示（如最后一个 Profile 无法删除）
    var deleteError: String?

    // MARK: - Dependencies

    let profileManager: ProfileManager
    private let draftService: CaptureDraftServiceProtocol

    // MARK: - Init

    init(
        profileManager: ProfileManager,
        draftService: CaptureDraftServiceProtocol
    ) {
        self.profileManager = profileManager
        self.draftService = draftService
    }

    // MARK: - Derived

    var profiles: [Profile] { profileManager.profiles }
    var activeProfileId: UUID? { profileManager.activeProfileId }

    // MARK: - Actions

    /// onDelete 回调：守卫单 Profile 不允许删除
    func confirmDelete(at offsets: IndexSet) {
        guard profileManager.profiles.count > 1 else { return }
        if let index = offsets.first {
            profileToDelete = profileManager.profiles[index]
        }
    }

    /// 用户在确认 alert 点删除
    func executeDelete() async {
        guard let profile = profileToDelete else { return }
        if profile.id == profileManager.activeProfileId,
           draftService.state().revision != nil {
            deleteError = L10n.Settings.draftExistsMessage
            profileToDelete = nil
            return
        }
        do {
            try await profileManager.deleteProfile(id: profile.id)
        } catch {
            SnapDrillLogger.data.error("ProfileListView: 删除 Profile 失败 - \(error.localizedDescription)")
            deleteError = error.localizedDescription
        }
        profileToDelete = nil
    }

    /// 切换前检查草稿状态。返回是否应当 dismiss view（true = 切换成功）
    @discardableResult
    func switchToProfile(_ profileId: UUID) async -> Bool {
        guard profileId != profileManager.activeProfileId else { return false }
        let draftState = draftService.state()
        if let revision = draftState.revision {
            pendingSwitchProfileId = profileId
            pendingDraftRevision = revision
            return false
        }
        do {
            try await profileManager.switchProfile(to: profileId)
            return true
        } catch {
            switchError = error.localizedDescription
            return false
        }
    }

    /// 放弃 Profile-free 草稿后执行切换，避免草稿短暂暴露给目标 Profile。
    @discardableResult
    func discardDraftAndSwitch() async -> Bool {
        guard let profileId = pendingSwitchProfileId,
              let draftRevision = pendingDraftRevision else {
            return false
        }
        do {
            try draftService.discard(draftRevision)
            try await profileManager.switchProfile(to: profileId)
            pendingSwitchProfileId = nil
            pendingDraftRevision = nil
            return true
        } catch {
            switchError = error.localizedDescription
            return false
        }
    }

    /// 创建 Profile（newProfileName 已 trim 过）
    func createProfile() {
        let name = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if profileManager.createProfile(name: name) == nil {
            SnapDrillLogger.data.error("ProfileListView: Profile 创建失败")
        }
    }
}
