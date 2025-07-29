import Foundation

/// 登录方式枚举 - 领域值对象
/// 位置: Core/Domain/ValueObjects/Authentication/LoginMethod.swift
enum LoginMethod: String, CaseIterable {
    case email = "email"
    case phone = "phone"
    case username = "username"
    
    /// 显示标题
    var title: String {
        switch self {
        case .email: return "邮箱登录"
        case .phone: return "手机登录"
        case .username: return "用户名"
        }
    }
    
    /// 输入框占位符文本
    var placeholder: String {
        switch self {
        case .email: return "请输入邮箱地址"
        case .phone: return "请输入手机号码"
        case .username: return "请输入用户名"
        }
    }
    
    /// SF Symbols 图标名称
    var iconName: String {
        switch self {
        case .email: return "envelope"
        case .phone: return "phone"
        case .username: return "person"
        }
    }
}