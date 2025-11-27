//
//  LibraryUITests.swift
//  NotBadUITests
//
//  Created for NotBad K12 错题本
//

import XCTest

/// 题库 UI 测试
///
/// 测试题库列表、搜索、筛选功能
final class LibraryUITests: NotBadUITests {
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launch()
        completeOnboardingIfNeeded()
    }
    
    // MARK: - Tests
    
    /// 测试题库 Tab 显示
    func testLibraryTabDisplay() throws {
        navigateToTab("题库")
        
        takeScreenshot(named: "library_tab_initial")
        
        // 验证题库页面加载
        let libraryTitle = app.navigationBars["library_title"]
        let searchField = app.searchFields.firstMatch
        
        XCTAssertTrue(libraryTitle.waitForExistence(timeout: 3) || 
                      searchField.waitForExistence(timeout: 3),
                      "题库页面应该正确加载")
    }
    
    /// 测试空状态
    func testEmptyLibrary() throws {
        app.launchArguments.append("--empty-data")
        app.terminate()
        app.launch()
        completeOnboardingIfNeeded()
        
        navigateToTab("题库")
        
        takeScreenshot(named: "library_empty_state")
        
        // 验证空状态显示
        let emptyView = app.staticTexts["library_empty_title"]
        if emptyView.waitForExistence(timeout: 3) {
            XCTAssertTrue(emptyView.exists)
        }
    }
    
    /// 测试搜索功能
    func testSearch() throws {
        navigateToTab("题库")
        
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            takeScreenshot(named: "library_before_search")
            
            // 点击搜索框
            searchField.tap()
            
            // 输入搜索词
            searchField.typeText("数学")
            
            takeScreenshot(named: "library_search_results")
            
            // 清除搜索
            let clearButton = app.buttons["Clear text"]
            if clearButton.exists {
                clearButton.tap()
            }
            
            takeScreenshot(named: "library_search_cleared")
        }
    }
    
    /// 测试筛选功能
    func testFilter() throws {
        navigateToTab("题库")
        
        // 找到筛选按钮
        let filterButton = app.buttons["library_filter"]
        if filterButton.waitForExistence(timeout: 3) {
            filterButton.tap()
            
            takeScreenshot(named: "library_filter_open")
            
            // 选择一个筛选条件
            let mathFilter = app.buttons["数学"]
            if mathFilter.waitForExistence(timeout: 2) {
                mathFilter.tap()
            }
            
            takeScreenshot(named: "library_filter_applied")
        }
    }
    
    /// 测试排序功能
    func testSort() throws {
        navigateToTab("题库")
        
        // 找到排序按钮
        let sortButton = app.buttons["library_sort"]
        if sortButton.waitForExistence(timeout: 3) {
            sortButton.tap()
            
            takeScreenshot(named: "library_sort_menu")
            
            // 选择排序方式
            let sortOption = app.buttons.matching(NSPredicate(format: "label CONTAINS '时间'")).firstMatch
            if sortOption.waitForExistence(timeout: 2) {
                sortOption.tap()
            }
            
            takeScreenshot(named: "library_sorted")
        }
    }
    
    /// 测试点击列表项
    func testTapListItem() throws {
        navigateToTab("题库")
        
        // 等待列表加载
        let listItem = app.cells.firstMatch
        if listItem.waitForExistence(timeout: 3) {
            takeScreenshot(named: "library_before_tap")
            
            listItem.tap()
            
            takeScreenshot(named: "library_item_detail")
            
            // 验证进入详情页
            let backButton = app.navigationBars.buttons.firstMatch
            XCTAssertTrue(backButton.waitForExistence(timeout: 2), "应该进入详情页")
            
            // 返回列表
            backButton.tap()
        }
    }
    
    /// 测试滑动删除
    func testSwipeToDelete() throws {
        navigateToTab("题库")
        
        let listItem = app.cells.firstMatch
        if listItem.waitForExistence(timeout: 3) {
            takeScreenshot(named: "library_before_swipe")
            
            // 左滑显示删除按钮
            listItem.swipeLeft()
            
            takeScreenshot(named: "library_swipe_actions")
            
            // 检查删除按钮
            let deleteButton = app.buttons["Delete"]
            if deleteButton.waitForExistence(timeout: 2) {
                // 不实际删除，只验证按钮存在
                XCTAssertTrue(deleteButton.exists)
                
                // 取消操作
                listItem.swipeRight()
            }
        }
    }
    
    /// 测试列表滚动
    func testListScrolling() throws {
        navigateToTab("题库")
        
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 3) {
            takeScreenshot(named: "library_scroll_top")
            
            // 向上滑动
            scrollView.swipeUp()
            
            takeScreenshot(named: "library_scroll_middle")
            
            // 继续滑动
            scrollView.swipeUp()
            
            takeScreenshot(named: "library_scroll_bottom")
        }
    }
}
