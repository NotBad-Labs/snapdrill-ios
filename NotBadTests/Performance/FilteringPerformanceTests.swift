//
//  FilteringPerformanceTests.swift
//  NotBadTests
//
//  筛选和排序性能测试
//

import XCTest
@testable import NotBad

/// 筛选性能测试
///
/// 测试大数据量下筛选和排序操作的性能
final class FilteringPerformanceTests: XCTestCase {
    
    // MARK: - Test Data Generation
    
    /// 生成测试用的 ReviewItem 数组
    private func generateItems(count: Int) -> [ReviewItem] {
        TestReviewItemFactory.createRealisticDataset(count: count)
    }
    
    // MARK: - Filtering Performance Tests
    
    /// 测试 100 条数据的筛选性能
    ///
    /// 预期：< 10ms
    func testFiltering100Items() {
        let items = generateItems(count: 100)
        
        measure {
            // 筛选数学题目
            _ = items.filter { $0.subject == .math }
        }
    }
    
    /// 测试 500 条数据的筛选性能
    ///
    /// 预期：< 50ms
    func testFiltering500Items() {
        let items = generateItems(count: 500)
        
        measure {
            // 筛选需要复习的数学题目
            _ = items.filter { $0.subject == .math && $0.needsReview }
        }
    }
    
    /// 测试 1000 条数据的筛选性能
    ///
    /// 预期：< 100ms
    func testFiltering1000Items() {
        let items = generateItems(count: 1000)
        
        measure {
            // 多条件筛选
            _ = items.filter {
                $0.subject == .math &&
                $0.mastery != .mastered &&
                $0.difficulty == .hard
            }
        }
    }
    
    // MARK: - Sorting Performance Tests
    
    /// 测试 500 条数据的排序性能
    ///
    /// 预期：< 30ms
    func testSorting500Items() {
        let items = generateItems(count: 500)
        
        measure {
            _ = items.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    /// 测试多字段排序性能
    ///
    /// 预期：< 50ms
    func testMultiFieldSorting500Items() {
        let items = generateItems(count: 500)
        
        measure {
            _ = items.sorted {
                if $0.subject.rawValue != $1.subject.rawValue {
                    return $0.subject.rawValue < $1.subject.rawValue
                }
                return $0.createdAt > $1.createdAt
            }
        }
    }
    
    // MARK: - Combined Operations
    
    /// 测试筛选 + 排序组合操作性能
    ///
    /// 预期：< 80ms
    func testFilterAndSort500Items() {
        let items = generateItems(count: 500)
        
        measure {
            let filtered = items.filter { $0.needsReview }
            _ = filtered.sorted { $0.nextReviewDate < $1.nextReviewDate }
        }
    }
    
    /// 测试搜索性能
    ///
    /// 预期：< 50ms
    func testSearchInItems() {
        let items = generateItems(count: 500)
        let searchText = "数学"
        
        measure {
            _ = items.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.note.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Grouping Performance
    
    /// 测试按学科分组性能
    ///
    /// 预期：< 30ms
    func testGroupingBySubject() {
        let items = generateItems(count: 500)
        
        measure {
            _ = Dictionary(grouping: items, by: { $0.subject })
        }
    }
    
    /// 测试按掌握度分组性能
    func testGroupingByMastery() {
        let items = generateItems(count: 500)
        
        measure {
            _ = Dictionary(grouping: items, by: { $0.mastery })
        }
    }
    
    // MARK: - Memory Baseline
    
    /// 记录 1000 条数据的内存基线
    func testMemoryBaseline1000Items() {
        let beforeMemory = PerformanceTestHelpers.currentMemoryUsage()
        
        let items = generateItems(count: 1000)
        
        let afterMemory = PerformanceTestHelpers.currentMemoryUsage()
        let growth = afterMemory > beforeMemory ? afterMemory - beforeMemory : 0
        
        print("📊 1000 条数据内存占用:")
        print("  - 增长: \(growth / 1024) KB")
        print("  - 每条平均: \(growth / 1024 / 1000) KB")
        
        // 保持引用防止被优化掉
        XCTAssertEqual(items.count, 1000)
    }
}
