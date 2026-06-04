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

    // MARK: - L3 动态维度系统 E2E

    /// 启动参数：强制中文 locale，使内置维度 seed 出中文名（学科/来源/年级/标签）
    private func l3LaunchArguments() -> [String] {
        [
            "--uitesting",
            "-hasCompletedOnboarding", "YES",
            "-tip.fieldConfig.v1.seen", "YES",
            "-tip.reviewSwipe.v1.seen", "YES",
            "-AppleLanguages", "(zh-Hans)",
            "-AppleLocale", "zh_CN"
        ]
    }

    /// 步骤①：启动竞态修复验证 —— 连续冷启动多次，每次都应稳定进入主界面
    /// （防 ProfileManager 环境注入冷启动崩溃复发）
    func testLaunchStabilityAcrossRelaunches() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        for i in 1...5 {
            app.launch()
            XCTAssertTrue(
                app.tabBars.firstMatch.waitForExistence(timeout: 10),
                "第 \(i) 次冷启动应在 10 秒内进入主界面（tab bar 出现）；未出现=启动崩溃/卡死复发"
            )
            app.terminate()
        }
    }

    /// 步骤②：L3 seed —— 全新库应自动种出 4 个内置维度，且单/多值语义正确
    func testSeedBuiltInDimensions() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        // 进设置 Tab（顺序 Dashboard0/题库1/采集2/复习3/设置4）
        let settingsTab = app.tabBars.buttons.element(boundBy: 4)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "设置 Tab 应出现")
        settingsTab.tap()

        // 「管理分类维度」在设置列表下方（List 懒加载），需滚动到位再点
        let manageRow = app.buttons["settings.manageCategories"]
        scrollUntilHittable(manageRow, in: app)
        XCTAssertTrue(manageRow.waitForExistence(timeout: 5), "设置应有‘管理分类维度’入口")
        manageRow.tap()

        // 4 个内置维度都应出现（按 systemKey 的 identifier，locale 无关）
        for key in ["subject", "source", "grade", "tag"] {
            XCTAssertTrue(
                app.buttons["dim.row.\(key)"].waitForExistence(timeout: 5),
                "应种出内置维度 dim.row.\(key)"
            )
        }

        // 学科 = 单值（允许多选关）+ 含「数学」值
        app.buttons["dim.row.subject"].tap()
        let subjectMulti = app.switches["dim.multiToggle"]
        XCTAssertTrue(subjectMulti.waitForExistence(timeout: 5), "学科详情应有‘允许多选’开关")
        XCTAssertEqual(subjectMulti.value as? String, "0", "学科应为单值（允许多选=关）")
        XCTAssertTrue(app.buttons["dimValue.数学"].waitForExistence(timeout: 3), "学科下应种有‘数学’值")

        // 返回 → 标签 = 多值（允许多选开）
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["dim.row.tag"].tap()
        let tagMulti = app.switches["dim.multiToggle"]
        XCTAssertTrue(tagMulti.waitForExistence(timeout: 5), "标签详情应有‘允许多选’开关")
        XCTAssertEqual(tagMulti.value as? String, "1", "标签应为多值（允许多选=开）")
    }

    /// 步骤④：用户可新建自定义维度「章节」（单值）并加值（L3 核心卖点）
    func testCreateCustomDimensionWithValues() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        // 进维度管理
        let settingsTab = app.tabBars.buttons.element(boundBy: 4)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "设置 Tab 应出现")
        settingsTab.tap()
        let manageRow = app.buttons["settings.manageCategories"]
        scrollUntilHittable(manageRow, in: app)
        XCTAssertTrue(manageRow.waitForExistence(timeout: 5), "应有‘管理分类维度’入口")
        manageRow.tap()

        // 新建维度「章节」（单值：不开多选）
        let addDim = app.buttons["dim.add"]
        XCTAssertTrue(addDim.waitForExistence(timeout: 5), "应有新建维度按钮")
        addDim.tap()
        let dimName = app.textFields["dimEdit.nameField"]
        XCTAssertTrue(dimName.waitForExistence(timeout: 5), "新建维度应有名称输入框")
        dimName.tap()
        dimName.typeText("章节")
        app.buttons["保存"].tap()

        // 「章节」应出现在维度列表（自定义维度，identifier 走 name）
        let chapterRow = app.buttons["dim.row.章节"]
        XCTAssertTrue(chapterRow.waitForExistence(timeout: 5), "自定义维度‘章节’应出现在列表")
        chapterRow.tap()

        // 加两个值「第一章」「第二章」
        for valueName in ["第一章", "第二章"] {
            let addValue = app.buttons["dimValue.add"]
            XCTAssertTrue(addValue.waitForExistence(timeout: 5), "应有添加值按钮")
            addValue.tap()
            let valField = app.textFields["dimValueEdit.nameField"]
            XCTAssertTrue(valField.waitForExistence(timeout: 5), "添加值应有名称输入框")
            valField.tap()
            valField.typeText(valueName)
            app.buttons["保存"].tap()
            XCTAssertTrue(
                app.buttons["dimValue.\(valueName)"].waitForExistence(timeout: 5),
                "值‘\(valueName)’应加入列表"
            )
        }
    }

    /// 在可滚动容器里向上滑动直到目标元素可点击（应对 List 懒加载/折叠在下方的行）
    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 8) {
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
    }
}
