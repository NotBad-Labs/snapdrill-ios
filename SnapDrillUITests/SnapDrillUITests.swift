//
//  SnapDrillUITests.swift
//  SnapDrillUITests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  端到端 UI 测试：验证核心用户路径的完整性。
//  XCTest 生命周期方法 (setUp/tearDown) 从 nonisolated 上下文调用，
//  但 XCUIApplication API 需要 MainActor。
//  解决方案：App 启动逻辑放在 @MainActor 的测试方法内。
//

import XCTest

@MainActor
final class SnapDrillUITests: XCTestCase {

    // MARK: - Helpers

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        // --uitesting: 触发 DependencyContainer in-memory 模式
        // -hasCompletedOnboarding YES: 通过 NSUserDefaults launch arguments 跳过引导页
        //   （NSUserDefaults 处理 launch arguments 早于任何 Swift 代码执行）
        app.launchArguments = [
            "--uitesting",
            "-hasCompletedOnboarding", "YES",
            "-tip.fieldConfig.v1.seen", "YES",
            "-tip.reviewSwipe.v1.seen", "YES"
        ]
        app.launch()
        return app
    }

    // MARK: - E2E: 手动录入闭环

    /// 手动录入 -> 保存 -> 切换到题库 -> 验证题目出现
    func testManualEntryToLibrary() {
        let app = launchApp()

        // 1. 切换到采集 Tab（顺序：Dashboard(0), Library(1), Capture(2), Review(3), Settings(4)）
        let captureTab = app.tabBars.buttons.element(boundBy: 2)
        XCTAssertTrue(captureTab.waitForExistence(timeout: 5), "采集 Tab 应在 5 秒内出现")
        captureTab.tap()

        // 2. 点击手动录入
        let manualButton = app.buttons["capture.manual"]
        XCTAssertTrue(manualButton.waitForExistence(timeout: 5), "手动录入按钮应出现")
        manualButton.tap()

        // 3. 在 TextEditor 中输入内容
        let contentEditor = app.textViews["capture.contentEditor"]
        XCTAssertTrue(contentEditor.waitForExistence(timeout: 3), "内容编辑器应出现")
        contentEditor.tap()
        contentEditor.typeText("E2E UI Test Item")

        // 4. 点击保存
        let saveButton = app.buttons["capture.saveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "保存按钮应出现")
        saveButton.tap()

        // 5. 等待保存完成和导航返回（含 300ms 延迟 + 动画时间）
        //    如果出现错误弹窗，也是保存失败的信号
        let errorAlert = app.alerts.firstMatch
        let saveSucceeded = manualButton.waitForExistence(timeout: 10)
        if !saveSucceeded {
            // 检查是否有错误弹窗
            if errorAlert.exists {
                XCTFail("保存失败，出现错误弹窗: \(errorAlert.label)")
            } else {
                XCTFail("保存后未返回采集首页（可能卡在结果编辑页或引导 Tip）")
            }
            return
        }

        // 6. 切换到题库 Tab
        let libraryTab = app.tabBars.buttons.element(boundBy: 1)
        libraryTab.tap()

        // 7. 验证题目出现在题库中
        let itemText = app.staticTexts["E2E UI Test Item"]
        XCTAssertTrue(
            itemText.waitForExistence(timeout: 10),
            "保存的题目应出现在题库列表中"
        )
    }
}
