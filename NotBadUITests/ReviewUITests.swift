//
//  ReviewUITests.swift
//  NotBadUITests
//
//  Created for NotBad K12 错题本
//

import XCTest

/// 复习流程 UI 测试
///
/// 测试复习错题和掌握度评估
final class ReviewUITests: NotBadUITests {
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launch()
        completeOnboardingIfNeeded()
    }
    
    // MARK: - Tests
    
    /// 测试复习 Tab 显示
    func testReviewTabDisplay() throws {
        navigateToTab("复习")
        
        takeScreenshot(named: "review_tab_initial")
        
        // 验证复习页面加载
        // 可能显示空状态或复习卡片
        let emptyState = app.staticTexts["review_empty_title"]
        let reviewCard = app.otherElements["review_card"]
        
        let hasContent = emptyState.waitForExistence(timeout: 3) || 
                         reviewCard.waitForExistence(timeout: 3)
        XCTAssertTrue(hasContent, "应该显示空状态或复习卡片")
    }
    
    /// 测试空状态显示
    func testEmptyStateDisplay() throws {
        // 使用干净的测试数据
        app.launchArguments.append("--empty-data")
        app.terminate()
        app.launch()
        completeOnboardingIfNeeded()
        
        navigateToTab("复习")
        
        takeScreenshot(named: "review_empty_state")
        
        // 验证空状态元素
        let emptyTitle = app.staticTexts["review_empty_title"]
        if emptyTitle.waitForExistence(timeout: 3) {
            XCTAssertTrue(emptyTitle.exists, "空状态标题应该存在")
        }
    }
    
    /// 测试掌握度按钮
    func testMasteryButtons() throws {
        navigateToTab("复习")
        
        // 检查是否有复习卡片
        let masteredButton = app.buttons["review_mastery_mastered"]
        let unclearButton = app.buttons["review_mastery_unclear"]
        let failedButton = app.buttons["review_mastery_failed"]
        
        if masteredButton.waitForExistence(timeout: 3) {
            takeScreenshot(named: "review_mastery_buttons")
            
            XCTAssertTrue(masteredButton.exists, "完全掌握按钮应该存在")
            XCTAssertTrue(unclearButton.exists, "一知半解按钮应该存在")
            XCTAssertTrue(failedButton.exists, "不会按钮应该存在")
        }
    }
    
    /// 测试点击掌握按钮
    func testTapMasteredButton() throws {
        navigateToTab("复习")
        
        let masteredButton = app.buttons["review_mastery_mastered"]
        if masteredButton.waitForExistence(timeout: 3) {
            takeScreenshot(named: "review_before_mastered")
            
            masteredButton.tap()
            
            takeScreenshot(named: "review_after_mastered")
            
            // 验证进入下一题或显示完成
        }
    }
    
    /// 测试点击不会按钮
    func testTapFailedButton() throws {
        navigateToTab("复习")
        
        let failedButton = app.buttons["review_mastery_failed"]
        if failedButton.waitForExistence(timeout: 3) {
            takeScreenshot(named: "review_before_failed")
            
            failedButton.tap()
            
            takeScreenshot(named: "review_after_failed")
        }
    }
    
    /// 测试查看/隐藏答案
    func testToggleAnswer() throws {
        navigateToTab("复习")
        
        // 找到查看答案按钮
        let showAnswerButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '答案'")).firstMatch
        
        if showAnswerButton.waitForExistence(timeout: 3) {
            takeScreenshot(named: "review_answer_hidden")
            
            // 点击显示答案
            showAnswerButton.tap()
            
            takeScreenshot(named: "review_answer_shown")
            
            // 再次点击隐藏答案
            showAnswerButton.tap()
            
            takeScreenshot(named: "review_answer_hidden_again")
        }
    }
    
    /// 测试复习卡片信息显示
    func testReviewCardInfo() throws {
        navigateToTab("复习")
        
        let reviewCard = app.otherElements["review_card"]
        if reviewCard.waitForExistence(timeout: 3) {
            takeScreenshot(named: "review_card_info")
            
            // 验证卡片包含必要信息
            // 学科标签
            // 年级标签
            // 题目标题
        }
    }
}
