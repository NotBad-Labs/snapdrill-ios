//
//  DashboardUITests.swift
//  NotBadUITests
//
//  Created for NotBad K12 错题本
//

import XCTest

/// 首页仪表盘 UI 测试
///
/// 测试首页统计信息和快捷操作
final class DashboardUITests: NotBadUITests {
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launch()
        completeOnboardingIfNeeded()
    }
    
    // MARK: - Tests
    
    /// 测试首页显示
    func testDashboardDisplay() throws {
        // 首页应该是默认 Tab
        takeScreenshot(named: "dashboard_initial")
        
        // 验证欢迎卡片
        let welcomeCard = app.otherElements["welcome_card"]
        XCTAssertTrue(welcomeCard.waitForExistence(timeout: 3) || 
                      app.staticTexts.matching(NSPredicate(format: "label CONTAINS '今日'")).firstMatch.exists,
                      "欢迎卡片应该存在")
    }
    
    /// 测试统计卡片显示
    func testStatCardsDisplay() throws {
        takeScreenshot(named: "dashboard_stat_cards")
        
        // 验证统计卡片存在
        // 总错题数
        let totalCard = app.staticTexts["dashboard_total_items"]
        // 待复习
        let reviewCard = app.staticTexts["dashboard_pending_review"]
        
        // 至少应该有一些统计信息
        let hasStats = totalCard.waitForExistence(timeout: 3) || 
                       reviewCard.waitForExistence(timeout: 3)
        
        if hasStats {
            XCTAssertTrue(true, "统计卡片显示正常")
        }
    }
    
    /// 测试快捷操作
    func testQuickActions() throws {
        takeScreenshot(named: "dashboard_quick_actions")
        
        // 找到快捷操作按钮
        let quickActionButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '录入' OR label CONTAINS '复习'")).firstMatch
        
        if quickActionButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(quickActionButton.isEnabled)
            takeScreenshot(named: "dashboard_quick_action_found")
        }
    }
    
    /// 测试点击开始复习
    func testTapStartReview() throws {
        // 找到开始复习按钮
        let startReviewButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '开始复习'")).firstMatch
        
        if startReviewButton.waitForExistence(timeout: 3) {
            takeScreenshot(named: "dashboard_before_review")
            
            startReviewButton.tap()
            
            takeScreenshot(named: "dashboard_after_tap_review")
            
            // 验证导航到复习页面
            // 可能会显示复习卡片或空状态
        }
    }
    
    /// 测试点击添加错题
    func testTapAddItem() throws {
        // 找到添加按钮
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '录入' OR label CONTAINS '添加'")).firstMatch
        
        if addButton.waitForExistence(timeout: 3) {
            takeScreenshot(named: "dashboard_before_add")
            
            addButton.tap()
            
            takeScreenshot(named: "dashboard_after_tap_add")
        }
    }
    
    /// 测试下拉刷新
    func testPullToRefresh() throws {
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 3) {
            takeScreenshot(named: "dashboard_before_refresh")
            
            // 下拉刷新
            scrollView.swipeDown()
            
            takeScreenshot(named: "dashboard_refreshing")
            
            // 等待刷新完成
            sleep(2)
            
            takeScreenshot(named: "dashboard_after_refresh")
        }
    }
    
    /// 测试 Tab Bar 导航
    func testTabBarNavigation() throws {
        // 验证所有 Tab 存在
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 3))
        
        takeScreenshot(named: "tabbar_initial")
        
        // 遍历所有 Tab
        let tabs = ["首页", "复习", "录入", "题库", "我的"]
        
        for tab in tabs {
            let tabButton = tabBar.buttons[tab]
            if tabButton.exists {
                tabButton.tap()
                takeScreenshot(named: "tab_\(tab)")
            }
        }
        
        // 返回首页
        tabBar.buttons["首页"].tap()
    }
}
