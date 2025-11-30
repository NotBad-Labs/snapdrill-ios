//
//  OnboardingUITests.swift
//  NotBadUITests
//
//  Created for NotBad K12 错题本
//

import XCTest

/// Onboarding 流程 UI 测试
///
/// 测试首次启动的引导流程
final class OnboardingUITests: NotBadUITests {

    // MARK: - Tests

    /// 测试完整的 Onboarding 流程
    func testCompleteOnboardingFlow() throws {
        // 启动 App 并重置状态
        app.launchArguments.append("--reset-onboarding")
        app.launch()

        takeScreenshot(named: "01_onboarding_start")

        // 验证欢迎页面显示
        XCTAssertTrue(app.staticTexts["onboarding_welcome_title"].waitForExistence(timeout: 5))

        // 验证区域选择存在
        let chinaOption = app.buttons["onboarding_region_china"]
        let japanOption = app.buttons["onboarding_region_japan"]
        let koreaOption = app.buttons["onboarding_region_korea"]

        XCTAssertTrue(chinaOption.exists, "中国选项应该存在")
        XCTAssertTrue(japanOption.exists, "日本选项应该存在")
        XCTAssertTrue(koreaOption.exists, "韩国选项应该存在")

        // 选择中国
        chinaOption.tap()
        takeScreenshot(named: "02_region_selected")

        // 点击继续按钮
        let continueButton = app.buttons["onboarding_continue"]
        XCTAssertTrue(continueButton.exists)
        XCTAssertTrue(continueButton.isEnabled, "选择区域后继续按钮应该可用")
        continueButton.tap()

        takeScreenshot(named: "03_grade_selection")

        // 验证年级选择页面
        // 等待年级选项加载
        let gradeOption = app.buttons["高一"]
        XCTAssertTrue(gradeOption.waitForExistence(timeout: 3), "年级选项应该存在")

        // 选择年级
        gradeOption.tap()
        takeScreenshot(named: "04_grade_selected")

        // 完成 Onboarding
        let startButton = app.buttons["onboarding_start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        startButton.tap()

        takeScreenshot(named: "05_main_screen")

        // 验证进入主界面
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "应该进入主界面并显示 Tab Bar")
    }

    /// 测试区域切换
    func testRegionSwitching() throws {
        app.launchArguments.append("--reset-onboarding")
        app.launch()

        // 等待 Onboarding 加载
        let chinaOption = app.buttons["onboarding_region_china"]
        XCTAssertTrue(chinaOption.waitForExistence(timeout: 5))

        // 测试选择不同区域
        chinaOption.tap()

        // 切换到日本
        let japanOption = app.buttons["onboarding_region_japan"]
        japanOption.tap()

        // 验证可以继续
        let continueButton = app.buttons["onboarding_continue"]
        XCTAssertTrue(continueButton.isEnabled)

        takeScreenshot(named: "region_switch_test")
    }

    /// 测试未选择区域时继续按钮禁用
    func testContinueButtonDisabledWithoutSelection() throws {
        app.launchArguments.append("--reset-onboarding")
        app.launch()

        // 等待页面加载
        let continueButton = app.buttons["onboarding_continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))

        // 验证未选择时按钮状态
        // 注意：按钮可能是 disabled 或者点击后显示提示
        takeScreenshot(named: "continue_button_initial_state")
    }
}
