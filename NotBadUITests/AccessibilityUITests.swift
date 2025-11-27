//
//  AccessibilityUITests.swift
//  NotBadUITests
//
//  Created for NotBad K12 错题本
//

import XCTest

/// 可访问性 UI 测试
///
/// 验证应用符合可访问性标准
final class AccessibilityUITests: NotBadUITests {
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launch()
        completeOnboardingIfNeeded()
    }
    
    // MARK: - Tests
    
    /// 测试 Tab Bar 可访问性
    func testTabBarAccessibility() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 3))
        
        // 验证每个 Tab 都有可访问性标签
        for button in tabBar.buttons.allElementsBoundByIndex {
            XCTAssertFalse(button.label.isEmpty, "Tab 按钮应该有可访问性标签")
        }
        
        takeScreenshot(named: "accessibility_tabbar")
    }
    
    /// 测试按钮可访问性
    func testButtonAccessibility() throws {
        // 检查首页按钮
        let buttons = app.buttons.allElementsBoundByIndex
        
        var buttonsWithoutLabels: [String] = []
        for button in buttons.prefix(10) { // 检查前10个按钮
            if button.label.isEmpty && button.identifier.isEmpty {
                buttonsWithoutLabels.append("Button at \(button.frame)")
            }
        }
        
        if !buttonsWithoutLabels.isEmpty {
            XCTFail("以下按钮缺少可访问性标签: \(buttonsWithoutLabels)")
        }
        
        takeScreenshot(named: "accessibility_buttons")
    }
    
    /// 测试图片可访问性
    func testImageAccessibility() throws {
        navigateToTab("录入")
        
        // 检查图片是否有可访问性描述
        let images = app.images.allElementsBoundByIndex
        
        for image in images.prefix(5) {
            // 图片应该有 accessibilityLabel 或者被标记为 accessibilityHidden
            // 这里只是记录，不做强制要求
            print("Image label: \(image.label), identifier: \(image.identifier)")
        }
        
        takeScreenshot(named: "accessibility_images")
    }
    
    /// 测试文本字段可访问性
    func testTextFieldAccessibility() throws {
        navigateToTab("录入")
        
        let textFields = app.textFields.allElementsBoundByIndex
        
        for textField in textFields {
            // 文本字段应该有 placeholder 或 label
            let hasLabel = !textField.label.isEmpty || !textField.placeholderValue!.isEmpty
            XCTAssertTrue(hasLabel, "文本字段应该有可访问性标签或占位符")
        }
        
        takeScreenshot(named: "accessibility_textfields")
    }
    
    /// 测试 VoiceOver 标签
    func testVoiceOverLabels() throws {
        // 测试关键元素是否有 VoiceOver 标签
        
        // 录入页面
        navigateToTab("录入")
        
        let saveButton = app.buttons["capture_save_to_library"]
        if saveButton.exists {
            XCTAssertFalse(saveButton.label.isEmpty, "保存按钮应该有 VoiceOver 标签")
        }
        
        takeScreenshot(named: "accessibility_voiceover")
    }
    
    /// 测试动态字体支持
    func testDynamicTypeSupport() throws {
        // 注意：动态字体测试需要在实际设备上进行
        // 这里只验证基本布局
        
        takeScreenshot(named: "accessibility_dynamic_type")
        
        // 验证文本元素存在
        let staticTexts = app.staticTexts.allElementsBoundByIndex
        XCTAssertGreaterThan(staticTexts.count, 0, "应该有文本元素")
    }
    
    /// 测试颜色对比度（视觉验证）
    func testColorContrast() throws {
        // 截取各个页面的截图供人工验证颜色对比度
        
        // 首页
        takeScreenshot(named: "contrast_dashboard")
        
        // 复习
        navigateToTab("复习")
        takeScreenshot(named: "contrast_review")
        
        // 录入
        navigateToTab("录入")
        takeScreenshot(named: "contrast_capture")
        
        // 题库
        navigateToTab("题库")
        takeScreenshot(named: "contrast_library")
        
        // 个人中心
        navigateToTab("我的")
        takeScreenshot(named: "contrast_profile")
    }
    
    /// 测试触摸目标大小
    func testTouchTargetSize() throws {
        // Apple HIG 建议最小触摸目标为 44x44 点
        let minSize: CGFloat = 44
        
        navigateToTab("录入")
        
        let buttons = app.buttons.allElementsBoundByIndex
        
        var smallButtons: [String] = []
        for button in buttons.prefix(10) {
            let frame = button.frame
            if frame.width < minSize || frame.height < minSize {
                smallButtons.append("\(button.label): \(frame.size)")
            }
        }
        
        // 记录可能过小的按钮（不强制失败）
        if !smallButtons.isEmpty {
            print("以下按钮可能触摸目标过小: \(smallButtons)")
        }
        
        takeScreenshot(named: "accessibility_touch_targets")
    }
}
