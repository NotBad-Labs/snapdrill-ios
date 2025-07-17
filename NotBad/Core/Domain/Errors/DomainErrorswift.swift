//
//  DomainErrorswift.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/15/25.
//

import Foundation

// 定义一个通用的领域错误协议
protocol DomainError: Error, LocalizedError {
    var title: String { get }
    var message: String { get }
}

// 示例：一个简单的通用错误实现
enum AppError: DomainError {
    case unknown(Error?)
    case networkError(Error)
    case invalidData
    case authenticationFailed

    var title: String {
        switch self {
        case .unknown: return "未知错误"
        case .networkError: return "网络错误"
        case .invalidData: return "数据无效"
        case .authenticationFailed: return "认证失败"
        }
    }

    var message: String {
        switch self {
        case .unknown(let error): return "发生了一个未知错误: \(error?.localizedDescription ?? "请稍后再试。")"
        case .networkError(let error): return "网络请求失败: \(error.localizedDescription)"
        case .invalidData: return "接收到的数据无效。"
        case .authenticationFailed: return "用户名或密码不正确。"
        }
    }

    var errorDescription: String? {
        return message // 使其遵循 LocalizedError
    }
}

