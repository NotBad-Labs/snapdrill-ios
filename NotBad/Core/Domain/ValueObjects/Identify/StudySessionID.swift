//
//  StudySessionID.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//


//
//  StudySessionID.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

/// 学习会话的唯一标识符
/// 这是一个值对象，用强类型包装 UUID，提供类型安全
struct StudySessionID {
    /// 内部的 UUID 值
    let value: UUID
    
    /// 创建一个新的 StudySessionID（生成新的 UUID）
    init() {
        self.value = UUID()
    }
    
    /// 从现有的 UUID 创建 StudySessionID
    init(_ uuid: UUID) {
        self.value = uuid
    }
    
    /// 从字符串创建 StudySessionID（通常用于从数据库或API读取）
    init?(fromString string: String) {
        guard let uuid = UUID(uuidString: string) else {
            return nil
        }
        self.value = uuid
    }
}

// MARK: - 协议遵循
extension StudySessionID: Identifiable {
    /// Identifiable 协议要求的 id 属性
    var id: UUID { value }
}

extension StudySessionID: Hashable {
    /// 两个 StudySessionID 相等当且仅当它们的 UUID 相等
    static func == (lhs: StudySessionID, rhs: StudySessionID) -> Bool {
        lhs.value == rhs.value
    }
    
    /// hash 方法，用于在 Set 和 Dictionary 中使用
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension StudySessionID: Sendable {
    // Sendable 协议确保这个类型可以安全地在并发环境中传递
    // StudySessionID 是值类型且所有属性都是不可变的，所以自动符合 Sendable
}

extension StudySessionID: Codable {
    /// 编码时只编码 UUID 的字符串形式
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value.uuidString)
    }
    
    /// 解码时从字符串创建 UUID
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let uuidString = try container.decode(String.self)
        
        guard let uuid = UUID(uuidString: uuidString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid UUID string: \(uuidString)"
                )
            )
        }
        
        self.value = uuid
    }
}

// MARK: - 便捷方法
extension StudySessionID {
    /// 获取 UUID 的字符串表示（用于存储或显示）
    var stringValue: String {
        value.uuidString
    }
    
    /// 获取短格式的 ID（只取前8位，用于日志或调试）
    var shortString: String {
        String(stringValue.prefix(8))
    }
}

// MARK: - CustomStringConvertible（用于调试）
extension StudySessionID: CustomStringConvertible {
    var description: String {
        "StudySessionID(\(shortString))"
    }
}