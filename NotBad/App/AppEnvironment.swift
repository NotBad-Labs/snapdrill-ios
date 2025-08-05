// MARK: - AppEnvironment.swift
/**
 * 应用依赖注入环境容器
 * 
 * 职责：
 * - 创建和管理所有应用级别的服务实例
 * - 提供依赖注入容器功能，解决对象间的依赖关系
 * - 管理外部服务的初始化和配置
 * - 注册命令查询处理器到总线系统
 * 
 * 设计原则：
 * - 依赖倒置：面向接口编程，具体实现在运行时注入
 * - 单例管理：确保服务实例在整个应用生命周期中的唯一性
 * - 延迟初始化：服务在首次需要时才创建，提高启动性能
 * - 环境隔离：支持不同环境（开发、测试、生产）的配置
 * 
 * 架构位置：
 * ```
 * NotBadApp
 *     ↓ 创建
 * AppEnvironment (这里) ← 依赖注入容器
 *     ↓ 提供服务
 * 各层组件 ← 获取所需依赖
 * ```
 * 
 * 使用方式：
 * ```swift
 * @EnvironmentObject private var environment: AppEnvironment
 * 
 * // 获取服务
 * let service = environment.questionCaptureService
 * 
 * // 执行命令
 * try await environment.commandQueryBus.execute(command)
 * ```
 * 
 * 注意事项：
 * - 必须在使用前调用 configure() 方法完成初始化
 * - 所有服务都是线程安全的，使用 @MainActor 确保主线程访问
 * - 配置过程是异步的，可能会抛出异常
 * - 服务间的依赖关系在 configure() 中建立，顺序很重要
 * 
 * @author NotBad Team
 * @since 1.0.0
 * @updated 2025-08-01
 */

import Foundation
import Observation

@Observable
@MainActor
class AppEnvironment {
    
    // MARK: - 配置状态
    
    /// 环境是否已完成配置，用于防止重复初始化和确保服务可用性
    private(set) var isConfigured: Bool = false
    
    /// 当前应用配置，包含环境相关的设置和参数
    private(set) var configuration: AppConfiguration!
    
    // MARK: - 核心应用服务
    // 这些服务直接对应用例层，提供业务功能的核心实现
    
    /// 题目录入服务 - 负责题目的捕获、识别、验证等功能
    private(set) var questionCaptureService: QuestionCaptureService!
    
    /// 题目管理服务 - 负责题目的增删改查、分类、标签等管理功能
    private(set) var questionManagementService: QuestionManagementService!
    
    /// 学习练习服务 - 负责学习会话、练习模式、进度跟踪等功能
    private(set) var studyPracticeService: StudyPracticeService!
    
    /// 数据同步服务 - 负责本地与云端数据的同步
    private(set) var syncService: SyncService!
    
    // MARK: - 仓储层服务
    // 这些仓储提供数据访问抽象，隔离具体的存储实现
    
    /// 题目仓储 - 负责题目相关数据的持久化操作
    private(set) var questionRepository: QuestionRepository!
    
    /// 学习会话仓储 - 负责学习会话数据的持久化操作
    private(set) var studySessionRepository: StudySessionRepository!
    
    /// 用户配置仓储 - 负责用户信息和配置的持久化操作
    private(set) var userProfileRepository: UserProfileRepository!
    
    // MARK: - 外部服务集成
    // 这些服务封装了对外部 API 或 SDK 的调用
    
    /// OCR 识别服务 - 负责图像文字识别功能
    private(set) var ocrService: OCRService!
    
    /// 数据分析服务 - 负责用户行为统计和应用分析
    private(set) var analyticsService: AnalyticsService!
    
    /// 文件解析服务 - 负责各种文件格式的解析（PDF、Word等）
    private(set) var fileParserService: FileParserService!
    
    // MARK: - 架构组件
    
    /// 命令查询总线 - CQRS 模式的核心组件，负责命令和查询的分发
    private(set) var commandQueryBus: CommandQueryBus!
    
    // MARK: - 初始化
    
    /**
     * 初始化依赖注入环境
     * 
     * 创建一个未配置的环境实例，实际的服务创建和配置
     * 将在 configure() 方法中异步完成
     */
    init() {
        // 延迟初始化模式：实际配置在 configure() 方法中完成
        // 这样可以支持异步初始化和错误处理
    }
    
    // MARK: - 公开方法 - 环境配置
    
    /**
     * 配置依赖注入环境
     * 
     * 按照正确的依赖顺序创建所有服务实例，建立它们之间的依赖关系。
     * 该方法是幂等的，多次调用不会重复初始化。
     * 
     * 初始化顺序：
     * 1. 加载应用配置
     * 2. 创建外部服务（无依赖）
     * 3. 创建仓储层（依赖配置）
     * 4. 创建领域服务（依赖仓储）
     * 5. 创建应用服务（依赖领域服务和仓储）
     * 6. 创建架构组件（命令查询总线）
     * 7. 注册处理器
     * 
     * @throws ConfigurationError 如果配置过程中发生错误
     * 
     * 使用示例：
     * ```swift
     * do {
     *     try await appEnvironment.configure()
     *     // 现在可以安全使用各种服务
     * } catch {
     *     // 处理配置错误
     * }
     * ```
     */
    func configure() async throws {
        // 防止重复配置
        guard !isConfigured else {
            print("⚠️ AppEnvironment 已经配置过，跳过重复配置")
            return
        }
        
        print("🚀 开始配置 AppEnvironment...")
        
        do {
            // 第一步：加载应用配置
            try await loadConfiguration()
            
            // 第二步：初始化外部服务
            try await initializeExternalServices()
            
            // 第三步：初始化仓储层
            try await initializeRepositories()
            
            // 第四步：初始化领域服务
            try await initializeDomainServices()
            
            // 第五步：初始化应用服务
            try await initializeApplicationServices()
            
            // 第六步：初始化架构组件
            try await initializeArchitecturalComponents()
            
            // 第七步：注册命令查询处理器
            try await registerHandlers()
            
            // 标记配置完成
            isConfigured = true
            print("✅ AppEnvironment 配置完成")
            
        } catch {
            print("❌ AppEnvironment 配置失败: \(error)")
            // 清理已创建的资源
            cleanup()
            throw error
        }
    }
    
    // MARK: - 私有方法 - 初始化步骤
    
    /**
     * 加载应用配置
     * 
     * 根据当前环境（开发、测试、生产）加载对应的配置参数
     */
    private func loadConfiguration() async throws {
        print("📋 加载应用配置...")
        configuration = AppConfiguration.current
        print("📋 当前环境: \(configuration.environment)")
    }
    
    /**
     * 初始化外部服务
     * 
     * 创建与外部系统集成的服务实例，这些服务通常不依赖其他内部服务
     */
    private func initializeExternalServices() async throws {
        print("🔌 初始化外部服务...")
        
        // OCR 服务初始化
        ocrService = try await createOCRService()
        
        // 分析服务初始化
        analyticsService = try await createAnalyticsService()
        
        // 文件解析服务初始化
        fileParserService = try await createFileParserService()
        
        print("🔌 外部服务初始化完成")
    }
    
    /**
     * 初始化仓储层
     * 
     * 创建数据访问层的仓储实例，依赖于应用配置
     */
    private func initializeRepositories() async throws {
        print("🗄️ 初始化仓储层...")
        
        // 根据配置选择合适的仓储实现
        questionRepository = try await createQuestionRepository()
        studySessionRepository = try await createStudySessionRepository()
        userProfileRepository = try await createUserProfileRepository()
        
        print("🗄️ 仓储层初始化完成")
    }
    
    /**
     * 初始化领域服务
     * 
     * 创建领域层的服务实例，这些服务封装跨聚合的业务逻辑
     */
    private func initializeDomainServices() async throws {
        print("⚙️ 初始化领域服务...")
        
        // 领域服务通常是无状态的，主要用于封装复杂的业务规则
        // 这里先预留接口，具体实现根据业务需要添加
        
        print("⚙️ 领域服务初始化完成")
    }
    
    /**
     * 初始化应用服务
     * 
     * 创建应用层的服务实例，这些服务协调用例的执行
     */
    private func initializeApplicationServices() async throws {
        print("🎯 初始化应用服务...")
        
        // 题目录入服务
        questionCaptureService = try await createQuestionCaptureService()
        
        // 题目管理服务
        questionManagementService = try await createQuestionManagementService()
        
        // 学习练习服务
        studyPracticeService = try await createStudyPracticeService()
        
        // 同步服务
        syncService = try await createSyncService()
        
        print("🎯 应用服务初始化完成")
    }
    
    /**
     * 初始化架构组件
     * 
     * 创建支持架构模式的组件，如 CQRS 的命令查询总线
     */
    private func initializeArchitecturalComponents() async throws {
        print("🏗️ 初始化架构组件...")
        
        commandQueryBus = CommandQueryBus()
        
        print("🏗️ 架构组件初始化完成")
    }
    
    /**
     * 注册命令查询处理器
     * 
     * 将各种命令和查询的处理器注册到总线中
     */
    private func registerHandlers() async throws {
        print("📝 注册命令查询处理器...")
        
        try await registerCommandHandlers()
        try await registerQueryHandlers()
        
        print("📝 处理器注册完成")
    }
    
    // MARK: - 私有方法 - 服务创建工厂
    
    /**
     * 创建 OCR 服务实例
     */
    private func createOCRService() async throws -> OCRService {
        // 根据配置选择不同的 OCR 服务提供商
        switch configuration.ocrProvider {
        case .apple:
            return AppleVisionOCRService()
        case .google:
            return GoogleCloudVisionService(apiKey: configuration.googleAPIKey)
        case .azure:
            return AzureCognitiveServicesOCRService(subscriptionKey: configuration.azureKey)
        }
    }
    
    /**
     * 创建分析服务实例
     */
    private func createAnalyticsService() async throws -> AnalyticsService {
        if configuration.enableAnalytics {
            return FirebaseAnalyticsService()
        } else {
            return NoOpAnalyticsService() // 开发环境使用空实现
        }
    }
    
    /**
     * 创建文件解析服务实例
     */
    private func createFileParserService() async throws -> FileParserService {
        return CompositeFileParserService([
            PDFParserService(),
            WordDocumentParserService(),
            ImageParserService()
        ])
    }
    
    /**
     * 创建题目仓储实例
     */
    private func createQuestionRepository() async throws -> QuestionRepository {
        let swiftDataRepository = SwiftDataQuestionRepository()
        
        if configuration.enableCloudSync {
            return CloudSyncQuestionRepository(
                localRepository: swiftDataRepository,
                cloudService: configuration.cloudService
            )
        } else {
            return swiftDataRepository
        }
    }
    
    /**
     * 创建学习会话仓储实例
     */
    private func createStudySessionRepository() async throws -> StudySessionRepository {
        return SwiftDataStudySessionRepository()
    }
    
    /**
     * 创建用户配置仓储实例
     */
    private func createUserProfileRepository() async throws -> UserProfileRepository {
        return SwiftDataUserProfileRepository()
    }
    
    /**
     * 创建题目录入服务实例
     */
    private func createQuestionCaptureService() async throws -> QuestionCaptureService {
        return QuestionCaptureServiceImpl(
            questionRepository: questionRepository,
            ocrService: ocrService,
            fileParserService: fileParserService,
            analyticsService: analyticsService
        )
    }
    
    /**
     * 创建题目管理服务实例
     */
    private func createQuestionManagementService() async throws -> QuestionManagementService {
        return QuestionManagementServiceImpl(
            questionRepository: questionRepository
        )
    }
    
    /**
     * 创建学习练习服务实例
     */
    private func createStudyPracticeService() async throws -> StudyPracticeService {
        return StudyPracticeServiceImpl(
            questionRepository: questionRepository,
            studySessionRepository: studySessionRepository,
            analyticsService: analyticsService
        )
    }
    
    /**
     * 创建同步服务实例
     */
    private func createSyncService() async throws -> SyncService {
        return SyncServiceImpl(
            questionRepository: questionRepository,
            studySessionRepository: studySessionRepository,
            userProfileRepository: userProfileRepository,
            cloudService: configuration.cloudService
        )
    }
    
    // MARK: - 私有方法 - 处理器注册
    
    /**
     * 注册命令处理器
     */
    private func registerCommandHandlers() async throws {
        // 题目相关命令处理器
        commandQueryBus.register(
            CaptureQuestionCommandHandler(captureService: questionCaptureService)
        )
        commandQueryBus.register(
            CreateQuestionCommandHandler(managementService: questionManagementService)
        )
        commandQueryBus.register(
            UpdateQuestionCommandHandler(managementService: questionManagementService)
        )
        commandQueryBus.register(
            DeleteQuestionCommandHandler(managementService: questionManagementService)
        )
        
        // 学习相关命令处理器
        commandQueryBus.register(
            StartStudySessionCommandHandler(practiceService: studyPracticeService)
        )
        commandQueryBus.register(
            SubmitAnswerCommandHandler(practiceService: studyPracticeService)
        )
        commandQueryBus.register(
            EndStudySessionCommandHandler(practiceService: studyPracticeService)
        )
    }
    
    /**
     * 注册查询处理器
     */
    private func registerQueryHandlers() async throws {
        // 题目相关查询处理器
        commandQueryBus.register(
            GetQuestionsQueryHandler(repository: questionRepository)
        )
        commandQueryBus.register(
            GetQuestionByIdQueryHandler(repository: questionRepository)
        )
        commandQueryBus.register(
            SearchQuestionsQueryHandler(repository: questionRepository)
        )
        
        // 学习相关查询处理器
        commandQueryBus.register(
            GetStudySessionsQueryHandler(repository: studySessionRepository)
        )
        commandQueryBus.register(
            GetStudyStatisticsQueryHandler(
                studySessionRepository: studySessionRepository,
                questionRepository: questionRepository
            )
        )
    }
    
    // MARK: - 私有方法 - 资源清理
    
    /**
     * 清理已创建的资源
     * 
     * 在配置失败时调用，清理已经创建的资源以避免内存泄漏
     */
    private func cleanup() {
        print("🧹 清理 AppEnvironment 资源...")
        
        // 清理服务实例
        questionCaptureService = nil
        questionManagementService = nil
        studyPracticeService = nil
        syncService = nil
        
        // 清理仓储实例
        questionRepository = nil
        studySessionRepository = nil
        userProfileRepository = nil
        
        // 清理外部服务实例
        ocrService = nil
        analyticsService = nil
        fileParserService = nil
        
        // 清理架构组件
        commandQueryBus = nil
        
        // 重置配置状态
        isConfigured = false
        configuration = nil
        
        print("🧹 资源清理完成")
    }
}

// MARK: - 配置错误类型

/**
 * 配置过程中可能发生的错误类型
 */
enum ConfigurationError: LocalizedError {
    case invalidConfiguration(String)
    case serviceInitializationFailed(String, Error)
    case dependencyMissing(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "配置无效: \(message)"
        case .serviceInitializationFailed(let service, let error):
            return "服务初始化失败 [\(service)]: \(error.localizedDescription)"
        case .dependencyMissing(let dependency):
            return "缺少依赖: \(dependency)"
        }
    }
}