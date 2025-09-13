//
//  ReviewItemRepository.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import Foundation

// MARK: - 复习项仓储协议
/// 复习项仓储协议，定义数据访问的抽象接口
/// 遵循依赖倒置原则，Domain层定义接口，Infrastructure层实现具体逻辑
protocol ReviewItemRepository {
    /// 创建新的复习项
    /// - Parameter item: 要创建的复习项
    /// - Returns: 创建成功的复习项
    /// - Throws: 创建失败时抛出错误
    func create(_ item: ReviewItem) async throws -> ReviewItem
    
    /// 根据ID获取复习项
    /// - Parameter id: 复习项ID
    /// - Returns: 找到的复习项，如果不存在则返回nil
    /// - Throws: 查询失败时抛出错误
    func getById(_ id: UUID) async throws -> ReviewItem?
    
    /// 获取所有复习项
    /// - Returns: 所有复习项的数组
    /// - Throws: 查询失败时抛出错误
    func getAll() async throws -> [ReviewItem]
    
    /// 根据用户ID获取复习项
    /// - Parameter ownerId: 用户ID
    /// - Returns: 该用户的所有复习项
    /// - Throws: 查询失败时抛出错误
    func getByOwner(_ ownerId: UUID) async throws -> [ReviewItem]
    
    /// 根据科目获取复习项
    /// - Parameter subject: 科目名称
    /// - Returns: 该科目的所有复习项
    /// - Throws: 查询失败时抛出错误
    func getBySubject(_ subject: String) async throws -> [ReviewItem]
    
    /// 根据掌握程度获取复习项
    /// - Parameter masteryLevel: 掌握程度
    /// - Returns: 该掌握程度的所有复习项
    /// - Throws: 查询失败时抛出错误
    func getByMasteryLevel(_ masteryLevel: MasteryLevel) async throws -> [ReviewItem]
    
    /// 更新复习项
    /// - Parameter item: 要更新的复习项
    /// - Returns: 更新后的复习项
    /// - Throws: 更新失败时抛出错误
    func update(_ item: ReviewItem) async throws -> ReviewItem
    
    /// 删除复习项
    /// - Parameter id: 要删除的复习项ID
    /// - Throws: 删除失败时抛出错误
    func delete(_ id: UUID) async throws
    
    /// 批量删除复习项
    /// - Parameter ids: 要删除的复习项ID数组
    /// - Throws: 删除失败时抛出错误
    func deleteBatch(_ ids: [UUID]) async throws
    
    /// 搜索复习项
    /// - Parameter query: 搜索关键词
    /// - Returns: 匹配的复习项数组
    /// - Throws: 搜索失败时抛出错误
    func search(_ query: String) async throws -> [ReviewItem]
    
    /// 添加学习记录
    /// - Parameters:
    ///   - itemId: 复习项ID
    ///   - record: 学习记录
    /// - Returns: 更新后的复习项
    /// - Throws: 添加失败时抛出错误
    func addStudyRecord(itemId: UUID, record: StudyRecord) async throws -> ReviewItem
    
    /// 更新掌握程度
    /// - Parameters:
    ///   - itemId: 复习项ID
    ///   - masteryLevel: 新的掌握程度
    /// - Returns: 更新后的复习项
    /// - Throws: 更新失败时抛出错误
    func updateMasteryLevel(itemId: UUID, masteryLevel: MasteryLevel) async throws -> ReviewItem
}

// MARK: - 复习项仓储错误类型
/// 复习项仓储操作可能出现的错误类型
enum ReviewItemRepositoryError: Error, LocalizedError {
    case itemNotFound(UUID)
    case itemAlreadyExists(UUID)
    case invalidData(String)
    case storageError(String)
    case networkError(String)
    case permissionDenied(String)
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound(let id):
            return "复习项未找到: \(id)"
        case .itemAlreadyExists(let id):
            return "复习项已存在: \(id)"
        case .invalidData(let message):
            return "数据无效: \(message)"
        case .storageError(let message):
            return "存储错误: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .permissionDenied(let message):
            return "权限不足: \(message)"
        }
    }
}
