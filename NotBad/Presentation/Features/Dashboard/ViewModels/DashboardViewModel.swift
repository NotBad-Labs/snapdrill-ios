import SwiftUI
import Foundation

// MARK: - DashboardViewModel
// 位置: Presentation/Features/Dashboard/ViewModels/DashboardViewModel.swift

/// Dashboard首页视图模型
/// 负责管理Dashboard页面的状态和业务逻辑
/// TODO: 架构重构 - 将业务逻辑迁移到Use Cases，数据模型迁移到Domain层
@MainActor
@Observable
class DashboardViewModel {
    
    // MARK: - Published Properties
    
    /// 加载状态
    var isLoading: Bool = false
    
    /// 错误信息
    var errorMessage: String?
    
    /// 用户基本信息（暂时简化）
    var userInfo: BasicUserInfo?
    
    // MARK: - Dependencies
    // TODO: 架构重构 - 注入Use Cases和Repository
    // private let getDashboardDataUseCase: GetDashboardDataUseCase
    // private let userRepository: UserRepository
    // private let studyRepository: StudyRepository
    
    // MARK: - Initialization
    
    init() {
        setupInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 刷新页面数据
    func refreshData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 模拟数据加载
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8秒
            
            // TODO: 架构重构 - 调用GetDashboardDataUseCase
            userInfo = await loadUserInfo()
            
        } catch {
            errorMessage = "数据加载失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    /// 设置初始化数据
    private func setupInitialData() {
        userInfo = BasicUserInfo.mockData
    }
    
    /// 加载用户信息
    private func loadUserInfo() async -> BasicUserInfo {
        // TODO: 架构重构 - 调用真实的用户服务
        return BasicUserInfo.mockData
    }
}

// MARK: - 简化的数据模型
// TODO: 架构重构 - 将这些模型迁移到Core/Domain/Entities/

/// 基础用户信息（简化版）
struct BasicUserInfo {
    let username: String
    let greeting: String
    
    static let mockData = BasicUserInfo(
        username: "小明同学",
        greeting: "早上好"
    )
}