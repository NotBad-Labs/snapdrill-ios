//
//  SnapshotRegressionTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/04/19.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SwiftUI 视觉回归测试（Harness Stage C PR-6）。
//
//  基线图入 git，改 View 时若快照失败，先人眼审是否为有意变更，
//  再删对应基线文件或用 `isRecording = true` 重录。
//  禁止盲目 record 掉所有快照（反模式，等同 test evasion）。
//
//  位置说明：本文件放在 SnapDrillFeaturesTests 而非 SnapDrillUITests(SPM)，
//  原因 —— Xcode 原生 `SnapDrillUITests` (XCUITest) 与 SPM `SnapDrillUITests`
//  命名冲突，且 AllTests scheme 只纳入 Core/Data/FeaturesTests。
//  放 FeaturesTests 可确保 CI 真实执行。
//
//  覆盖范围：先只覆盖 SnapDrillUI 层 public View。后续 PR 可通过
//  `@testable import SnapDrillFeature*` 扩展到 Features 层 internal View。
//

import SnapshotTesting
import SwiftUI
import SnapDrillCore
import SnapDrillUI
import XCTest

// XCTestCase 要求 init 保持 nonisolated 与基类一致；
// 项目 defaultIsolation(MainActor) 会将类型默认转 MainActor，故在类上显式标 nonisolated。
// 单个测试方法若需 MainActor 语义再加 @MainActor。
nonisolated final class SnapshotRegressionTests: XCTestCase {

    // MARK: - SnapDrillButton

    @MainActor
    func testSnapDrillButton_default() {
        let view = SnapDrillButton(title: "主要操作") { }
            .padding()
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - ProgressLoadingView

    @MainActor
    func testProgressLoadingView_withProgress() {
        let view = ProgressLoadingView(message: "正在导出 PDF...", progress: 0.65)
            .frame(width: 390, height: 400)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    @MainActor
    func testProgressLoadingView_indeterminate() {
        let view = ProgressLoadingView(message: "正在同步数据...")
            .frame(width: 390, height: 400)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - ErrorMessageView

    @MainActor
    func testErrorMessageView_default() {
        let view = ErrorMessageView(
            title: "加载失败",
            message: "请检查网络连接后重试"
        )
        .frame(width: 390, height: 300)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    @MainActor
    func testErrorMessageView_withAction() {
        let view = ErrorMessageView(
            title: "导出失败",
            message: "请稍后重试",
            icon: "arrow.down.circle.fill",
            actionTitle: "重试",
            action: { }
        )
        .frame(width: 390, height: 360)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - ContextualErrorView

    @MainActor
    func testContextualErrorView_dataCorrupted() {
        let view = ContextualErrorView(error: .dataCorrupted)
            .frame(width: 390, height: 400)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - TipPopoverContent

    @MainActor
    func testTipPopoverContent_default() {
        let view = TipPopoverContent(
            icon: "lightbulb.fill",
            title: "复习小技巧",
            message: "点击卡片翻面查看答案，左滑表示忘了，右滑表示记得",
            onDismiss: { }
        )
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
