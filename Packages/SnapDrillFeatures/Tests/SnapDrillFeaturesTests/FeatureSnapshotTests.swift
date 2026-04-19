//
//  FeatureSnapshotTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/04/19.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Features 层 internal View 视觉回归测试（Codex 3 PR 方案 PR3）。
//  与 SnapshotRegressionTests（SnapDrillUI 层 public View）互补，
//  通过 @testable import 访问 Features 模块 internal 类型。
//
//  覆盖：
//  - Dashboard：ReviewHeroCard / BentoCard
//  - Capture：CaptureMethodCard / CornerBracketShape
//  - Settings：SettingsRow
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import SnapDrillFeatureDashboard
@testable import SnapDrillFeatureCapture
@testable import SnapDrillFeatureSettings

nonisolated final class FeatureSnapshotTests: XCTestCase {

    // MARK: - Dashboard.ReviewHeroCard

    @MainActor
    func testReviewHeroCard_newUser_noItems() {
        let view = ReviewHeroCard(
            totalCount: 0,
            dueCount: 0,
            reviewedTodayCount: 0,
            onStartReview: {},
            onStartCapture: {}
        )
        .frame(width: 390, height: 260)
        .padding()
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    @MainActor
    func testReviewHeroCard_withDueItems() {
        let view = ReviewHeroCard(
            totalCount: 100,
            dueCount: 12,
            reviewedTodayCount: 5,
            onStartReview: {},
            onStartCapture: {}
        )
        .frame(width: 390, height: 260)
        .padding()
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    @MainActor
    func testReviewHeroCard_allCompleted() {
        let view = ReviewHeroCard(
            totalCount: 100,
            dueCount: 0,
            reviewedTodayCount: 18,
            onStartReview: {},
            onStartCapture: {}
        )
        .frame(width: 390, height: 260)
        .padding()
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Dashboard.BentoCard

    @MainActor
    func testBentoCard_interactive() {
        let view = BentoCard(
            title: "智能扫描",
            subtitle: "录入新题",
            icon: "camera.viewfinder",
            gradient: LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            action: {}
        )
        .frame(width: 180, height: 180)
        .padding()
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    @MainActor
    func testBentoCard_display() {
        // action 为 nil 的展示模式
        let view = BentoCard(
            title: "题库浏览",
            subtitle: "管理知识",
            icon: "books.vertical.fill",
            gradient: LinearGradient(
                colors: [.orange, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            action: nil
        )
        .frame(width: 180, height: 180)
        .padding()
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Capture.CaptureMethodCard

    @MainActor
    func testCaptureMethodCard_default() {
        let view = CaptureMethodCard(
            icon: "camera.fill",
            title: "拍照识题",
            subtitle: "自动裁剪与识别",
            color: .blue,
            accessibilityHint: "",
            action: {}
        )
        .frame(width: 170, height: 140)
        .padding()
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Capture.CornerBracketShape

    @MainActor
    func testCornerBracketShape_default() {
        let view = CornerBracketShape()
            .stroke(Color.yellow, lineWidth: 3)
            .frame(width: 200, height: 200)
            .padding()
            .background(Color.black)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Settings.SettingsRow

    @MainActor
    func testSettingsRow_withValue() {
        let view = SettingsRow(
            icon: "person.crop.circle",
            gradientStart: .blue,
            gradientEnd: .purple,
            title: "个人资料",
            value: "已设置"
        )
        .frame(width: 390)
        .padding()
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    @MainActor
    func testSettingsRow_noValue() {
        let view = SettingsRow(
            icon: "bell.fill",
            gradientStart: .orange,
            gradientEnd: .red,
            title: "通知设置",
            value: nil
        )
        .frame(width: 390)
        .padding()
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
