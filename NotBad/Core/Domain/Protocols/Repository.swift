//
//  Repository.swift
//  NotBad
//
//  Created by YourName on 2024/07/15.
//

import Foundation

// 基础 Repository 协议，定义了数据操作的基本接口
protocol Repository {
    associatedtype Entity // 关联类型，表示该 Repository 操作的实体类型
    
    // 获取所有实体
    func getAll() async throws -> [Entity]
    
    // 根据ID获取单个实体
    func get(id: UUID) async throws -> Entity?
    
    // 添加或更新实体
    func save(entity: Entity) async throws
    
    // 删除实体
    func delete(id: UUID) async throws
}
