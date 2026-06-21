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
    private func createManualItem(content: String, subject: String?, in app: XCUIApplication) {
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
        let save = app.buttons["capture.saveButton"]
        scrollUntilHittable(save, in: app)
        XCTAssertTrue(save.waitForExistence(timeout: 5), "保存按钮应出现")
        save.tap()
        XCTAssertTrue(manual.waitForExistence(timeout: 10), "保存后应返回采集首页")
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
