//
//  UserRepository.swift
//  NotBad
//
//  Created by YourName on 2024/07/15.
//

import Foundation

// 用户实体（占位符）
// TODO: 未来分离为纯领域模型
struct User {
    let id: UUID
    let username: String
    let email: String
    // ... 其他用户属性
}

// 用户仓库协议，继承自基础 Repository
protocol UserRepository: Repository where Entity == User {
    // 可以添加用户特有的操作，例如根据邮箱查找用户
    func getUserByEmail(_ email: String) async throws -> User?
}
