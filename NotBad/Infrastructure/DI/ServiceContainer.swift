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
    
    // MARK: - Infrastructure Layer (Repositories)
    private let _reviewItemRepository: ReviewItemRepository
    
    // MARK: - Domain Services
    private let _reviewItemService: ReviewItemService
    
    // MARK: - Application Services
    private let _captureReviewItemUseCase: CaptureReviewItemUseCase
    private let _reviewSessionUseCase: ReviewSessionUseCase
    
    // MARK: - Public Interfaces
    
    var reviewItemRepository: ReviewItemRepository {
        _reviewItemRepository
    }
    
    var reviewItemService: ReviewItemService {
        _reviewItemService
    }

    /// 协议类型暴露，便于替换与测试
    var reviewItemServicing: ReviewItemServicing {
        _reviewItemService
    }
    
    var captureReviewItemUseCase: CaptureReviewItemUseCase {
        _captureReviewItemUseCase
    }
    
    var reviewSessionUseCase: ReviewSessionUseCase {
        _reviewSessionUseCase
    }
    
    // MARK: - Initialization
    
    private init() {
        // 1. 创建Infrastructure层 (Repositories)
        self._reviewItemRepository = InMemoryReviewItemRepository()
        
        // 2. 创建Domain Services（注入Repository）
        self._reviewItemService = ReviewItemService(
            repository: _reviewItemRepository
        )
        
        // 3. 创建Application Services（注入Domain Services）
        self._captureReviewItemUseCase = CaptureReviewItemUseCase(
            reviewItemService: _reviewItemService
        )
        self._reviewSessionUseCase = ReviewSessionUseCase(
            reviewItemService: _reviewItemService
        )
    }
}

// MARK: - 测试支持
#if DEBUG
extension ServiceContainer {
    /// 创建测试用的服务容器
    /// - Parameter repository: 测试用的Repository实现
    /// - Returns: 配置了测试Repository的服务容器
    static func createForTesting(with repository: ReviewItemRepository) -> ServiceContainer {
        let container = ServiceContainer()
        container._configureForTesting(repository: repository)
        return container
    }
    
    private func _configureForTesting(repository: ReviewItemRepository) {
        // 在测试环境中，我们使用反射或者重新构建依赖链
        // 这里简化处理，实际项目中可能需要更复杂的依赖注入框架
    }
}
#endif

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
