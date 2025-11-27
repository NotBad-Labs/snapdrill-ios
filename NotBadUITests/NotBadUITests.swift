//
//  NotBadUITests.swift
//  NotBadUITests
//
//  Created for NotBad K12 错题本
//

import XCTest

/// UI 测试基类
///
/// 提供通用的测试辅助方法和配置
class NotBadUITests: XCTestCase {
    
    // MARK: - Properties
    
    var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // 重置 UserDefaults 以确保干净的测试状态
        app.launchArguments = ["--uitesting", "--reset-state"]
        
        // 设置测试语言为中文
        app.launchArguments.append(contentsOf: ["-AppleLanguages", "(zh-Hans)"])
        app.launchArguments.append(contentsOf: ["-AppleLocale", "zh_CN"])
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Helper Methods
    
    /// 等待元素出现
    /// - Parameters:
    ///   - element: 要等待的元素
    ///   - timeout: 超时时间（默认5秒）
    /// - Returns: 元素是否出现
    @discardableResult
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    /// 等待元素消失
    /// - Parameters:
    ///   - element: 要等待消失的元素
    ///   - timeout: 超时时间
    /// - Returns: 元素是否消失
    @discardableResult
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /// 截图并附加到测试报告
    /// - Parameter name: 截图名称
    func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// 滑动到元素可见
    /// - Parameters:
    ///   - element: 目标元素
    ///   - scrollView: 滚动视图
    ///   - maxSwipes: 最大滑动次数
    func scrollToElement(_ element: XCUIElement, in scrollView: XCUIElement, maxSwipes: Int = 10) {
        var swipeCount = 0
        while !element.isHittable && swipeCount < maxSwipes {
            scrollView.swipeUp()
            swipeCount += 1
        }
    }
    
    /// 完成 Onboarding 流程（如果显示）
    func completeOnboardingIfNeeded() {
        // 检查是否在 Onboarding 页面
        let continueButton = app.buttons["onboarding_continue"]
        if continueButton.waitForExistence(timeout: 2) {
            // 选择中国
            let chinaOption = app.buttons["onboarding_region_china"]
            if chinaOption.exists {
                chinaOption.tap()
            }
            
            // 点击继续
            continueButton.tap()
            
            // 选择年级（选择高一）
            let gradeOption = app.buttons["高一"]
            if gradeOption.waitForExistence(timeout: 2) {
                gradeOption.tap()
            }
            
            // 完成 Onboarding
            let startButton = app.buttons["onboarding_start"]
            if startButton.waitForExistence(timeout: 2) {
                startButton.tap()
            }
        }
    }
    
    /// 导航到指定的 Tab
    /// - Parameter tabName: Tab 名称
    func navigateToTab(_ tabName: String) {
        let tabButton = app.tabBars.buttons[tabName]
        if tabButton.exists {
            tabButton.tap()
        }
    }
}
