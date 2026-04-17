//
//  ProfileListViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/04/17.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ProfileListViewModel 删除/切换/创建逻辑单元测试。
//  覆盖 Issue #638：deleteProfile 错误路径自动化保护。
//

import Testing
import Foundation
@testable import SnapDrillFeatureSettings
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("ProfileListViewModel 测试", .serialized)
@MainActor
final class ProfileListViewModelTests {

    private let profileManager: ProfileManager

    init() {
        profileManager = ProfileManager(inMemory: true)
    }

    private func makeVM() -> ProfileListViewModel {
        ProfileListViewModel(profileManager: profileManager)
    }

    // MARK: - 初始状态

    @Test("初始状态：所有 alert/error 字段为空")
    func initialState() {
        let vm = makeVM()
        #expect(vm.showingAddSheet == false)
        #expect(vm.newProfileName == "")
        #expect(vm.profileToDelete == nil)
        #expect(vm.pendingSwitchProfileId == nil)
        #expect(vm.switchError == nil)
        #expect(vm.deleteError == nil)
    }

    // MARK: - confirmDelete 守卫（issue #638 核心场景）

    @Test("confirmDelete 单 Profile 时不设置 profileToDelete（守卫生效）")
    func confirmDelete_singleProfile_doesNotSet() {
        let vm = makeVM()
        // 默认 inMemory ProfileManager 应只有 1 个默认 Profile
        #expect(vm.profiles.count == 1)

        vm.confirmDelete(at: IndexSet(integer: 0))

        #expect(vm.profileToDelete == nil)
    }

    @Test("confirmDelete 多 Profile 时设置 profileToDelete")
    func confirmDelete_multipleProfiles_setsTarget() {
        let vm = makeVM()
        _ = profileManager.createProfile(name: "测试 Profile A")
        _ = profileManager.createProfile(name: "测试 Profile B")

        #expect(vm.profiles.count == 3)
        let targetIndex = vm.profiles.count - 1
        let expected = vm.profiles[targetIndex]

        vm.confirmDelete(at: IndexSet(integer: targetIndex))

        #expect(vm.profileToDelete?.id == expected.id)
    }

    // MARK: - executeDelete 错误路径（Issue #638 关键覆盖）

    @Test("executeDelete 删除最后一个 Profile 时设置 deleteError 并清 profileToDelete")
    func executeDelete_lastProfile_setsDeleteError() {
        let vm = makeVM()
        // 故意绕过 confirmDelete 守卫，直接给 profileToDelete 赋值
        // 模拟 ProfileManager.deleteProfile 抛 cannotDeleteLastProfile 的场景
        guard let onlyProfile = vm.profiles.first else {
            Issue.record("inMemory ProfileManager 应有默认 Profile")
            return
        }
        vm.profileToDelete = onlyProfile

        vm.executeDelete()

        #expect(vm.deleteError != nil)
        #expect(vm.deleteError?.contains("最后") == true || vm.deleteError?.contains("无法") == true)
        #expect(vm.profileToDelete == nil, "executeDelete 后 profileToDelete 必须清空，避免 alert 残留")
    }

    @Test("executeDelete profileToDelete 为 nil 时无副作用")
    func executeDelete_noTarget_noop() {
        let vm = makeVM()

        vm.executeDelete()

        #expect(vm.deleteError == nil)
        #expect(vm.profileToDelete == nil)
    }

    @Test("executeDelete 成功路径：删除非活跃 Profile 后 deleteError 不设置")
    func executeDelete_nonActiveProfile_succeeds() {
        let vm = makeVM()
        _ = profileManager.createProfile(name: "可删除 Profile")
        let nonActive = vm.profiles.first { $0.id != vm.activeProfileId }
        guard let target = nonActive else {
            Issue.record("应能找到非活跃 Profile")
            return
        }

        vm.profileToDelete = target
        vm.executeDelete()

        #expect(vm.deleteError == nil)
        #expect(vm.profileToDelete == nil)
        #expect(!vm.profiles.contains(where: { $0.id == target.id }))
    }

    // MARK: - createProfile

    @Test("createProfile 空名称跳过（trim 后空）")
    func createProfile_blankName_noOp() {
        let vm = makeVM()
        let countBefore = vm.profiles.count

        vm.newProfileName = "   "
        vm.createProfile()

        #expect(vm.profiles.count == countBefore)
    }

    @Test("createProfile 有效名称新增 Profile")
    func createProfile_validName_added() {
        let vm = makeVM()
        let countBefore = vm.profiles.count

        vm.newProfileName = "新学习者"
        vm.createProfile()

        #expect(vm.profiles.count == countBefore + 1)
        #expect(vm.profiles.contains(where: { $0.name == "新学习者" }))
    }

    // MARK: - switchToProfile 边界

    @Test("switchToProfile 当前活跃 Profile 时返回 false 且不切换")
    func switchToProfile_alreadyActive_noOp() {
        let vm = makeVM()
        guard let activeId = vm.activeProfileId else {
            Issue.record("应有活跃 Profile")
            return
        }

        let result = vm.switchToProfile(activeId)

        #expect(result == false)
        #expect(vm.switchError == nil)
        #expect(vm.pendingSwitchProfileId == nil)
    }
}
