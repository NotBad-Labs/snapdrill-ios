//
//  ServiceContainer.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import Foundation
import SwiftUI

/// 服务容器
/// 管理依赖注入，遵循整洁架构原则
final class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    // MARK: - 服务实例
    private let _reviewItemService: ReviewItemService
    
    // MARK: - 公共接口
    var reviewItemService: ReviewItemService {
        _reviewItemService
    }
    
    private init() {
        // 在这里可以根据配置选择不同的实现
        // 开发阶段使用内存实现，生产环境可以替换为SwiftData实现
        self._reviewItemService = InMemoryReviewItemService()
    }
    
    /// 配置服务（用于测试或不同环境）
    func configure(reviewItemService: ReviewItemService) {
        // 如果需要运行时配置，可以在这里实现
        // 但要保持架构的清洁性
    }
}

/// 环境键，用于SwiftUI依赖注入
private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}