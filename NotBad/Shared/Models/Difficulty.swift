//
//  Difficulty.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/18/25.
//

import Foundation
import SwiftUI

enum Difficulty: Int, CaseIterable, Codable, Sendable {
    case 基础题 = 1
    case 简单题 = 2
    case 中等题 = 3
    case 困难题 = 4
    case 极难题 = 5
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .基础题: return "基础题"
        case .简单题: return "简单题"
        case .中等题: return "中等题"
        case .困难题: return "困难题"
        case .极难题: return "极难题"
        }
    }
    
    /// 对应的颜色（与DifficultyBadge保持一致）
    var color: Color {
        Color.difficultyColor(for: self.rawValue)
    }
    
    /// 默认难度
    static let `default`: Difficulty = .中等题
    
    /// 从Int值创建Difficulty（安全转换）
    static func from(value: Int) -> Difficulty {
        return Difficulty(rawValue: value) ?? .default
    }
    
    /// 简短描述（用于选择器等UI）
    var shortName: String {
        switch self {
        case .基础题: return "基础"
        case .简单题: return "简单"
        case .中等题: return "中等"
        case .困难题: return "困难"
        case .极难题: return "极难"
        }
    }
}

// MARK: - Identifiable
extension Difficulty: Identifiable {
    var id: Int { rawValue }
}

// MARK: - Comparable
extension Difficulty: Comparable {
    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}