//
//  CaptureViewModel.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import PhotosUI
import SwiftData

// MARK: - CaptureViewModel

/// 错题录入 ViewModel
///
/// 负责管理错题录入的完整流程，包括图片选择、OCR 识别、表单填写和保存。
///
/// ## 录入流程
///
/// 1. **选择图片**：从相册选择或拍照
/// 2. **OCR 识别**：自动识别图片中的文字
/// 3. **填写表单**：标题、学科、知识点等
/// 4. **保存**：存入 SwiftData
///
/// ## 使用示例
///
/// ```swift
/// struct CaptureView: View {
///     @State private var viewModel = CaptureViewModel()
///
///     var body: some View {
///         PhotosPicker(selection: $viewModel.selectedItem) {
///             Text("选择图片")
///         }
///         .onChange(of: viewModel.selectedItem) { _, newValue in
///             Task {
///                 await viewModel.loadTransferable(from: newValue)
///             }
///         }
///     }
/// }
/// ```
@MainActor
@Observable
final class CaptureViewModel {

    // MARK: - Image State

    /// 选中的图片项（PhotosPicker）
    var selectedItem: PhotosPickerItem?

    /// 显示用的 SwiftUI Image
    var selectedImage: Image?

    /// 图片数据（用于存储）
    var selectedImageData: Data?

    /// UIImage（用于 OCR）
    var selectedUIImage: UIImage?

    /// 是否已选择图片
    var hasImage: Bool {
        selectedImageData != nil
    }

    // MARK: - Form State

    /// 标题
    var title: String = ""

    /// 笔记/备注
    var note: String = ""

    /// 学科
    var subject: Subject = .math

    /// 年级（从用户设置读取默认值）
    var grade: Grade = CaptureViewModel.getUserDefaultGrade()

    /// 获取用户在 Onboarding 中选择的年级
    private static func getUserDefaultGrade() -> Grade {
        guard let savedGrade = UserDefaults.standard.string(forKey: "user_current_grade"),
              let grade = Grade(rawValue: savedGrade) else {
            return .grade7  // 默认初一
        }
        return grade
    }

    /// 知识点输入（逗号分隔）
    var knowledgePointsInput: String = ""

    /// 难度
    var difficulty: Difficulty = .medium

    /// 错误类型
    var errorType: ErrorType = .other

    /// 来源
    var source: Source = .other

    /// 题型
    var questionType: ReviewItemType = .other

    // MARK: - UI State

    /// 当前步骤
    var currentStep: CaptureStep = .selectImage

    /// 是否正在保存
    var isSaving = false

    /// 是否正在识别文字
    var isRecognizingText = false

    /// 是否显示提示框
    var showAlert = false

    /// 提示信息
    var alertMessage = ""

    /// 提示类型
    var alertType: AlertType = .info

    /// 是否为成功提示（用于判断是否重置表单）
    var isSuccessAlert = false

    /// 是否显示相机
    var showCamera = false

    /// 是否显示实时扫描
    var showLiveScanner = false

    /// 是否显示图片选择器
    var showPhotoPicker = false

    // MARK: - OCR State

    /// OCR 识别结果
    var recognizedText: String = ""

    /// OCR 置信度
    var ocrConfidence: Double = 0

    // MARK: - Dependencies

    private let ocrService: OCRService
    private var modelContext: ModelContext?

    // MARK: - Initialization

    /// 创建 ViewModel
    ///
    /// - Parameter ocrService: OCR 服务，默认使用共享实例
    init(ocrService: OCRService = .shared) {
        self.ocrService = ocrService
    }

    /// 配置 ModelContext
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Validation

    /// 是否来自实时扫描（无图片模式）
    var isFromLiveScanner: Bool {
        !recognizedText.isEmpty && selectedImageData == nil
    }

    /// 表单是否有效
    /// - Note: 实时扫描模式允许无图片保存
    var isValid: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasTitle && (hasImage || isFromLiveScanner)
    }

    /// 验证结果
    var validationErrors: [String] {
        var errors: [String] = []

        if !hasImage && !isFromLiveScanner {
            errors.append(String(localized: "capture_validation_no_image"))
        }

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(String(localized: "capture_validation_no_title"))
        }

        return errors
    }

    /// 是否可以进入下一步
    var canProceed: Bool {
        switch currentStep {
        case .selectImage:
            return hasImage
        case .recognize:
            return true
        case .fillForm:
            return isValid
        case .review:
            return isValid
        }
    }

    // MARK: - Image Actions

    /// 处理选中的图片
    ///
    /// - Parameter image: 选中的 UIImage
    func handlePickedImage(_ image: UIImage) {
        selectedUIImage = image
        selectedImage = Image(uiImage: image)

        // 使用 ImageCompressor 压缩图片
        selectedImageData = ImageCompressor.compress(image)

        // 更新步骤
        currentStep = .recognize

        // 自动触发 OCR
        if title.isEmpty {
            Task {
                await recognizeText()
            }
        }
    }

    /// 从 PhotosPicker 加载图片
    func loadTransferable(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }

        handlePickedImage(uiImage)
    }

    /// 清除已选图片
    func clearImage() {
        selectedItem = nil
        selectedImage = nil
        selectedImageData = nil
        selectedUIImage = nil
        currentStep = .selectImage
    }

    // MARK: - OCR Actions

    /// 识别图片中的文字
    func recognizeText() async {
        guard let image = selectedUIImage else { return }

        isRecognizingText = true

        do {
            let result = try await ocrService.recognizeText(from: image)
            recognizedText = result

            // 提取标题
            let extractedTitle = ocrService.extractTitle(from: result)
            if title.isEmpty {
                title = extractedTitle
            }

            // 填充笔记
            if note.isEmpty {
                note = result
            }

            isRecognizingText = false
            currentStep = .fillForm

            showSuccessAlert(String(localized: "capture_ocr_success"))
        } catch {
            isRecognizingText = false
            currentStep = .fillForm

            showWarningAlert(String(format: String(localized: "capture_ocr_failure"), error.localizedDescription))
        }
    }

    /// 重新识别
    func retryRecognition() async {
        recognizedText = ""
        title = ""
        note = ""
        await recognizeText()
    }

    // MARK: - Form Actions

    /// 处理实时扫描结果
    func handleLiveScanResult(_ text: String, imageData: Data?) {
        #if DEBUG
        print("🔍 [CaptureVM] handleLiveScanResult: text长度=\(text.count), 图片=\(imageData?.count ?? 0) bytes")
        #endif
        recognizedText = text
        
        // 保存截图
        if let imageData = imageData {
            selectedImageData = imageData
            if let uiImage = UIImage(data: imageData) {
                selectedImage = Image(uiImage: uiImage)
                selectedUIImage = uiImage
            }
        }

        let firstLine = text.components(separatedBy: .newlines).first ?? text
        if title.isEmpty {
            title = String(firstLine.prefix(50))
        }

        if note.isEmpty {
            note = text
        }

        currentStep = .fillForm

        #if DEBUG
        print("🔍 [CaptureVM] 处理结果: title=\(title), hasImage=\(hasImage), isValid=\(isValid)")
        #endif
    }

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

    // MARK: - Save Actions

    /// 进入预览步骤
    func proceedToReview() {
        guard isValid else { return }
        currentStep = .review
    }

    /// 保存错题
    func saveItem() {
        guard let modelContext else {
            #if DEBUG
            print("❌ [CaptureVM] 保存失败：modelContext 为 nil")
            #endif
            showErrorAlert(String(localized: "capture_save_error_context"))
            return
        }

        // 验证：必须有图片或来自实时扫描
        guard hasImage || isFromLiveScanner else {
            #if DEBUG
            print("❌ [CaptureVM] 保存失败：无图片且非实时扫描")
            #endif
            showErrorAlert(String(localized: "capture_save_error_no_image"))
            return
        }

        isSaving = true

        let newItem = ReviewItem(
            imageData: selectedImageData,  // 可为 nil（实时扫描模式）
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note,
            subject: subject,
            grade: grade,
            knowledgePoints: KnowledgePoints(from: knowledgePointsInput),
            difficulty: difficulty,
            errorType: errorType,
            source: source,
            questionType: questionType
        )

        #if DEBUG
        print("📝 [CaptureVM] 创建 ReviewItem: id=\(newItem.id), title=\(newItem.title)")
        #endif

        modelContext.insert(newItem)
        #if DEBUG
        print("📝 [CaptureVM] insert 完成")
        #endif

        do {
            try modelContext.save()
            #if DEBUG
            print("✅ [CaptureVM] save 成功")
            #endif

            // 触觉反馈 - 成功
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // 延迟显示成功提示，改善体验
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.isSaving = false
                self?.showSuccessAlert(String(localized: "capture_save_success"))

                // 发送通知
                NotificationCenter.default.post(name: .reviewItemAdded, object: newItem)
            }
        } catch {
            #if DEBUG
            print("❌ [CaptureVM] save 失败: \(error)")
            #endif

            // 触觉反馈 - 失败
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

            isSaving = false
            showErrorAlert(String(format: String(localized: "capture_save_error_generic"), error.localizedDescription))
        }
    }

    /// 保存并继续录入下一题
    func saveAndContinue() {
        saveItem()

        // 保存成功后重置（保留学科和年级）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.resetForm(keepSubjectAndGrade: true)
        }
    }

    /// 重置表单
    ///
    /// - Parameter keepSubjectAndGrade: 是否保留学科和年级设置
    func resetForm(keepSubjectAndGrade: Bool = false) {
        selectedItem = nil
        selectedImage = nil
        selectedImageData = nil
        selectedUIImage = nil
        title = ""
        note = ""
        knowledgePointsInput = ""
        recognizedText = ""
        currentStep = .selectImage

        if !keepSubjectAndGrade {
            subject = .math
            grade = CaptureViewModel.getUserDefaultGrade()
        }

        difficulty = .medium
        errorType = .other
        source = .other
        questionType = .other
    }

    // MARK: - Alert Helpers

    private func showSuccessAlert(_ message: String) {
        alertType = .success
        alertMessage = message
        isSuccessAlert = true
        showAlert = true
    }

    private func showWarningAlert(_ message: String) {
        alertType = .warning
        alertMessage = message
        isSuccessAlert = false
        showAlert = true
    }

    private func showErrorAlert(_ message: String) {
        alertType = .error
        alertMessage = message
        isSuccessAlert = false
        showAlert = true
    }

    /// 显示验证错误
    func showValidationError() {
        let errors = validationErrors
        if !errors.isEmpty {
            showWarningAlert(errors.joined(separator: "\n"))
        }
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
