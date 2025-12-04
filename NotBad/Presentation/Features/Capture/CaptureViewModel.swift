//
//  CaptureViewModel.swift
//  NotBad
//
//  Created by LIAOYIMING on 2025/6/5.
//  Phase 3: ViewModel Dependency Injection
//

import Foundation
import Observation
import PhotosUI
import SwiftData
import SwiftUI

// MARK: - CaptureViewModel

/// 错题录入视图模型
///
/// 负责处理图片选择、OCR 识别、表单管理和保存操作
/// 使用 Swift 6 的 @Observable 宏实现响应式更新
///
/// ## 依赖注入
///
/// 支持注入 DataProvider 用于测试：
///
/// ```swift
/// // 生产环境
/// let viewModel = CaptureViewModel()
/// viewModel.configure(with: modelContext)
///
/// // 测试环境
/// let mockProvider = MockReviewItemProvider()
/// let viewModel = CaptureViewModel(dataProvider: mockProvider)
/// ```
@MainActor
@Observable
final class CaptureViewModel {
    // MARK: - Image State

    var selectedItem: PhotosPickerItem?
    var selectedImage: Image?
    var selectedImageData: Data?
    var selectedUIImage: UIImage?
    
    /// 图片正在压缩处理中（后台线程执行 JPEG 压缩）
    var isProcessingImage: Bool = false

    // MARK: - Form State

    var title: String = ""
    var note: String = ""
    var subject: Subject = .math
    var grade: Grade = getUserDefaultGrade()
    var knowledgePointsInput: String = ""
    var difficulty: Difficulty = .medium
    var errorType: ErrorType = .other
    var source: Source = .other
    var questionType: ReviewItemType = .other

    // MARK: - UI State

    var currentStep: CaptureStep = .selectImage
    var showAlert: Bool = false
    var alertMessage: String = ""
    var alertType: AlertType = .success
    var isSuccessAlert: Bool = false
    var showCamera: Bool = false
    var showLiveScanner: Bool = false
    var showPhotoPicker: Bool = false

    // MARK: - OCR State

    var isRecognizingText: Bool = false
    var recognizedText: String = ""

    // MARK: - Smart Analysis State
    
    var isAnalyzing: Bool = false
    var smartAnalysisAvailable: Bool = false
    var suggestedSubject: Subject?
    var subjectWasAutoSelected: Bool = false

    // MARK: - Save State

    var isSaving: Bool = false

    // MARK: - Scanner Mode

    var isFromLiveScanner: Bool = false

    // MARK: - Dependencies

    /// 数据提供者（可选，用于依赖注入）
    private var dataProvider: (any ReviewItemDataProviding)?

    var modelContext: ModelContext?
    let ocrService = OCRService.shared
    let smartAnalysisService = SmartAnalysisService.shared

    // MARK: - Initialization

    /// 默认初始化
    init() {
        // 检查智能分析是否可用
        smartAnalysisAvailable = smartAnalysisService.isAvailable
    }

    /// 依赖注入初始化（推荐用于测试）
    ///
    /// - Parameter dataProvider: 数据提供者
    init(dataProvider: any ReviewItemDataProviding) {
        self.dataProvider = dataProvider
        smartAnalysisAvailable = smartAnalysisService.isAvailable
    }

    /// 配置 ModelContext
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Grade Default

    static func getUserDefaultGrade() -> Grade {
        let gradeCode = UserDefaults.standard.string(forKey: "defaultGrade") ?? Grade.grade7.rawValue
        return Grade(rawValue: gradeCode) ?? .grade7
    }
}

// MARK: - Computed Properties

extension CaptureViewModel {
    /// 是否已选择图片
    var hasImage: Bool {
        selectedImageData != nil
    }

    /// 表单是否有效
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            (hasImage || isFromLiveScanner)
    }

    /// 验证错误列表
    var validationErrors: [String] {
        var errors: [String] = []

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(String(localized: "capture_validation_title_required"))
        }

        if !hasImage && !isFromLiveScanner {
            errors.append(String(localized: "capture_validation_image_required"))
        }

        return errors
    }

    /// 当前步骤是否可继续
    var canProceed: Bool {
        switch currentStep {
        case .selectImage:
            return hasImage
        case .recognize:
            return !isRecognizingText
        case .fillForm:
            return isValid
        case .review:
            return isValid
        }
    }
}

// MARK: - Form Actions

extension CaptureViewModel {
    /// 添加知识点
    func addKnowledgePoint(_ point: String) {
        let trimmed = point.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if knowledgePointsInput.isEmpty {
            knowledgePointsInput = trimmed
        } else {
            knowledgePointsInput += ", \(trimmed)"
        }
    }

    /// 解析的知识点列表
    var parsedKnowledgePoints: [String] {
        KnowledgePoints(from: knowledgePointsInput).items
    }
}

// MARK: - CaptureStep

/// 录入步骤
enum CaptureStep: Int, CaseIterable, Identifiable {
    case selectImage = 0
    case recognize = 1
    case fillForm = 2
    case review = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .selectImage: String(localized: "capture_step_select_image")
        case .recognize: String(localized: "capture_step_recognize")
        case .fillForm: String(localized: "capture_step_fill_form")
        case .review: String(localized: "capture_step_review")
        }
    }

    var icon: String {
        switch self {
        case .selectImage: "photo"
        case .recognize: "text.viewfinder"
        case .fillForm: "square.and.pencil"
        case .review: "checkmark.circle"
        }
    }
}

// MARK: - AlertType

/// 提示类型
enum AlertType: Sendable {
    case success
    case warning
    case error
    case info

    var icon: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: .green
        case .warning: .orange
        case .error: .red
        case .info: .blue
        }
    }
}
