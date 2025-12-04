//
//  SelectionManager.swift
//  NotBad
//
//  通用选择状态管理器
//

import Foundation
import Observation

// MARK: - Selection Manager

/// 通用选择状态管理器
///
/// 管理多选模式下的选中状态，可复用于多个场景：
/// - 错题库批量删除
/// - 批量标记掌握程度
/// - 批量导出选择
///
/// ## 使用示例
///
/// ```swift
/// @State private var selection = SelectionManager<UUID>()
///
/// // 切换选择模式
/// selection.toggleMode()
///
/// // 选中/取消选中
/// selection.toggle(item.id)
///
/// // 全选
/// selection.selectAll(items.map(\.id))
///
/// // 获取选中项
/// let selectedItems = items.filter { selection.isSelected($0.id) }
/// ```
@MainActor
@Observable
final class SelectionManager<ID: Hashable & Sendable>: @unchecked Sendable {
    
    // MARK: - State
    
    /// 是否处于选择模式
    private(set) var isSelectionMode = false
    
    /// 选中的 ID 集合
    private(set) var selectedIDs: Set<ID> = []
    
    // MARK: - Computed Properties
    
    /// 选中数量
    var selectedCount: Int {
        selectedIDs.count
    }
    
    /// 是否有选中项
    var hasSelection: Bool {
        !selectedIDs.isEmpty
    }
    
    // MARK: - Mode Control
    
    /// 切换选择模式
    ///
    /// 进入选择模式时保留已选项，退出时清空选中状态。
    func toggleMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedIDs.removeAll()
        }
    }
    
    /// 进入选择模式
    func enterSelectionMode() {
        isSelectionMode = true
    }
    
    /// 退出选择模式并清空选中项
    func exitSelectionMode() {
        isSelectionMode = false
        selectedIDs.removeAll()
    }
    
    // MARK: - Selection Control
    
    /// 切换单个项目的选中状态
    ///
    /// - Parameter id: 要切换的项目 ID
    func toggle(_ id: ID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
    
    /// 选中单个项目
    ///
    /// - Parameter id: 要选中的项目 ID
    func select(_ id: ID) {
        selectedIDs.insert(id)
    }
    
    /// 取消选中单个项目
    ///
    /// - Parameter id: 要取消选中的项目 ID
    func deselect(_ id: ID) {
        selectedIDs.remove(id)
    }
    
    /// 检查项目是否被选中
    ///
    /// - Parameter id: 项目 ID
    /// - Returns: 是否被选中
    func isSelected(_ id: ID) -> Bool {
        selectedIDs.contains(id)
    }
    
    /// 全选
    ///
    /// - Parameter ids: 所有可选项目的 ID 列表
    func selectAll(_ ids: [ID]) {
        selectedIDs = Set(ids)
    }
    
    /// 全选（从 Set）
    ///
    /// - Parameter ids: 所有可选项目的 ID 集合
    func selectAll(_ ids: Set<ID>) {
        selectedIDs = ids
    }
    
    /// 取消全选
    func deselectAll() {
        selectedIDs.removeAll()
    }
    
    /// 反选
    ///
    /// - Parameter allIDs: 所有可选项目的 ID 列表
    func invertSelection(_ allIDs: [ID]) {
        let allSet = Set(allIDs)
        selectedIDs = allSet.subtracting(selectedIDs)
    }
    
    // MARK: - Batch Operations
    
    /// 获取选中的项目
    ///
    /// - Parameter items: 所有项目列表
    /// - Parameter idKeyPath: 获取 ID 的 KeyPath
    /// - Returns: 选中的项目列表
    func selectedItems<T>(from items: [T], id idKeyPath: KeyPath<T, ID>) -> [T] {
        items.filter { selectedIDs.contains($0[keyPath: idKeyPath]) }
    }
    
    /// 完成批量操作后退出选择模式
    func completeOperation() {
        selectedIDs.removeAll()
        isSelectionMode = false
    }
}

// MARK: - Convenience Extension for UUID

extension SelectionManager where ID == UUID {
    
    /// 从 ReviewItem 数组全选
    func selectAll(from items: [ReviewItem]) {
        selectedIDs = Set(items.map(\.id))
    }
    
    /// 从 ReviewItem 数组获取选中项
    func selectedItems(from items: [ReviewItem]) -> [ReviewItem] {
        items.filter { selectedIDs.contains($0.id) }
    }
}
