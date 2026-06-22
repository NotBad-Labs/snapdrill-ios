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

    @discardableResult
    private func waitForAnyElement(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 8,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier]
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "应出现 UI 元素：\(identifier)", file: file, line: line)
        return element
    }

    private func addScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func waitForUIAnimation(seconds: TimeInterval = 0.8) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

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

    private func l3AccessibilityLaunchArguments() -> [String] {
        l3LaunchArguments() + [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
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

    /// UI-freeze evidence: capture the app-shell degraded-mode banner.
    func testUIFreezeAppShellDegradedBannerScreenshot() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments() + ["--ui-test-force-degraded-banner"]
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "主 tab bar 应出现")
        waitForAnyElement("app.degradedBanner", in: app)
        addScreenshot(named: "ui-freeze-app-shell-01-degraded-banner")
    }

    /// UI-freeze evidence: capture the five primary tabs in a clean, empty-library state.
    func testUIFreezePrimaryTabSurfaceScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "主 tab bar 应出现")

        waitForAnyElement("dashboard.root", in: app)
        addScreenshot(named: "ui-freeze-01-dashboard-empty")

        app.tabBars.buttons.element(boundBy: 1).tap()
        waitForAnyElement("library.root", in: app)
        addScreenshot(named: "ui-freeze-02-library-empty")

        app.tabBars.buttons.element(boundBy: 2).tap()
        waitForAnyElement("capture.root", in: app)
        XCTAssertTrue(app.buttons["capture.manual"].waitForExistence(timeout: 5), "采集页应显示手动录入入口")
        addScreenshot(named: "ui-freeze-03-capture-methods")

        app.tabBars.buttons.element(boundBy: 3).tap()
        waitForAnyElement("review.root", in: app)
        addScreenshot(named: "ui-freeze-04-review-empty")

        app.tabBars.buttons.element(boundBy: 4).tap()
        waitForAnyElement("settings.root", in: app)
        addScreenshot(named: "ui-freeze-05-settings-main")
    }

    /// UI-freeze evidence: capture the five primary tabs at AX XXXL Dynamic Type size.
    func testUIFreezePrimaryTabAccessibilityTextScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3AccessibilityLaunchArguments()
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "主 tab bar 应出现")

        waitForAnyElement("dashboard.root", in: app)
        addScreenshot(named: "ui-freeze-primary-ax-01-dashboard-empty")

        app.tabBars.buttons.element(boundBy: 1).tap()
        waitForAnyElement("library.root", in: app)
        addScreenshot(named: "ui-freeze-primary-ax-02-library-empty")

        app.tabBars.buttons.element(boundBy: 2).tap()
        waitForAnyElement("capture.root", in: app)
        XCTAssertTrue(app.buttons["capture.manual"].waitForExistence(timeout: 5), "AX 字号下采集页应显示手动录入入口")
        addScreenshot(named: "ui-freeze-primary-ax-03-capture-methods")

        app.tabBars.buttons.element(boundBy: 3).tap()
        waitForAnyElement("review.root", in: app)
        addScreenshot(named: "ui-freeze-primary-ax-04-review-empty")

        app.tabBars.buttons.element(boundBy: 4).tap()
        waitForAnyElement("settings.root", in: app)
        addScreenshot(named: "ui-freeze-primary-ax-05-settings-main")
    }

    /// UI-freeze evidence: capture Capture method-grid bottom reachability at normal and AX sizes.
    func testUIFreezeCaptureMethodGridDeepScrollScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "主 tab bar 应出现")
        app.tabBars.buttons.element(boundBy: 2).tap()
        waitForAnyElement("capture.root", in: app)

        let pdfButton = app.buttons["capture.pdf"]
        scrollUntilHittable(pdfButton, in: app, maxSwipes: 4)
        XCTAssertTrue(pdfButton.waitForExistence(timeout: 5), "普通字号下 PDF 导入入口应可滚动到安全区域")
        app.swipeUp()
        waitForUIAnimation(seconds: 0.4)
        addScreenshot(named: "ui-freeze-capture-methods-deep-01-regular-bottom")
        app.terminate()

        let accessibilityApp = XCUIApplication()
        accessibilityApp.launchArguments = l3AccessibilityLaunchArguments()
        accessibilityApp.launch()

        XCTAssertTrue(accessibilityApp.tabBars.firstMatch.waitForExistence(timeout: 10), "AX 字号下主 tab bar 应出现")
        accessibilityApp.tabBars.buttons.element(boundBy: 2).tap()
        waitForAnyElement("capture.root", in: accessibilityApp)

        let accessibilityPDFButton = accessibilityApp.buttons["capture.pdf"]
        scrollUntilHittable(accessibilityPDFButton, in: accessibilityApp, maxSwipes: 8)
        XCTAssertTrue(accessibilityPDFButton.waitForExistence(timeout: 5), "AX 字号下 PDF 导入入口应可滚动到安全区域")
        accessibilityApp.swipeUp()
        waitForUIAnimation(seconds: 0.4)
        addScreenshot(named: "ui-freeze-capture-methods-deep-02-ax-bottom")
    }

    /// UI-freeze evidence: capture first-run onboarding pages and completion path.
    func testUIFreezeOnboardingPagedScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "-hasCompletedOnboarding", "NO",
            "-AppleLanguages", "(zh-Hans)",
            "-AppleLocale", "zh_CN"
        ]
        app.launch()

        waitForAnyElement("onboarding.root", in: app, timeout: 10)
        XCTAssertTrue(app.buttons["onboarding.skip"].waitForExistence(timeout: 5), "引导页应提供跳过按钮")
        XCTAssertTrue(app.buttons["onboarding.next"].waitForExistence(timeout: 5), "引导页第一页应提供下一页按钮")
        addScreenshot(named: "ui-freeze-onboarding-01-welcome")

        app.buttons["onboarding.next"].tap()
        waitForUIAnimation()
        XCTAssertTrue(app.descendants(matching: .any)["onboarding.page.1"].waitForExistence(timeout: 5), "应进入第二页")
        XCTAssertTrue(app.buttons["onboarding.previous"].waitForExistence(timeout: 5), "第二页起应提供上一页按钮")
        addScreenshot(named: "ui-freeze-onboarding-02-capture")

        app.buttons["onboarding.next"].tap()
        waitForUIAnimation()
        XCTAssertTrue(app.descendants(matching: .any)["onboarding.page.2"].waitForExistence(timeout: 5), "应进入第三页")
        addScreenshot(named: "ui-freeze-onboarding-03-review")

        app.buttons["onboarding.next"].tap()
        waitForUIAnimation()
        XCTAssertTrue(app.descendants(matching: .any)["onboarding.page.3"].waitForExistence(timeout: 5), "应进入最后一页")
        XCTAssertTrue(app.buttons["onboarding.getStarted"].waitForExistence(timeout: 5), "最后一页应提供开始使用按钮")
        addScreenshot(named: "ui-freeze-onboarding-04-export")

        app.buttons["onboarding.getStarted"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "完成引导后应进入主界面")
        addScreenshot(named: "ui-freeze-onboarding-05-completed")
    }

    /// UI-freeze evidence: capture onboarding at accessibility Dynamic Type size and verify skip path.
    func testUIFreezeOnboardingAccessibilityTextScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "-hasCompletedOnboarding", "NO",
            "-AppleLanguages", "(zh-Hans)",
            "-AppleLocale", "zh_CN",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        waitForAnyElement("onboarding.root", in: app, timeout: 10)
        XCTAssertTrue(app.buttons["onboarding.skip"].waitForExistence(timeout: 5), "AX 字号下仍应提供跳过按钮")
        XCTAssertTrue(app.buttons["onboarding.next"].waitForExistence(timeout: 5), "AX 字号下仍应提供下一页按钮")
        addScreenshot(named: "ui-freeze-onboarding-06-accessibility-text")

        app.buttons["onboarding.skip"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "跳过引导后应进入主界面")
        addScreenshot(named: "ui-freeze-onboarding-07-skip-completed")
    }

    /// UI-freeze evidence: capture the manual Capture result editor and metadata controls.
    func testUIFreezeCaptureManualResultEditorScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        app.tabBars.buttons.element(boundBy: 2).tap()
        waitForAnyElement("capture.root", in: app)
        app.buttons["capture.manual"].tap()

        waitForAnyElement("capture.result.root", in: app)
        waitForAnyElement("capture.contentEditor", in: app)
        addScreenshot(named: "ui-freeze-capture-01-manual-empty-editor")

        let editor = app.textViews["capture.contentEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5), "手动录入编辑器应出现")
        editor.tap()
        editor.typeText("Capture QA manual content")
        dismissKeyboardIfPresent(in: app)
        addScreenshot(named: "ui-freeze-capture-02-manual-filled-editor")

        let subjectRow = app.buttons["capture.dimRow.学科"]
        scrollUntilHittable(subjectRow, in: app)
        XCTAssertTrue(subjectRow.waitForExistence(timeout: 5), "手动录入表单应显示学科字段")
        subjectRow.tap()
        let mathOption = app.buttons["capture.opt.数学"]
        XCTAssertTrue(mathOption.waitForExistence(timeout: 5), "学科菜单应显示数学选项")
        addScreenshot(named: "ui-freeze-capture-03-subject-menu")
        mathOption.tap()
        addScreenshot(named: "ui-freeze-capture-04-subject-selected")

        let save = app.buttons["capture.saveButton"]
        XCTAssertTrue(save.waitForExistence(timeout: 5), "保存按钮应仍然可用")
        save.tap()
        waitForAnyElement("capture.root", in: app, timeout: 10)
        addScreenshot(named: "ui-freeze-capture-05-saved-back-to-capture")
    }

    /// UI-freeze evidence: capture populated Review dashboard, active session, card back, summary, and done state.
    func testUIFreezeReviewPopulatedSessionScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments() + ["-captureFieldAnswer", "YES"]
        app.launch()

        createManualItem(
            content: "Review QA Alpha",
            subject: "数学",
            answer: "Reference answer for Review QA Alpha",
            in: app
        )

        app.tabBars.buttons.element(boundBy: 3).tap()
        XCTAssertTrue(app.buttons["review.startButton"].waitForExistence(timeout: 10), "有待回顾项目时应显示开始回顾按钮")
        addScreenshot(named: "ui-freeze-review-01-dashboard-due")

        app.buttons["review.startButton"].tap()
        waitForAnyElement("review.rate.good", in: app)
        addScreenshot(named: "ui-freeze-review-02-session-front")

        app.buttons["review.toggleAnswer"].tap()
        waitForUIAnimation()
        addScreenshot(named: "ui-freeze-review-03-session-back")

        app.buttons["review.rate.good"].tap()
        waitForAnyElement("review.summary.dismiss", in: app, timeout: 10)
        addScreenshot(named: "ui-freeze-review-04-summary")

        app.buttons["review.summary.dismiss"].tap()
        XCTAssertTrue(app.staticTexts["暂无待回顾内容"].waitForExistence(timeout: 10), "完成后应回到无待回顾状态")
        addScreenshot(named: "ui-freeze-review-05-dashboard-done")
    }

    /// UI-freeze evidence: capture Review multi-card, pause, edit-sheet, and undo states.
    func testUIFreezeReviewInteractionSurfaceScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments() + ["-captureFieldAnswer", "YES"]
        app.launch()

        createManualItem(
            content: "Review QA First",
            subject: "数学",
            answer: "Reference answer for Review QA First",
            in: app
        )
        createManualItem(
            content: "Review QA Second",
            subject: "语文",
            answer: "Reference answer for Review QA Second",
            in: app
        )

        app.tabBars.buttons.element(boundBy: 3).tap()
        XCTAssertTrue(app.buttons["review.startButton"].waitForExistence(timeout: 10), "多卡回顾数据应显示开始按钮")
        app.buttons["review.startButton"].tap()
        waitForAnyElement("review.rate.good", in: app)
        XCTAssertTrue(app.staticTexts["1/2"].waitForExistence(timeout: 5), "多卡会话应显示 1/2 进度")
        addScreenshot(named: "ui-freeze-review-06-multi-card-front")

        app.buttons["review.pause"].tap()
        let pauseAlert = app.alerts["确认暂停回顾？"]
        XCTAssertTrue(pauseAlert.waitForExistence(timeout: 5), "暂停应显示确认弹窗")
        addScreenshot(named: "ui-freeze-review-07-pause-alert")
        pauseAlert.buttons["继续"].tap()
        waitForAnyElement("review.rate.good", in: app)

        let frontCardMore = app.buttons.matching(identifier: "review.card.front.more").firstMatch
        XCTAssertTrue(frontCardMore.waitForExistence(timeout: 5), "正面卡片应提供更多操作菜单")
        frontCardMore.tap()
        app.buttons["编辑题目"].tap()
        waitForAnyElement("library.edit.root", in: app)
        addScreenshot(named: "ui-freeze-review-08-front-edit-sheet")
        app.buttons["取消"].tap()
        waitForAnyElement("review.rate.good", in: app)

        app.buttons["review.toggleAnswer"].tap()
        waitForUIAnimation()
        let backCardMore = app.buttons.matching(identifier: "review.card.back.more").firstMatch
        XCTAssertTrue(backCardMore.waitForExistence(timeout: 5), "背面卡片应提供更多操作菜单")
        backCardMore.tap()
        app.buttons["编辑内容"].tap()
        waitForAnyElement("library.edit.root", in: app)
        addScreenshot(named: "ui-freeze-review-09-back-edit-sheet")
        app.buttons["取消"].tap()
        waitForAnyElement("review.rate.good", in: app)

        app.buttons["review.rate.good"].tap()
        waitForUIAnimation()
        XCTAssertTrue(app.buttons["review.undo"].isEnabled, "评分一次后撤销按钮应可用")
        addScreenshot(named: "ui-freeze-review-10-undo-enabled")

        app.buttons["review.undo"].tap()
        waitForUIAnimation()
        XCTAssertTrue(app.staticTexts["1/2"].waitForExistence(timeout: 5), "撤销后应回到 1/2 进度")
        addScreenshot(named: "ui-freeze-review-11-after-undo")
    }

    /// UI-freeze evidence: capture physical horizontal drag gestures on Review cards.
    func testUIFreezeReviewSwipeGestureScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments() + ["-captureFieldAnswer", "YES"]
        app.launch()

        createManualItem(
            content: "Review Swipe First",
            subject: "数学",
            answer: "Reference answer for Review Swipe First",
            in: app
        )
        createManualItem(
            content: "Review Swipe Second",
            subject: "语文",
            answer: "Reference answer for Review Swipe Second",
            in: app
        )

        app.tabBars.buttons.element(boundBy: 3).tap()
        XCTAssertTrue(app.buttons["review.startButton"].waitForExistence(timeout: 10), "拖拽测试应显示开始回顾按钮")
        app.buttons["review.startButton"].tap()
        waitForAnyElement("review.rate.good", in: app)
        XCTAssertTrue(app.staticTexts["1/2"].waitForExistence(timeout: 5), "拖拽前应处在第一张卡")

        dragReviewCard(in: app, direction: .left)
        XCTAssertTrue(app.staticTexts["2/2"].waitForExistence(timeout: 5), "左拖后应进入第二张卡")
        XCTAssertTrue(app.buttons["review.undo"].isEnabled, "左拖评分后撤销按钮应可用")
        addScreenshot(named: "ui-freeze-review-12-after-left-drag")

        app.buttons["review.undo"].tap()
        waitForUIAnimation()
        XCTAssertTrue(app.staticTexts["1/2"].waitForExistence(timeout: 5), "撤销后应回到第一张卡")
        XCTAssertFalse(app.buttons["review.undo"].isEnabled, "撤销回第一张后撤销按钮应回到禁用态")
        addScreenshot(named: "ui-freeze-review-13-after-drag-undo")

        dragReviewCard(in: app, direction: .right)
        XCTAssertTrue(app.staticTexts["2/2"].waitForExistence(timeout: 5), "右拖后应进入第二张卡")
        XCTAssertTrue(app.buttons["review.undo"].isEnabled, "右拖评分后撤销按钮应可用")
        addScreenshot(named: "ui-freeze-review-14-after-right-drag")
    }

    /// UI-freeze evidence: capture populated Dashboard hero, shortcuts, analytics gate, category sheet, and all-done state.
    func testUIFreezeDashboardPopulatedSurfaceScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        createManualItem(content: "Dashboard QA Due", subject: "数学", in: app)

        app.tabBars.buttons.element(boundBy: 0).tap()
        waitForAnyElement("dashboard.root", in: app)
        XCTAssertTrue(app.buttons["dashboard.hero.startReview"].waitForExistence(timeout: 10), "首页有待回顾项目时应显示立即开始")
        addScreenshot(named: "ui-freeze-dashboard-01-populated-due")

        let categoryEntry = app.buttons["dashboard.bento.categories"]
        scrollUntilHittable(categoryEntry, in: app)
        XCTAssertTrue(categoryEntry.waitForExistence(timeout: 5), "首页应显示管理分类入口")
        XCTAssertTrue(categoryEntry.isHittable, "首页管理分类入口应可点击")
        categoryEntry.tap()
        waitForAnyElement("settings.categoryManager.root", in: app)
        addScreenshot(named: "ui-freeze-dashboard-02-category-sheet")
        app.navigationBars.buttons["关闭"].tap()
        waitForAnyElement("dashboard.root", in: app)

        app.swipeUp()
        XCTAssertTrue(
            app.descendants(matching: .any)["dashboard.analytics.proGate"].waitForExistence(timeout: 5),
            "首页下半区应显示统计门控占位"
        )
        addScreenshot(named: "ui-freeze-dashboard-03-analytics-gate")

        app.tabBars.buttons.element(boundBy: 3).tap()
        XCTAssertTrue(app.buttons["review.startButton"].waitForExistence(timeout: 10), "回顾页应显示待回顾开始按钮")
        app.buttons["review.startButton"].tap()
        waitForAnyElement("review.rate.good", in: app)
        app.buttons["review.rate.good"].tap()
        waitForAnyElement("review.summary.dismiss", in: app, timeout: 10)
        app.buttons["review.summary.dismiss"].tap()

        app.tabBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["今日已完成"].waitForExistence(timeout: 10), "完成回顾后首页应显示 all-done Hero")
        app.swipeDown()
        app.swipeDown()
        addScreenshot(named: "ui-freeze-dashboard-04-all-done")
    }

    /// UI-freeze evidence: capture stable Settings secondary pages without mutating user data.
    func testUIFreezeSettingsSecondarySurfaceScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "主 tab bar 应出现")
        app.tabBars.buttons.element(boundBy: 4).tap()
        waitForAnyElement("settings.root", in: app)

        let routes: [(entry: String, root: String, screenshot: String)] = [
            ("settings.editProfile", "settings.editProfile.root", "ui-freeze-settings-01-edit-profile"),
            ("settings.profileList", "settings.profileList.root", "ui-freeze-settings-02-profile-list"),
            ("settings.reviewAppearance", "settings.reviewAppearance.root", "ui-freeze-settings-03-review-appearance"),
            ("settings.notifications", "settings.notifications.root", "ui-freeze-settings-04-notifications"),
            ("settings.dataAndSync", "settings.dataAndSync.root", "ui-freeze-settings-05-data-sync"),
            ("settings.storage", "settings.storage.root", "ui-freeze-settings-06-storage"),
            ("settings.privacyExport", "settings.privacyExport.root", "ui-freeze-settings-07-privacy-export"),
            ("settings.language", "settings.language.root", "ui-freeze-settings-08-language"),
            ("settings.manageCategories", "settings.categoryManager.root", "ui-freeze-settings-09-category-manager"),
            ("settings.privacyPolicy", "settings.privacyPolicy.root", "ui-freeze-settings-10-privacy-policy"),
            ("settings.terms", "settings.terms.root", "ui-freeze-settings-11-terms")
        ]

        for route in routes {
            let entry = app.descendants(matching: .any)[route.entry]
            scrollUntilHittable(entry, in: app, maxSwipes: 10)
            XCTAssertTrue(entry.waitForExistence(timeout: 5), "设置入口应出现：\(route.entry)")
            XCTAssertTrue(entry.isHittable, "设置入口应可点击：\(route.entry)")
            entry.tap()

            waitForAnyElement(route.root, in: app)
            addScreenshot(named: route.screenshot)

            app.navigationBars.buttons.element(boundBy: 0).tap()
            waitForAnyElement("settings.root", in: app)
        }
    }

    /// UI-freeze evidence: capture Profile/taxonomy selection controls and symbol-picker search states.
    func testUIFreezeTaxonomyControlStateScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "主 tab bar 应出现")
        app.tabBars.buttons.element(boundBy: 4).tap()
        waitForAnyElement("settings.root", in: app)

        let editProfile = app.descendants(matching: .any)["settings.editProfile"]
        XCTAssertTrue(editProfile.waitForExistence(timeout: 5), "设置应显示编辑个人资料入口")
        editProfile.tap()
        waitForAnyElement("settings.editProfile.root", in: app)

        let secondProfileColor = app.buttons["settings.editProfile.color.1"]
        scrollUntilHittable(secondProfileColor, in: app, maxSwipes: 6)
        XCTAssertTrue(secondProfileColor.waitForExistence(timeout: 5), "Profile 主题色应可定位")
        secondProfileColor.tap()
        waitForUIAnimation(seconds: 0.4)
        addScreenshot(named: "ui-freeze-taxonomy-01-profile-color-selected")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForAnyElement("settings.root", in: app)

        let manageCategories = app.buttons["settings.manageCategories"]
        scrollUntilHittable(manageCategories, in: app, maxSwipes: 10)
        XCTAssertTrue(manageCategories.waitForExistence(timeout: 5), "设置应有分类管理入口")
        manageCategories.tap()
        waitForAnyElement("settings.categoryManager.root", in: app)

        app.buttons["dim.row.subject"].tap()
        waitForAnyElement("dimValueList.root.subject", in: app)
        addScreenshot(named: "ui-freeze-taxonomy-02-subject-values")

        app.buttons["dimValue.数学"].tap()
        waitForAnyElement("dimValueEdit.root", in: app)
        addScreenshot(named: "ui-freeze-taxonomy-03-edit-value-default-color")

        let redSwatch = app.buttons["dimValueEdit.color.E57373"]
        XCTAssertTrue(redSwatch.waitForExistence(timeout: 5), "分类值颜色 swatch 应可定位")
        redSwatch.tap()
        waitForUIAnimation(seconds: 0.4)
        addScreenshot(named: "ui-freeze-taxonomy-04-edit-value-selected-color")

        app.buttons["dimValueEdit.iconPicker"].tap()
        waitForAnyElement("symbolPicker.category.common", in: app)
        addScreenshot(named: "ui-freeze-taxonomy-05-symbol-picker-default")

        let searchField = app.textFields["symbolPicker.searchField"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "图标选择器应提供搜索框")
        searchField.tap()
        searchField.typeText("zzzzzz")
        dismissKeyboardIfPresent(in: app)
        waitForAnyElement("symbolPicker.empty", in: app)
        addScreenshot(named: "ui-freeze-taxonomy-06-symbol-picker-empty-search")
    }

    /// UI-freeze evidence: capture taxonomy add/delete edge states for dimensions and values.
    func testUIFreezeTaxonomyEdgeStateScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "主 tab bar 应出现")
        app.tabBars.buttons.element(boundBy: 4).tap()
        waitForAnyElement("settings.root", in: app)

        let manageCategories = app.buttons["settings.manageCategories"]
        scrollUntilHittable(manageCategories, in: app, maxSwipes: 10)
        XCTAssertTrue(manageCategories.waitForExistence(timeout: 5), "设置应有分类管理入口")
        manageCategories.tap()
        waitForAnyElement("settings.categoryManager.root", in: app)

        app.buttons["dim.add"].tap()
        waitForAnyElement("dimEdit.root", in: app)
        addScreenshot(named: "ui-freeze-taxonomy-edge-01-add-dimension-empty")
        let dimensionName = app.textFields["dimEdit.nameField"]
        XCTAssertTrue(dimensionName.waitForExistence(timeout: 5), "新增维度应有名称输入框")
        dimensionName.tap()
        dimensionName.typeText("场景 QA")
        app.switches["dimEdit.multiToggle"].tap()
        addScreenshot(named: "ui-freeze-taxonomy-edge-02-add-dimension-filled")
        app.buttons["dimEdit.save"].tap()

        let customDimension = app.buttons["dim.row.场景 QA"]
        XCTAssertTrue(customDimension.waitForExistence(timeout: 5), "新增维度应出现在分类管理列表")
        addScreenshot(named: "ui-freeze-taxonomy-edge-03-custom-dimension-list")
        customDimension.tap()
        waitForAnyElement("dimValueList.root.场景 QA", in: app)
        addScreenshot(named: "ui-freeze-taxonomy-edge-04-empty-custom-dimension")

        app.buttons["dimValue.add"].tap()
        waitForAnyElement("dimValueEdit.root", in: app)
        let valueName = app.textFields["dimValueEdit.nameField"]
        XCTAssertTrue(valueName.waitForExistence(timeout: 5), "新增分类值应有名称输入框")
        valueName.tap()
        valueName.typeText("收据")
        let amberSwatch = app.buttons["dimValueEdit.color.FFB74D"]
        XCTAssertTrue(amberSwatch.waitForExistence(timeout: 5), "新增分类值应显示颜色 swatch")
        amberSwatch.tap()
        addScreenshot(named: "ui-freeze-taxonomy-edge-05-add-value-filled")
        app.buttons["dimValueEdit.save"].tap()

        let customValue = app.buttons["dimValue.收据"]
        XCTAssertTrue(customValue.waitForExistence(timeout: 5), "新增分类值应出现在维度详情")
        addScreenshot(named: "ui-freeze-taxonomy-edge-06-custom-value-list")
        customValue.swipeLeft()
        XCTAssertTrue(app.buttons["删除"].waitForExistence(timeout: 5), "自定义分类值应显示删除滑动操作")
        addScreenshot(named: "ui-freeze-taxonomy-edge-07-value-delete-swipe")
        app.buttons["删除"].tap()
        XCTAssertTrue(customValue.waitForNonExistence(timeout: 5), "删除后自定义分类值应消失")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForAnyElement("settings.categoryManager.root", in: app)
        let dimensionForDeletion = app.buttons["dim.row.场景 QA"]
        XCTAssertTrue(dimensionForDeletion.waitForExistence(timeout: 5), "返回后自定义维度应仍在列表")
        dimensionForDeletion.swipeLeft()
        XCTAssertTrue(app.buttons["删除"].waitForExistence(timeout: 5), "自定义维度应显示删除滑动操作")
        addScreenshot(named: "ui-freeze-taxonomy-edge-08-dimension-delete-swipe")
        app.buttons["删除"].tap()
        XCTAssertTrue(dimensionForDeletion.waitForNonExistence(timeout: 5), "删除后自定义维度应消失")
    }

    /// UI-freeze evidence: capture Settings interaction states that are not visible on first viewport.
    func testUIFreezeSettingsInteractionStateScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "主 tab bar 应出现")
        app.tabBars.buttons.element(boundBy: 4).tap()
        waitForAnyElement("settings.root", in: app)

        let profileList = app.descendants(matching: .any)["settings.profileList"]
        scrollUntilHittable(profileList, in: app, maxSwipes: 4)
        XCTAssertTrue(profileList.waitForExistence(timeout: 5), "设置应有资料空间列表入口")
        profileList.tap()
        waitForAnyElement("settings.profileList.root", in: app)

        app.buttons["settings.profileList.add"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5), "新增资料空间应显示输入弹窗")
        addScreenshot(named: "ui-freeze-settings-interactions-01-profile-add-alert")
        let profileNameField = app.alerts.firstMatch.textFields.firstMatch
        XCTAssertTrue(profileNameField.waitForExistence(timeout: 5), "新增资料空间弹窗应有名称输入框")
        profileNameField.tap()
        profileNameField.typeText("视觉 QA")
        app.alerts.firstMatch.buttons["确定"].tap()
        XCTAssertTrue(app.buttons["settings.profileList.profile.视觉 QA"].waitForExistence(timeout: 5), "新增资料空间应出现在列表")
        addScreenshot(named: "ui-freeze-settings-interactions-02-profile-multiple")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForAnyElement("settings.root", in: app)

        let language = app.buttons["settings.language"]
        scrollUntilHittable(language, in: app, maxSwipes: 8)
        XCTAssertTrue(language.waitForExistence(timeout: 5), "设置应有语言入口")
        language.tap()
        waitForAnyElement("settings.language.root", in: app)
        app.buttons["settings.language.en"].tap()
        XCTAssertTrue(app.alerts["语言已切换"].waitForExistence(timeout: 5), "切换语言应显示重启提示")
        addScreenshot(named: "ui-freeze-settings-interactions-03-language-restart-alert")
        app.alerts["语言已切换"].buttons["确定"].tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForAnyElement("settings.root", in: app)

        let privacyExport = app.buttons["settings.privacyExport"]
        scrollUntilHittable(privacyExport, in: app, maxSwipes: 8)
        XCTAssertTrue(privacyExport.waitForExistence(timeout: 5), "设置应有隐私导出入口")
        privacyExport.tap()
        waitForAnyElement("settings.privacyExport.root", in: app)
        app.buttons["settings.privacyExport.exportButton"].tap()
        XCTAssertTrue(app.buttons["JSON 格式"].waitForExistence(timeout: 5), "隐私导出应显示格式选择")
        addScreenshot(named: "ui-freeze-settings-interactions-04-privacy-export-dialog")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()
        XCTAssertTrue(app.buttons["JSON 格式"].waitForNonExistence(timeout: 5), "点空白处应关闭导出格式选择")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForAnyElement("settings.root", in: app)

        let reviewAppearance = app.buttons["settings.reviewAppearance"]
        scrollUntilHittable(reviewAppearance, in: app, maxSwipes: 8)
        XCTAssertTrue(reviewAppearance.waitForExistence(timeout: 5), "设置应有回顾外观入口")
        reviewAppearance.tap()
        waitForAnyElement("settings.reviewAppearance.root", in: app)

        let frontSlider = app.sliders["settings.reviewAppearance.frontFontSize"]
        XCTAssertTrue(frontSlider.waitForExistence(timeout: 5), "回顾外观应有正面字号滑块")
        frontSlider.adjust(toNormalizedSliderPosition: 1.0)
        addScreenshot(named: "ui-freeze-settings-interactions-05-review-front-large")

        let backSlider = app.sliders["settings.reviewAppearance.backFontSize"]
        scrollUntilHittable(backSlider, in: app, maxSwipes: 4)
        XCTAssertTrue(backSlider.waitForExistence(timeout: 5), "回顾外观应有背面字号滑块")
        backSlider.adjust(toNormalizedSliderPosition: 1.0)
        addScreenshot(named: "ui-freeze-settings-interactions-06-review-back-large")
    }

    /// UI-freeze evidence: capture Settings destructive, dialog, reminder, and license states.
    func testUIFreezeSettingsControlStateScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "主 tab bar 应出现")
        app.tabBars.buttons.element(boundBy: 4).tap()
        waitForAnyElement("settings.root", in: app)

        let profileList = app.buttons["settings.profileList"]
        scrollUntilHittable(profileList, in: app, maxSwipes: 4)
        XCTAssertTrue(profileList.waitForExistence(timeout: 5), "设置应有资料空间入口")
        profileList.tap()
        waitForAnyElement("settings.profileList.root", in: app)

        app.buttons["settings.profileList.add"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5), "新增资料空间应显示输入弹窗")
        let profileNameField = app.alerts.firstMatch.textFields.firstMatch
        XCTAssertTrue(profileNameField.waitForExistence(timeout: 5), "新增资料空间弹窗应有名称输入框")
        profileNameField.tap()
        profileNameField.typeText("删除 QA")
        app.alerts.firstMatch.buttons["确定"].tap()
        let deleteProfile = app.buttons["settings.profileList.profile.删除 QA"]
        XCTAssertTrue(deleteProfile.waitForExistence(timeout: 5), "新增资料空间应出现在列表")
        deleteProfile.swipeLeft()
        XCTAssertTrue(app.buttons["删除"].waitForExistence(timeout: 5), "多资料空间应显示删除滑动操作")
        app.buttons["删除"].tap()
        XCTAssertTrue(app.alerts["删除"].waitForExistence(timeout: 5), "删除资料空间应显示确认弹窗")
        addScreenshot(named: "ui-freeze-settings-controls-01-profile-delete-alert")
        app.alerts["删除"].buttons["取消"].tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForAnyElement("settings.root", in: app)

        let reviewAppearance = app.buttons["settings.reviewAppearance"]
        scrollUntilHittable(reviewAppearance, in: app, maxSwipes: 4)
        XCTAssertTrue(reviewAppearance.waitForExistence(timeout: 5), "设置应有回顾外观入口")
        reviewAppearance.tap()
        waitForAnyElement("settings.reviewAppearance.root", in: app)
        let frontAlignment = app.buttons["settings.reviewAppearance.frontAlignment"]
        XCTAssertTrue(frontAlignment.waitForExistence(timeout: 5), "回顾外观应有正面对齐选择")
        frontAlignment.tap()
        XCTAssertTrue(app.buttons["居中"].waitForExistence(timeout: 5), "正面对齐选择应显示居中选项")
        addScreenshot(named: "ui-freeze-settings-controls-02-review-alignment-options")
        app.buttons["居中"].tap()
        waitForAnyElement("settings.reviewAppearance.root", in: app)
        addScreenshot(named: "ui-freeze-settings-controls-03-review-centered-preview")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForAnyElement("settings.root", in: app)

        app.terminate()
        app.launchArguments = l3LaunchArguments() + [
            "-notificationsEnabled", "YES",
            "-soundEnabled", "YES"
        ]
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "主 tab bar 应出现")
        app.tabBars.buttons.element(boundBy: 4).tap()
        waitForAnyElement("settings.root", in: app)

        let notifications = app.buttons["settings.notifications"]
        scrollUntilHittable(notifications, in: app, maxSwipes: 4)
        XCTAssertTrue(notifications.waitForExistence(timeout: 5), "设置应有通知入口")
        notifications.tap()
        waitForAnyElement("settings.notifications.root", in: app)
        waitForAnyElement("settings.notifications.timePicker", in: app)
        XCTAssertTrue(app.switches["settings.notifications.soundToggle"].isEnabled, "开启通知后声音开关应可用")
        addScreenshot(named: "ui-freeze-settings-controls-04-notifications-enabled")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForAnyElement("settings.root", in: app)

        let dataAndSync = app.buttons["settings.dataAndSync"]
        scrollUntilHittable(dataAndSync, in: app, maxSwipes: 8)
        XCTAssertTrue(dataAndSync.waitForExistence(timeout: 5), "设置应有数据与备份入口")
        dataAndSync.tap()
        waitForAnyElement("settings.dataAndSync.root", in: app)
        app.buttons["settings.dataAndSync.restore"].tap()
        XCTAssertTrue(app.buttons["选择备份文件"].waitForExistence(timeout: 5), "恢复数据应显示备份文件选择确认")
        addScreenshot(named: "ui-freeze-settings-controls-05-restore-dialog")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()

        let clearCache = app.buttons["settings.dataAndSync.clearCache"]
        scrollUntilHittable(clearCache, in: app, maxSwipes: 4)
        XCTAssertTrue(clearCache.waitForExistence(timeout: 5), "数据与备份页应有清理缓存按钮")
        clearCache.tap()
        XCTAssertTrue(app.alerts["清理缓存"].waitForExistence(timeout: 5), "清理缓存应显示确认弹窗")
        addScreenshot(named: "ui-freeze-settings-controls-06-clear-cache-alert")
        app.alerts["清理缓存"].buttons["取消"].tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForAnyElement("settings.root", in: app)

        let clearAllData = app.buttons["settings.clearAllData"]
        scrollUntilHittable(clearAllData, in: app, maxSwipes: 10)
        XCTAssertTrue(clearAllData.waitForExistence(timeout: 5), "设置应有清空所有数据入口")
        clearAllData.tap()
        XCTAssertTrue(app.alerts["确认清空所有数据？"].waitForExistence(timeout: 5), "清空所有数据应显示确认弹窗")
        addScreenshot(named: "ui-freeze-settings-controls-07-clear-all-alert")
        app.alerts["确认清空所有数据？"].buttons["取消"].tap()

        let feedback = app.buttons["settings.feedback"]
        scrollUntilHittable(feedback, in: app, maxSwipes: 4)
        XCTAssertTrue(feedback.waitForExistence(timeout: 5), "设置应有反馈入口")
        feedback.tap()
        XCTAssertTrue(app.alerts["意见反馈"].waitForExistence(timeout: 5), "意见反馈应显示联系弹窗")
        addScreenshot(named: "ui-freeze-settings-controls-08-feedback-alert")
        app.alerts["意见反馈"].buttons["以后再说"].tap()

        let licenses = app.buttons["settings.licenses"]
        scrollUntilHittable(licenses, in: app, maxSwipes: 4)
        XCTAssertTrue(licenses.waitForExistence(timeout: 5), "设置应有开源许可入口")
        licenses.tap()
        waitForAnyElement("settings.licenses.root", in: app)
        addScreenshot(named: "ui-freeze-settings-controls-09-licenses-root")
        app.buttons["settings.licenses.mantis"].tap()
        waitForAnyElement("settings.licenses.detail.Mantis", in: app)
        addScreenshot(named: "ui-freeze-settings-controls-10-license-detail")
    }

    /// UI-freeze evidence: capture deep Settings scroll zones and global clear-data confirmation.
    func testUIFreezeSettingsDeepScrollScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "主 tab bar 应出现")
        app.tabBars.buttons.element(boundBy: 4).tap()
        waitForAnyElement("settings.root", in: app)

        let clearAll = app.buttons["settings.clearAllData"]
        scrollUntilHittable(clearAll, in: app, maxSwipes: 10)
        XCTAssertTrue(clearAll.waitForExistence(timeout: 5), "设置深滚后应显示清空全部数据入口")
        addScreenshot(named: "ui-freeze-settings-deep-01-danger-zone")
        clearAll.tap()
        let clearAlert = app.alerts.firstMatch
        XCTAssertTrue(clearAlert.waitForExistence(timeout: 5), "清空全部数据应显示确认弹窗")
        addScreenshot(named: "ui-freeze-settings-deep-02-clear-all-alert")
        clearAlert.buttons["取消"].tap()

        let terms = app.buttons["settings.terms"]
        scrollUntilHittable(terms, in: app, maxSwipes: 8)
        XCTAssertTrue(terms.waitForExistence(timeout: 5), "设置底部应显示服务条款入口")
        addScreenshot(named: "ui-freeze-settings-deep-03-about-legal-bottom")

        let generateTestData = app.buttons["settings.generateTestData"]
        scrollUntilHittable(generateTestData, in: app, maxSwipes: 4)
        XCTAssertTrue(generateTestData.waitForExistence(timeout: 5), "DEBUG 设置末尾行应能完整滚出浮动 tab bar")
        addScreenshot(named: "ui-freeze-settings-deep-04-debug-bottom")
    }

    /// UI-freeze evidence: capture Library populated, filter, detail, edit, selection, and export surfaces.
    func testUIFreezeLibraryPopulatedSurfaceScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        createManualItem(content: "Library QA Alpha", subject: "数学", in: app)
        createManualItem(content: "Library QA Beta", subject: "语文", in: app)

        app.tabBars.buttons.element(boundBy: 1).tap()
        waitForAnyElement("library.root", in: app)
        XCTAssertTrue(app.staticTexts["Library QA Alpha"].waitForExistence(timeout: 10), "题库应显示第一条 QA 数据")
        XCTAssertTrue(app.staticTexts["Library QA Beta"].waitForExistence(timeout: 5), "题库应显示第二条 QA 数据")
        addScreenshot(named: "ui-freeze-library-01-populated-list")

        app.buttons["library.filterButton"].tap()
        waitForAnyElement("library.filter.root", in: app)
        addScreenshot(named: "ui-freeze-library-02-filter-sheet")

        let mathFilter = app.buttons["filter.value.数学"]
        XCTAssertTrue(mathFilter.waitForExistence(timeout: 5), "筛选页应显示数学值")
        mathFilter.tap()
        addScreenshot(named: "ui-freeze-library-03-filter-selected")
        app.buttons["完成"].tap()

        XCTAssertTrue(app.staticTexts["Library QA Alpha"].waitForExistence(timeout: 5), "筛选后数学条目应保留")
        XCTAssertTrue(app.staticTexts["Library QA Beta"].waitForNonExistence(timeout: 5), "筛选后语文条目应隐藏")
        addScreenshot(named: "ui-freeze-library-04-filtered-list")

        let alphaCell = app.cells.containing(.staticText, identifier: "Library QA Alpha").firstMatch
        XCTAssertTrue(alphaCell.waitForExistence(timeout: 5), "筛选列表应有可进入详情的 QA 条目")
        alphaCell.tap()
        waitForAnyElement("library.detail.root", in: app)
        addScreenshot(named: "ui-freeze-library-05-detail-text")

        app.buttons["library.detail.editButton"].tap()
        waitForAnyElement("library.edit.root", in: app)
        addScreenshot(named: "ui-freeze-library-06-edit-sheet")
        app.buttons["取消"].tap()
        waitForAnyElement("library.detail.root", in: app)

        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForAnyElement("library.root", in: app)

        let filteredAlphaCell = app.cells.containing(.staticText, identifier: "Library QA Alpha").firstMatch
        XCTAssertTrue(filteredAlphaCell.waitForExistence(timeout: 5), "返回列表后 QA 条目应仍可见")
        filteredAlphaCell.press(forDuration: 0.6)

        let exportButton = app.buttons["library.selection.export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5), "长按后应进入选择工具栏")
        if !exportButton.isEnabled {
            filteredAlphaCell.tap()
        }
        XCTAssertTrue(exportButton.isEnabled, "选择一条资料后导出按钮应可用")
        addScreenshot(named: "ui-freeze-library-07-selection-toolbar")

        app.buttons["library.selection.batchTag"].tap()
        waitForAnyElement("library.batchTag.root", in: app)
        addScreenshot(named: "ui-freeze-library-08-batch-tag-sheet")
        app.buttons["取消"].tap()
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5), "关闭批量标签后应回到选择工具栏")

        exportButton.tap()
        waitForAnyElement("library.export.root", in: app)
        addScreenshot(named: "ui-freeze-library-09-export-sheet")

        app.buttons["library.export.pdf"].tap()
        waitForAnyElement("library.exportPreview.root", in: app, timeout: 12)
        XCTAssertTrue(app.staticTexts["正在生成..."].waitForNonExistence(timeout: 12), "PDF 预览应完成生成态")
        addScreenshot(named: "ui-freeze-library-10-export-preview")
    }

    /// UI-freeze evidence: capture image-backed Library detail, answer, edit, export, and storage states.
    func testUIFreezeLibraryImageDataScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments() + ["--ui-test-seed-image-library"]
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "主 tab bar 应出现")
        app.tabBars.buttons.element(boundBy: 1).tap()
        waitForAnyElement("library.root", in: app)
        XCTAssertTrue(app.staticTexts["Library Image Fixture"].waitForExistence(timeout: 10), "题库应显示图片 fixture")
        addScreenshot(named: "ui-freeze-library-image-01-list")

        let imageCell = app.cells.containing(.staticText, identifier: "Library Image Fixture").firstMatch
        XCTAssertTrue(imageCell.waitForExistence(timeout: 5), "图片 fixture 应可进入详情")
        imageCell.tap()
        waitForAnyElement("library.detail.root", in: app)
        let questionImage = waitForAnyElement("library.detail.questionImage", in: app, timeout: 10)
        addScreenshot(named: "ui-freeze-library-image-02-detail-image")

        questionImage.tap()
        waitForAnyElement("library.fullScreenImage.close", in: app)
        addScreenshot(named: "ui-freeze-library-image-04-fullscreen-image")
        app.buttons["library.fullScreenImage.close"].tap()
        waitForAnyElement("library.detail.root", in: app)

        app.buttons["library.detail.answerToggle"].tap()
        waitForAnyElement("library.detail.answerContent", in: app)
        addScreenshot(named: "ui-freeze-library-image-03-answer-expanded")

        app.buttons["library.detail.editButton"].tap()
        waitForAnyElement("library.edit.root", in: app)
        addScreenshot(named: "ui-freeze-library-image-05-edit-image")
        app.buttons["取消"].tap()
        waitForAnyElement("library.detail.root", in: app)

        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForAnyElement("library.root", in: app)
        imageCell.press(forDuration: 0.6)
        let exportButton = app.buttons["library.selection.export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5), "图片 fixture 选择后应显示导出按钮")
        if !exportButton.isEnabled {
            imageCell.tap()
        }
        XCTAssertTrue(exportButton.isEnabled, "图片 fixture 被选择后导出按钮应可用")
        exportButton.tap()
        waitForAnyElement("library.export.root", in: app)
        XCTAssertTrue(app.buttons["library.export.zip"].isEnabled, "图片 fixture 应允许进入 ZIP 导出")
        addScreenshot(named: "ui-freeze-library-image-06-export-image-item")
        app.buttons["library.export.close"].tap()
        XCTAssertTrue(app.buttons["完成"].waitForExistence(timeout: 5), "关闭导出页后应回到选择工具栏")
        app.buttons["完成"].tap()

        app.tabBars.buttons.element(boundBy: 4).tap()
        waitForAnyElement("settings.root", in: app)
        let storage = app.buttons["settings.storage"]
        scrollUntilHittable(storage, in: app, maxSwipes: 8)
        XCTAssertTrue(storage.waitForExistence(timeout: 5), "设置应有存储入口")
        storage.tap()
        waitForAnyElement("settings.storage.root", in: app)
        let populatedSize = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'KB' OR label CONTAINS[c] 'MB'")
        ).firstMatch
        XCTAssertTrue(populatedSize.waitForExistence(timeout: 8), "存储页应显示非空图片缓存大小")
        addScreenshot(named: "ui-freeze-library-image-07-storage-populated")
    }

    /// UI-freeze evidence: capture Library filter reset, batch tag, export option, and search states.
    func testUIFreezeLibraryControlStateScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        createManualItem(content: "Library Control Alpha", subject: "数学", in: app)
        createManualItem(content: "Library Control Beta", subject: "语文", in: app)
        createTagValue("重点", in: app)

        app.tabBars.buttons.element(boundBy: 1).tap()
        waitForAnyElement("library.root", in: app)
        XCTAssertTrue(app.staticTexts["Library Control Alpha"].waitForExistence(timeout: 10), "题库应显示第一条 QA 数据")
        XCTAssertTrue(app.staticTexts["Library Control Beta"].waitForExistence(timeout: 5), "题库应显示第二条 QA 数据")

        app.buttons["library.filterButton"].tap()
        waitForAnyElement("library.filter.root", in: app)
        let mathFilter = app.buttons["filter.value.数学"]
        XCTAssertTrue(mathFilter.waitForExistence(timeout: 5), "筛选页应显示数学值")
        mathFilter.tap()
        addScreenshot(named: "ui-freeze-library-controls-01-filter-selected-before-reset")
        app.buttons["library.filter.reset"].tap()
        waitForAnyElement("library.root", in: app)
        XCTAssertTrue(app.staticTexts["Library Control Alpha"].waitForExistence(timeout: 5), "重置后数学条目应恢复")
        XCTAssertTrue(app.staticTexts["Library Control Beta"].waitForExistence(timeout: 5), "重置后语文条目应恢复")
        addScreenshot(named: "ui-freeze-library-controls-02-filter-reset-list")

        let alphaCell = app.cells.containing(.staticText, identifier: "Library Control Alpha").firstMatch
        XCTAssertTrue(alphaCell.waitForExistence(timeout: 5), "QA 条目应可选择")
        alphaCell.press(forDuration: 0.6)
        let batchTag = app.buttons["library.selection.batchTag"]
        XCTAssertTrue(batchTag.waitForExistence(timeout: 5), "长按后应显示批量标签按钮")
        if !batchTag.isEnabled {
            alphaCell.tap()
        }
        XCTAssertTrue(batchTag.isEnabled, "选择资料后批量标签按钮应可用")
        batchTag.tap()
        waitForAnyElement("library.batchTag.root", in: app)
        let tag = app.buttons["library.batchTag.value.重点"]
        XCTAssertTrue(tag.waitForExistence(timeout: 5), "批量标签页应显示预置标签")
        tag.tap()
        XCTAssertTrue(app.buttons["library.batchTag.done"].isEnabled, "选择标签后完成按钮应可用")
        addScreenshot(named: "ui-freeze-library-controls-03-batch-tag-selected")
        app.buttons["取消"].tap()

        let exportButton = app.buttons["library.selection.export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5), "关闭批量标签后应回到选择工具栏")
        exportButton.tap()
        waitForAnyElement("library.export.root", in: app)
        XCTAssertTrue(app.buttons["library.export.csv"].waitForExistence(timeout: 5), "导出页应显示 CSV 入口")
        XCTAssertTrue(app.buttons["library.export.zip"].waitForExistence(timeout: 5), "导出页应显示 ZIP 入口")
        XCTAssertTrue(app.switches["library.export.hideAnswers"].waitForExistence(timeout: 5), "导出页应显示隐藏答案开关")
        addScreenshot(named: "ui-freeze-library-controls-04-export-options")

        app.buttons["library.export.zip"].tap()
        XCTAssertTrue(app.alerts["选中的题目没有图片"].waitForExistence(timeout: 5), "纯文本资料 ZIP 导出应显示无图片提示")
        addScreenshot(named: "ui-freeze-library-controls-05-zip-no-images-alert")
        app.alerts["选中的题目没有图片"].buttons["关闭"].tap()
        app.buttons["library.export.close"].tap()

        let doneButton = app.buttons["完成"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "关闭导出页后应仍在选择模式")
        doneButton.tap()
        XCTAssertTrue(app.staticTexts["Library Control Alpha"].waitForExistence(timeout: 5), "退出选择模式后列表应仍可见")

        let searchField = app.searchFields.firstMatch
        if !searchField.exists {
            app.swipeDown()
        }
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "题库应提供搜索框")
        searchField.tap()
        searchField.typeText("Alpha")
        XCTAssertTrue(app.staticTexts["Library Control Alpha"].waitForExistence(timeout: 5), "搜索 Alpha 应保留匹配条目")
        XCTAssertTrue(app.staticTexts["Library Control Beta"].waitForNonExistence(timeout: 5), "搜索 Alpha 应隐藏不匹配条目")
        addScreenshot(named: "ui-freeze-library-controls-06-search-result")

        searchField.typeText(" zzz")
        XCTAssertTrue(app.staticTexts["无结果"].waitForExistence(timeout: 5), "无匹配搜索应显示无结果状态")
        addScreenshot(named: "ui-freeze-library-controls-07-search-no-results")
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

    /// Icon picker should expose general-audience, localized categories instead of school-only taxonomy.
    func testIconPickerUsesGeneralAudienceCategories() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        let settingsTab = app.tabBars.buttons.element(boundBy: 4)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "设置 Tab 应出现")
        settingsTab.tap()
        let manageRow = app.buttons["settings.manageCategories"]
        scrollUntilHittable(manageRow, in: app)
        XCTAssertTrue(manageRow.waitForExistence(timeout: 5), "应有‘管理分类维度’入口")
        manageRow.tap()

        let addDim = app.buttons["dim.add"]
        XCTAssertTrue(addDim.waitForExistence(timeout: 5), "应有新建维度按钮")
        addDim.tap()
        let iconPicker = app.buttons["dimEdit.iconPicker"]
        XCTAssertTrue(iconPicker.waitForExistence(timeout: 5), "新建维度应有图标选择入口")
        iconPicker.tap()

        XCTAssertTrue(app.staticTexts["symbolPicker.category.common"].waitForExistence(timeout: 5), "图标选择器应显示通用分类")
        XCTAssertTrue(app.staticTexts["symbolPicker.category.documents"].exists, "图标选择器应显示文档分类")
        XCTAssertTrue(app.staticTexts["symbolPicker.category.work"].exists, "图标选择器应显示工作分类")
        let pickerScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        pickerScreenshot.name = "icon-picker-general-audience-categories"
        pickerScreenshot.lifetime = .keepAlways
        add(pickerScreenshot)

        for oldCategory in ["学术", "数学/逻辑", "理化/实验", "体育/运动"] {
            XCTAssertFalse(app.staticTexts[oldCategory].exists, "图标选择器不应暴露旧教育分类：\(oldCategory)")
        }

        let documentIcon = app.buttons["symbolPicker.symbol.doc.text.fill"]
        XCTAssertTrue(documentIcon.waitForExistence(timeout: 5), "文档图标应在通用图标选择器中")
        documentIcon.tap()
        XCTAssertTrue(iconPicker.waitForExistence(timeout: 5), "选择图标后应回到维度编辑页")
        XCTAssertTrue(app.staticTexts["doc.text.fill"].waitForExistence(timeout: 3), "维度编辑页应回填已选图标名")
    }

    /// 步骤③：手动录入时选单值维度（学科=数学）+ 保存 + 题库显示徽标
    func testManualEntryWithDimensionSelection() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        createManualItem(content: "维度选择 E2E", subject: "数学", in: app)

        // 题库验证徽标
        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.staticTexts["维度选择 E2E"].waitForExistence(timeout: 10), "题目应出现在题库")
        XCTAssertTrue(app.staticTexts["数学"].waitForExistence(timeout: 5), "题库卡片应显示学科徽标‘数学’")
    }

    /// 步骤⑤：用户新建的自定义维度应即时出现在采集表单、可选值并保存（L3 端到端杀手锏）
    func testCustomDimensionAppearsInCaptureForm() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        // 设置 → 维度管理 → 新建单值维度「章节」+ 加值「第一章」
        let settingsTab = app.tabBars.buttons.element(boundBy: 4)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "设置 Tab 应出现")
        settingsTab.tap()
        let manageRow = app.buttons["settings.manageCategories"]
        scrollUntilHittable(manageRow, in: app)
        XCTAssertTrue(manageRow.waitForExistence(timeout: 5), "应有‘管理分类维度’入口")
        manageRow.tap()
        let addDim = app.buttons["dim.add"]
        XCTAssertTrue(addDim.waitForExistence(timeout: 5), "应有新建维度按钮")
        addDim.tap()
        let dimName = app.textFields["dimEdit.nameField"]
        XCTAssertTrue(dimName.waitForExistence(timeout: 5), "新建维度应有名称输入框")
        dimName.tap()
        dimName.typeText("章节")
        app.buttons["保存"].tap()
        let chapterRow = app.buttons["dim.row.章节"]
        XCTAssertTrue(chapterRow.waitForExistence(timeout: 5), "‘章节’应出现在维度列表")
        chapterRow.tap()
        let addValue = app.buttons["dimValue.add"]
        XCTAssertTrue(addValue.waitForExistence(timeout: 5), "应有添加值按钮")
        addValue.tap()
        let valField = app.textFields["dimValueEdit.nameField"]
        XCTAssertTrue(valField.waitForExistence(timeout: 5), "添加值应有名称输入框")
        valField.tap()
        valField.typeText("第一章")
        app.buttons["保存"].tap()
        XCTAssertTrue(app.buttons["dimValue.第一章"].waitForExistence(timeout: 5), "值‘第一章’应加入列表")

        // 采集 → 手动录入：自定义维度「章节」应即时出现在表单
        let captureTab = app.tabBars.buttons.element(boundBy: 2)
        captureTab.tap()
        let manual = app.buttons["capture.manual"]
        XCTAssertTrue(manual.waitForExistence(timeout: 5), "手动录入按钮应出现")
        manual.tap()
        let editor = app.textViews["capture.contentEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5), "内容编辑器应出现")
        editor.tap()
        editor.typeText("自定义维度 E2E")
        dismissKeyboardIfPresent(in: app)

        // 关键断言：自定义维度「章节」即时出现在采集表单
        let chapterMenu = app.buttons["capture.dimRow.章节"]
        scrollUntilHittable(chapterMenu, in: app)
        XCTAssertTrue(chapterMenu.waitForExistence(timeout: 5), "自定义维度‘章节’应即时出现在采集表单")
        chapterMenu.tap()
        let firstChapterOpt = app.buttons["capture.opt.第一章"]
        XCTAssertTrue(firstChapterOpt.waitForExistence(timeout: 5), "章节菜单应有‘第一章’")
        firstChapterOpt.tap()

        // 保存 + 题库验证
        let save = app.buttons["capture.saveButton"]
        scrollUntilHittable(save, in: app)
        XCTAssertTrue(save.waitForExistence(timeout: 5), "保存按钮应出现")
        save.tap()
        XCTAssertTrue(manual.waitForExistence(timeout: 10), "保存后应返回采集首页")
        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.staticTexts["自定义维度 E2E"].waitForExistence(timeout: 10), "题目应出现在题库")
    }

    /// 步骤⑥：题库按动态维度筛选——选「学科=数学」只剩数学题、语文题隐藏；重置后恢复
    func testLibraryFilterByDimension() {
        let app = XCUIApplication()
        app.launchArguments = l3LaunchArguments()
        app.launch()

        // 造两题：甲=数学、乙=语文（--uitesting 起始空库，无噪音）
        createManualItem(content: "筛选甲数学", subject: "数学", in: app)
        createManualItem(content: "筛选乙语文", subject: "语文", in: app)

        // 进题库，确认两题都在
        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.staticTexts["筛选甲数学"].waitForExistence(timeout: 10), "数学题应在题库")
        XCTAssertTrue(app.staticTexts["筛选乙语文"].waitForExistence(timeout: 5), "语文题应在题库")

        // 打开筛选 → 选 学科=数学 → 完成
        let filterBtn = app.buttons["library.filterButton"]
        XCTAssertTrue(filterBtn.waitForExistence(timeout: 5), "题库应有筛选入口")
        filterBtn.tap()
        let mathFilter = app.buttons["filter.value.数学"]
        XCTAssertTrue(mathFilter.waitForExistence(timeout: 5), "筛选面板应有‘数学’值")
        mathFilter.tap()
        app.buttons["完成"].tap()

        // 数学题留、语文题隐藏
        XCTAssertTrue(app.staticTexts["筛选甲数学"].waitForExistence(timeout: 5), "筛选后数学题应仍在")
        XCTAssertTrue(app.staticTexts["筛选乙语文"].waitForNonExistence(timeout: 5), "筛选数学后语文题应被隐藏")

        // 重置筛选 → 两题恢复
        filterBtn.tap()
        let resetBtn = app.buttons["重置"]
        XCTAssertTrue(resetBtn.waitForExistence(timeout: 3), "筛选面板应有重置按钮")
        resetBtn.tap()
        XCTAssertTrue(app.staticTexts["筛选乙语文"].waitForExistence(timeout: 5), "重置后语文题应恢复")
    }

    /// 手动录入一题（可选指定单值学科），保存后停在采集首页。复用于 ③⑥ 造数据。
    private func createManualItem(content: String, subject: String?, answer: String? = nil, in app: XCUIApplication) {
        let captureTab = app.tabBars.buttons.element(boundBy: 2)
        XCTAssertTrue(captureTab.waitForExistence(timeout: 5), "采集 Tab 应出现")
        captureTab.tap()
        let manual = app.buttons["capture.manual"]
        XCTAssertTrue(manual.waitForExistence(timeout: 5), "手动录入按钮应出现")
        manual.tap()
        let editor = app.textViews["capture.contentEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5), "内容编辑器应出现")
        editor.tap()
        editor.typeText(content)
        dismissKeyboardIfPresent(in: app)
        if let subject {
            // 单值维度暴露为 capture.dimRow.<title>（内层 Menu id 被外层 HStack 吞）
            let menu = app.buttons["capture.dimRow.学科"]
            scrollUntilHittable(menu, in: app)
            XCTAssertTrue(menu.waitForExistence(timeout: 5), "应有学科单值菜单")
            menu.tap()
            let option = app.buttons["capture.opt.\(subject)"]
            XCTAssertTrue(option.waitForExistence(timeout: 5), "学科菜单应有‘\(subject)’选项")
            option.tap()
        }
        if let answer {
            let answerEditor = app.textViews["capture.answerEditor"]
            scrollUntilHittable(answerEditor, in: app)
            XCTAssertTrue(answerEditor.waitForExistence(timeout: 5), "答案编辑器应出现")
            answerEditor.tap()
            answerEditor.typeText(answer)
            dismissKeyboardIfPresent(in: app)
        }
        let save = app.buttons["capture.saveButton"]
        scrollUntilHittable(save, in: app)
        XCTAssertTrue(save.waitForExistence(timeout: 5), "保存按钮应出现")
        save.tap()
        XCTAssertTrue(manual.waitForExistence(timeout: 10), "保存后应返回采集首页")
    }

    private enum HorizontalDragDirection {
        case left
        case right
    }

    /// Drag across the visible Review card without adding broad accessibility IDs to the card container.
    private func dragReviewCard(in app: XCUIApplication, direction: HorizontalDragDirection) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.48))
        let endX = direction == .left ? 0.14 : 0.86
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: endX, dy: 0.48))
        start.press(forDuration: 0.15, thenDragTo: end)
        waitForUIAnimation(seconds: 1.0)
    }

    /// 新建一个标签值，供批量标签 UI 状态使用。
    private func createTagValue(_ name: String, in app: XCUIApplication) {
        let settingsTab = app.tabBars.buttons.element(boundBy: 4)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "设置 Tab 应出现")
        settingsTab.tap()

        let manageRow = app.buttons["settings.manageCategories"]
        scrollUntilHittable(manageRow, in: app, maxSwipes: 10)
        XCTAssertTrue(manageRow.waitForExistence(timeout: 5), "设置应有分类管理入口")
        manageRow.tap()
        waitForAnyElement("settings.categoryManager.root", in: app)

        let tagRow = app.buttons["dim.row.tag"]
        scrollUntilHittable(tagRow, in: app, maxSwipes: 6)
        XCTAssertTrue(tagRow.waitForExistence(timeout: 5), "分类管理应有标签维度")
        tagRow.tap()
        waitForAnyElement("dimValueList.root.tag", in: app)

        let addValue = app.buttons["dimValue.add"]
        XCTAssertTrue(addValue.waitForExistence(timeout: 5), "标签值列表应有添加按钮")
        addValue.tap()
        let nameField = app.textFields["dimValueEdit.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "添加标签值应有名称输入框")
        nameField.tap()
        nameField.typeText(name)
        app.buttons["保存"].tap()
        XCTAssertTrue(app.buttons["dimValue.\(name)"].waitForExistence(timeout: 5), "新标签值应出现在列表")
    }

    /// 收起软键盘（防表单下方控件被键盘遮挡）——点导航栏中性区域 resign first responder
    private func dismissKeyboardIfPresent(in app: XCUIApplication) {
        guard app.keyboards.element.exists else { return }
        app.navigationBars.firstMatch.tap()
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
