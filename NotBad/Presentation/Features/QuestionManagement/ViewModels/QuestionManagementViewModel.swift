import SwiftUI
import Foundation

// MARK: - QuestionManagementViewModel
// 位置: Presentation/Features/QuestionManagement/ViewModels/QuestionManagementViewModel.swift

/// 题目管理视图模型
/// 负责管理题目录入、编辑、删除等功能的业务逻辑和状态
/// TODO: 架构重构 - 将业务逻辑迁移到Use Cases，数据模型迁移到Domain层
@MainActor
@Observable
class QuestionManagementViewModel {
    
    // MARK: - Published Properties
    
    /// 加载状态
    var isLoading: Bool = false
    
    /// 错误信息
    var errorMessage: String?
    
    /// 最近添加的题目列表
    var recentQuestions: [QuestionItem] = []
    
    /// 添加方式选项
    var addMethods: [AddMethodOption] = AddMethodOption.allMethods
    
    /// 当前选择的添加方式
    var selectedAddMethod: AddMethodOption?
    
    /// 搜索关键词
    var searchText: String = ""
    
    /// 筛选的题目列表
    var filteredQuestions: [QuestionItem] {
        if searchText.isEmpty {
            return recentQuestions
        } else {
            return recentQuestions.filter { question in
                question.content.localizedCaseInsensitiveContains(searchText) ||
                question.subject.localizedCaseInsensitiveContains(searchText) ||
                question.tags.contains { tag in
                    tag.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
    
    // MARK: - Dependencies
    // TODO: 架构重构 - 注入Use Cases和Repository
    // private let addQuestionUseCase: AddQuestionUseCase
    // private let questionRepository: QuestionRepository
    // private let ocrService: OCRService
    
    // MARK: - Initialization
    
    init() {
        setupInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 刷新题目列表
    func refreshQuestions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // TODO: 架构重构 - 调用GetRecentQuestionsUseCase
            recentQuestions = await loadRecentQuestions()
        } catch {
            errorMessage = "加载题目失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 选择添加方式
    func selectAddMethod(_ method: AddMethodOption) {
        selectedAddMethod = method
        
        switch method.type {
        case .camera:
            handleCameraCapture()
        case .photoLibrary:
            handlePhotoLibraryImport()
        case .fileImport:
            handleFileImport()
        case .manualInput:
            handleManualInput()
        }
    }
    
    /// 删除题目
    func deleteQuestion(_ question: QuestionItem) async {
        isLoading = true
        
        do {
            // TODO: 架构重构 - 调用DeleteQuestionUseCase
            await performDeleteQuestion(question)
            recentQuestions.removeAll { $0.id == question.id }
        } catch {
            errorMessage = "删除题目失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 编辑题目
    func editQuestion(_ question: QuestionItem) {
        // TODO: 导航到编辑页面
        print("编辑题目: \(question.id)")
    }
    
    /// 查看题目详情
    func viewQuestionDetail(_ question: QuestionItem) {
        // TODO: 导航到详情页面
        print("查看题目详情: \(question.id)")
    }
    
    // MARK: - Private Methods
    
    /// 设置初始数据
    private func setupInitialData() {
        recentQuestions = QuestionItem.mockData
    }
    
    /// 加载最近题目
    private func loadRecentQuestions() async -> [QuestionItem] {
        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8秒
        
        // TODO: 架构重构 - 通过Repository获取数据
        return QuestionItem.mockData
    }
    
    /// 处理相机拍照
    private func handleCameraCapture() {
        // TODO: 架构重构 - 调用CameraCaptureUseCase
        print("启动相机拍照")
    }
    
    /// 处理相册导入
    private func handlePhotoLibraryImport() {
        // TODO: 架构重构 - 调用PhotoImportUseCase
        print("从相册选择图片")
    }
    
    /// 处理文件导入
    private func handleFileImport() {
        // TODO: 架构重构 - 调用FileImportUseCase
        print("导入文件")
    }
    
    /// 处理手动输入
    private func handleManualInput() {
        // TODO: 架构重构 - 导航到手动输入页面
        print("手动输入题目")
    }
    
    /// 执行删除题目
    private func performDeleteQuestion(_ question: QuestionItem) async {
        // 模拟删除操作
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // TODO: 架构重构 - 调用Repository删除操作
    }
}

// MARK: - Data Models
// TODO: 架构重构 - 将这些模型迁移到Core/Domain/Entities/

/// 题目项目
struct QuestionItem: Identifiable {
    let id = UUID()
    let content: String
    let subject: String
    let topic: String
    let difficulty: QuestionDifficulty
    let type: QuestionType
    let tags: [String]
    let createdAt: Date
    let lastModified: Date
    let isCompleted: Bool
    let correctCount: Int
    let incorrectCount: Int
    let imageURL: String? // 题目图片
    
    /// 正确率
    var accuracy: Double {
        let total = correctCount + incorrectCount
        return total > 0 ? Double(correctCount) / Double(total) : 0.0
    }
    
    static let mockData: [QuestionItem] = [
        QuestionItem(
            content: "求函数 f(x) = x² + 2x - 3 的最值及对应的x值",
            subject: "数学",
            topic: "二次函数",
            difficulty: .medium,
            type: .multipleChoice,
            tags: ["函数", "最值", "二次函数"],
            createdAt: Date().addingTimeInterval(-120), // 2分钟前
            lastModified: Date().addingTimeInterval(-120),
            isCompleted: false,
            correctCount: 0,
            incorrectCount: 0,
            imageURL: nil
        ),
        QuestionItem(
            content: "The importance of environmental protection cannot be overstated. Complete the following sentence with the most appropriate phrase...",
            subject: "英语",
            topic: "阅读理解",
            difficulty: .easy,
            type: .fillInBlank,
            tags: ["阅读理解", "环保", "语法"],
            createdAt: Date().addingTimeInterval(-600), // 10分钟前
            lastModified: Date().addingTimeInterval(-300),
            isCompleted: true,
            correctCount: 2,
            incorrectCount: 1,
            imageURL: nil
        ),
        QuestionItem(
            content: "计算物体在斜面上的加速度，已知斜面角度θ=30°，物体质量m=2kg，摩擦系数μ=0.3",
            subject: "物理",
            topic: "牛顿定律",
            difficulty: .hard,
            type: .calculation,
            tags: ["力学", "加速度", "摩擦"],
            createdAt: Date().addingTimeInterval(-3600), // 1小时前
            lastModified: Date().addingTimeInterval(-1800),
            isCompleted: true,
            correctCount: 1,
            incorrectCount: 2,
            imageURL: nil
        ),
        QuestionItem(
            content: "写出乙酸与乙醇发生酯化反应的化学方程式，并说明反应条件",
            subject: "化学",
            topic: "有机化学",
            difficulty: .medium,
            type: .shortAnswer,
            tags: ["有机化学", "酯化反应", "方程式"],
            createdAt: Date().addingTimeInterval(-7200), // 2小时前
            lastModified: Date().addingTimeInterval(-3600),
            isCompleted: false,
            correctCount: 0,
            incorrectCount: 1,
            imageURL: nil
        ),
        QuestionItem(
            content: "分析鸦片战争对中国社会产生的深远影响，从政治、经济、社会三个方面论述",
            subject: "历史",
            topic: "近代史",
            difficulty: .hard,
            type: .essay,
            tags: ["近代史", "鸦片战争", "社会影响"],
            createdAt: Date().addingTimeInterval(-10800), // 3小时前
            lastModified: Date().addingTimeInterval(-5400),
            isCompleted: true,
            correctCount: 1,
            incorrectCount: 0,
            imageURL: nil
        )
    ]
}

/// 题目难度
/// TODO: 架构重构 - 迁移到Core/Domain/ValueObjects/DifficultyLevel.swift
enum QuestionDifficulty: String, CaseIterable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "1.circle.fill"
        case .medium: return "2.circle.fill"
        case .hard: return "3.circle.fill"
        }
    }
}

/// 题目类型
/// TODO: 架构重构 - 迁移到Core/Domain/ValueObjects/QuestionType.swift
enum QuestionType: String, CaseIterable {
    case multipleChoice = "选择题"
    case fillInBlank = "填空题"
    case shortAnswer = "简答题"
    case essay = "论述题"
    case calculation = "计算题"
    case trueOrFalse = "判断题"
    
    var icon: String {
        switch self {
        case .multipleChoice: return "checklist"
        case .fillInBlank: return "pencil.line"
        case .shortAnswer: return "text.alignleft"
        case .essay: return "doc.text"
        case .calculation: return "function"
        case .trueOrFalse: return "checkmark.circle"
        }
    }
}

/// 添加方式选项
struct AddMethodOption: Identifiable {
    let id = UUID()
    let type: AddMethodType
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    enum AddMethodType {
        case camera
        case photoLibrary
        case fileImport
        case manualInput
    }
    
    static let allMethods: [AddMethodOption] = [
        AddMethodOption(
            type: .camera,
            title: "拍照识别",
            subtitle: "使用相机拍摄题目，AI自动识别文字",
            icon: "camera.fill",
            color: .blue
        ),
        AddMethodOption(
            type: .photoLibrary,
            title: "相册导入",
            subtitle: "从相册中选择图片进行识别",
            icon: "photo.fill",
            color: .green
        ),
        AddMethodOption(
            type: .fileImport,
            title: "文件导入",
            subtitle: "导入PDF、Word等文档格式",
            icon: "doc.fill",
            color: .orange
        ),
        AddMethodOption(
            type: .manualInput,
            title: "手动输入",
            subtitle: "手动输入题目内容和答案",
            icon: "pencil",
            color: .purple
        )
    ]
}