//
//  SnapshotRegressionTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SwiftUI 视觉回归测试（Harness Stage C PR-6）。
//
//  基线图入 git，改 View 时若快照失败，先人眼审是否为有意变更，
//  再删对应基线文件或切 `SnapshotRecord` test configuration 重录。
//  禁止盲目 record 掉所有快照（反模式，等同 test evasion）。
//
//  位置说明：本文件放在 SnapDrillFeaturesTests 而非 SnapDrillUITests(SPM)，
//  原因 —— Xcode 原生 `SnapDrillUITests` (XCUITest) 与 SPM `SnapDrillUITests`
//  命名冲突，且 AllTests scheme 只纳入 Core/Data/FeaturesTests。
//  放 FeaturesTests 可确保 CI 真实执行。
//
//  覆盖范围：SnapDrillUI 层 public View。Features 层 internal View 覆盖由
//  FeatureSnapshotTests 通过 `@testable import SnapDrillFeature*` 承担。
//
//  swift-testing 迁移（Issue #699 PR #5）：
//  - `@Suite + struct` 替代 `XCTestCase 子类`；struct 默认 nonisolated 不需显式标
//  - `.snapshots` trait 启用 swift-testing 原生 record mode 传递
//  - 函数名保留 `test` 前缀以维持 baseline 路径 `__Snapshots__/SnapshotRegressionTests/testXxx.1.png` 不变
//

import SnapshotTesting
import SwiftUI
import SnapDrillCore
import SnapDrillUI
import Testing

@Suite("SnapDrillUI 层 public View 视觉回归", .snapshots)
struct SnapshotRegressionTests {

    // MARK: - SnapDrillButton

    @MainActor
    @Test("SnapDrillButton 默认样式")
    func testSnapDrillButton_default() {
        let view = SnapDrillButton(title: "主要操作") { }
            .padding()
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - ProgressLoadingView

    @MainActor
    @Test("ProgressLoadingView 带进度")
    func testProgressLoadingView_withProgress() {
        let view = ProgressLoadingView(message: "正在导出 PDF...", progress: 0.65)
            .frame(width: 390, height: 400)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    @MainActor
    @Test("ProgressLoadingView 无进度（不确定态）")
    func testProgressLoadingView_indeterminate() {
        let view = ProgressLoadingView(message: "正在同步数据...")
            .frame(width: 390, height: 400)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - ErrorMessageView

    @MainActor
    @Test("ErrorMessageView 默认无按钮")
    func testErrorMessageView_default() {
        let view = ErrorMessageView(
            title: "加载失败",
            message: "请检查网络连接后重试"
        )
        .frame(width: 390, height: 300)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    @MainActor
    @Test("ErrorMessageView 带重试按钮")
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
    @Test("ContextualErrorView dataCorrupted 语义")
    func testContextualErrorView_dataCorrupted() {
        let view = ContextualErrorView(error: .dataCorrupted)
            .frame(width: 390, height: 400)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - TipPopoverContent

    @MainActor
    @Test("TipPopoverContent 默认样式")
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
