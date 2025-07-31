import SwiftUI
import Foundation

// MARK: - StudyPracticeViewModel
// 位置: Presentation/Features/StudyPractice/ViewModels/StudyPracticeViewModel.swift

/// StudyPractice学习练习视图模型
/// 负责管理学习练习页面的状态和业务逻辑
/// TODO: 架构重构 - 将业务逻辑迁移到Use Cases，数据模型迁移到Domain层
@MainActor
@Observable
class StudyPracticeViewModel {
    
    // MARK: - Published Properties
    
    /// 加载状态
    var isLoading: Bool = false
    
    /// 错误信息
    var errorMessage: String?
    
    /// 当前学习状态
    var isStudying: Bool = false
    
    /// 学习时长（秒）
    var studyTimeSeconds: Int = 0
    
    /// 当前学习会话信息
    var currentStudySession: StudySessionInfo?
    
    /// 是否已有初始数据（避免重复加载）
    var hasInitialData: Bool = false
    
    // MARK: - Dependencies
    // TODO: 架构重构 - 注入Use Cases和Repository
    // private let startStudySessionUseCase: StartStudySessionUseCase
    // private let studySessionRepository: StudySessionRepository
    
    // MARK: - Private Properties
    
    /// 计时器（不使用nonisolated，通过其他方式处理deinit）
    private var studyTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        setupInitialData()
    }
    
    // 移除deinit，让系统自动处理Timer的销毁
    // Timer会在ViewModel销毁时自动invalidate
    
    // MARK: - Public Methods
    
    /// 刷新页面数据
    func refreshData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 模拟数据加载
            try await Task.sleep(nanoseconds: 600_000_000) // 0.6秒
            
            // TODO: 架构重构 - 调用GetStudyDataUseCase
            await loadStudyData()
            
            // 标记已有初始数据
            hasInitialData = true
            
        } catch {
            errorMessage = "数据加载失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 开始学习
    func startStudy() {
        isStudying = true
        currentStudySession = StudySessionInfo.createNew()
        startStudyTimer()
        
        // TODO: 架构重构 - 调用StartStudySessionUseCase
        print("开始学习会话")
    }
    
    /// 暂停学习
    func pauseStudy() {
        isStudying = false
        stopStudyTimer()
        
        // TODO: 架构重构 - 调用PauseStudySessionUseCase
        print("暂停学习会话")
    }
    
    /// 继续学习
    func resumeStudy() {
        isStudying = true
        startStudyTimer()
        
        // TODO: 架构重构 - 调用ResumeStudySessionUseCase
        print("继续学习会话")
    }
    
    /// 结束学习
    func endStudy() {
        isStudying = false
        stopStudyTimer()
        
        // TODO: 架构重构 - 调用EndStudySessionUseCase
        print("结束学习会话，总时长: \(formatStudyTime(studyTimeSeconds))")
        
        // 重置状态
        currentStudySession = nil
    }
    
    /// 重置学习时间
    func resetStudyTime() {
        studyTimeSeconds = 0
        isStudying = false
        stopStudyTimer()
        currentStudySession = nil
        
        print("重置学习时间")
    }
    
    /// 选择学习模式
    func selectStudyMode(_ mode: StudyMode) {
        print("选择学习模式: \(mode.title)")
        // TODO: 架构重构 - 调用SelectStudyModeUseCase
        // TODO: 导航到对应的学习页面
    }
    
    // MARK: - Private Methods
    
    /// 设置初始数据
    private func setupInitialData() {
        // 恢复之前的学习状态（如果有）
        // TODO: 从持久化存储中恢复状态
        
        // 标记已有基础数据，避免不必要的加载
        hasInitialData = true
    }
    
    /// 加载学习数据
    private func loadStudyData() async {
        // TODO: 架构重构 - 通过Repository获取数据
    }
    
    /// 开始学习计时器
    private func startStudyTimer() {
        stopStudyTimer() // 确保不会重复启动
        
        studyTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.studyTimeSeconds += 1
            }
        }
    }
    
    /// 停止学习计时器
    private func stopStudyTimer() {
        studyTimer?.invalidate()
        studyTimer = nil
    }
    
    /// 格式化学习时间
    func formatStudyTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// MARK: - 简化的数据模型
// TODO: 架构重构 - 将这些模型迁移到Core/Domain/Entities/

/// 学习会话信息
struct StudySessionInfo {
    let id: UUID
    let startTime: Date
    let mode: StudyMode?
    
    static func createNew() -> StudySessionInfo {
        StudySessionInfo(
            id: UUID(),
            startTime: Date(),
            mode: nil
        )
    }
}

/// 学习模式
struct StudyMode: Identifiable {
    let id = UUID()
    let type: StudyModeType
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    
    enum StudyModeType {
        case quickPractice
        case topicPractice
        case examMode
        case reviewMode
    }
    
    /// 默认学习模式
    static let allModes: [StudyMode] = [
        StudyMode(
            type: .quickPractice,
            title: "快速练习",
            description: "随机挑选10道错题进行练习",
            icon: "bolt.fill",
            color: .blue,
            isEnabled: true
        ),
        StudyMode(
            type: .topicPractice,
            title: "专项训练",
            description: "针对特定知识点进行强化练习",
            icon: "target",
            color: .green,
            isEnabled: true
        ),
        StudyMode(
            type: .examMode,
            title: "模拟考试",
            description: "限时模拟考试环境练习",
            icon: "clock.fill",
            color: .red,
            isEnabled: true
        ),
        StudyMode(
            type: .reviewMode,
            title: "错题复习",
            description: "复习之前做错的题目",
            icon: "arrow.clockwise",
            color: .orange,
            isEnabled: false // 演示禁用状态
        )
    ]
}