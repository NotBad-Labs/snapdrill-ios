//
//  AppEnvironment.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation
import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()
    
    // MARK: - Dependencies
    
    // 以后我们会在这里注入各种服务
    // private let questionRepository: QuestionRepository
    // private let userRepository: UserRepository
    
    private init() {
        setupDependencies()
    }
    
    private func setupDependencies() {
        // 初始化依赖项
        print("🚀 AppEnvironment initialized")
    }
}
