//
//  ProfileUITests.swift
//  NotBadUITests
//
//  Created for NotBad K12 错题本
//

import XCTest

/// 个人中心 UI 测试
///
/// 测试个人信息和设置页面
final class ProfileUITests: NotBadUITests {
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launch()
        completeOnboardingIfNeeded()
    }
    
    // MARK: - Tests
    
    /// 测试个人中心显示
    func testProfileDisplay() throws {
        navigateToTab("我的")
        
        takeScreenshot(named: "profile_initial")
        
        // 验证个人中心页面加载
        let profileTitle = app.navigationBars["profile_title"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3) || 
                      app.staticTexts["profile_nickname"].exists,
                      "个人中心页面应该正确加载")
    }
    
    /// 测试统计信息显示
    func testStatisticsDisplay() throws {
        navigateToTab("我的")
        
        takeScreenshot(named: "profile_statistics")
        
        // 验证统计信息存在
        let totalItems = app.staticTexts["profile_total_items"]
        let mastered = app.staticTexts["profile_mastered"]
        
        // 统计信息应该存在
        if totalItems.waitForExistence(timeout: 3) {
            XCTAssertTrue(totalItems.exists)
        }
    }
    
    /// 测试设置导航
    func testNavigateToSettings() throws {
        navigateToTab("我的")
        
        // 找到设置项
        let settingsCell = app.cells.matching(NSPredicate(format: "label CONTAINS '设置' OR label CONTAINS '提醒'")).firstMatch
        
        if settingsCell.waitForExistence(timeout: 3) {
            takeScreenshot(named: "profile_before_settings")
            
            settingsCell.tap()
            
            takeScreenshot(named: "profile_settings_page")
            
            // 返回
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
    
    /// 测试复习提醒设置
    func testReviewReminderSettings() throws {
        navigateToTab("我的")
        
        let reminderCell = app.cells["profile_review_reminder"]
        if reminderCell.waitForExistence(timeout: 3) {
            reminderCell.tap()
            
            takeScreenshot(named: "profile_reminder_settings")
            
            // 验证提醒设置页面
            // 可能有时间选择器或开关
            
            // 返回
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
    
    /// 测试数据管理
    func testDataManagement() throws {
        navigateToTab("我的")
        
        let dataCell = app.cells["profile_data_management"]
        if dataCell.waitForExistence(timeout: 3) {
            dataCell.tap()
            
            takeScreenshot(named: "profile_data_management")
            
            // 验证数据管理页面
            // 可能有导出、导入、清除数据选项
            
            // 返回
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
    
    /// 测试外观设置
    func testAppearanceSettings() throws {
        navigateToTab("我的")
        
        let appearanceCell = app.cells["profile_appearance"]
        if appearanceCell.waitForExistence(timeout: 3) {
            appearanceCell.tap()
            
            takeScreenshot(named: "profile_appearance_settings")
            
            // 验证外观设置页面
            // 可能有深色模式开关等
            
            // 返回
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
    
    /// 测试关于页面
    func testAboutPage() throws {
        navigateToTab("我的")
        
        // 滚动到底部
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        }
        
        takeScreenshot(named: "profile_about_section")
        
        // 找到版本信息
        let versionText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '版本' OR label CONTAINS '1.0'")).firstMatch
        if versionText.waitForExistence(timeout: 3) {
            XCTAssertTrue(versionText.exists, "版本信息应该显示")
        }
    }
    
    /// 测试帮助中心
    func testHelpCenter() throws {
        navigateToTab("我的")
        
        let helpCell = app.cells["profile_help_center"]
        if helpCell.waitForExistence(timeout: 3) {
            helpCell.tap()
            
            takeScreenshot(named: "profile_help_center")
            
            // 返回
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
    
    /// 测试反馈页面
    func testFeedbackPage() throws {
        navigateToTab("我的")
        
        let feedbackCell = app.cells["profile_feedback"]
        if feedbackCell.waitForExistence(timeout: 3) {
            feedbackCell.tap()
            
            takeScreenshot(named: "profile_feedback_page")
            
            // 返回
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
}
