//
//  CaptureResultViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集结果预览与编辑的 ViewModel，直接通过 RepositoryContainer 保存题目内容与图片。
//

import SwiftUI
import PhotosUI
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

/// 采集结果预览与编辑的 ViewModel
@Observable
public final class CaptureResultViewModel {

    // MARK: - Properties

    /// OCR 识别的题目文本（用户可编辑）
    public var content: String
    /// 题目截图（可为 `nil` 表示纯文字题）
    public var image: UIImage?

    // 分类信息（自动推断：沿用上次录入的学科/来源，减少重复操作）
    /// 当前选中的学科名称
    public var selectedSubject: String = UserDefaults.standard.string(forKey: UDKey.lastSelectedSubject) ?? L10n.Capture.defaultSubject
    /// 当前选中的来源名称
    public var selectedSource: String = UserDefaults.standard.string(forKey: UDKey.lastSelectedSource) ?? L10n.Capture.defaultSource
    /// 标签列表（字符串形式）
    public var tagList: [String] = []
    /// 标签输入框当前文本
    public var tagInputText: String = ""

    // 详情表单
    /// 答案文本
    public var answerText: String = ""
    /// 题目难度
    public var difficulty: Difficulty = .one
    /// 年级
    public var grade: String = ""
    /// 答案图片（可为 `nil`）
    public var answerImage: UIImage?

    // 相册选择器状态
    /// 用户从相册选择的答案图片项（变更时自动触发图片加载）
    public var answerPhotoItem: PhotosPickerItem? {
        didSet {
            processSelectedPhoto()
        }
    }

    // UI 状态
    /// 是否正在重新识别 OCR
    public var isRecognizing = false
    /// 是否正在显示图片裁剪界面
    public var isCropping = false
    /// 是否已成功保存（用于触发返回导航）
    public var isSaved = false
    /// 复制文本到剪贴板的计数器（每次递增触发 sensoryFeedback，Bool 只能触发一次）
    public var copyConfirmationCount = 0
    /// 是否正在执行保存操作（防止双击重复写入）
    public var isSaving = false
    /// 是否弹出错误提示
    public var showErrorAlert = false
    /// 错误提示文本
    public var errorMessage: String?
    /// 字段配置引导提示（per-profile 隔离，由 ProfileTipState 管理）
    public var showFieldConfigTip = false
    private let profileTipState = ProfileTipState()

    // 新建分类 Alert 状态
    /// 是否显示新建学科 Alert
    public var showNewSubjectAlert = false
    /// 新建学科输入文本
    public var newSubjectName = ""
    /// 是否显示新建来源 Alert
    public var showNewSourceAlert = false
    /// 新建来源输入文本
    public var newSourceName = ""
    /// 是否显示新建年级 Alert
    public var showNewGradeAlert = false
    /// 新建年级输入文本
    public var newGradeName = ""

    // 下拉表单数据（@Model 类型）
    /// 可选学科列表
    public private(set) var availableSubjects: [SubjectModel] = []
    /// 可选来源列表
    public private(set) var availableSources: [SourceModel] = []
    /// 可选年级列表
    public private(set) var availableGrades: [GradeModel] = []
    /// 可选标签列表
    public private(set) var availableTags: [TagModel] = []

    // MARK: - Dependencies

    private let repositories: RepositoryContainer
    private let ocrService: OCRServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let imageStorage: ImageStorage
    private let router: CaptureRouter

    /// 识别任务句柄（@MainActor 隔离，由 View 的 onDisappear 通过 cancelTasks() 取消）
    /// @ObservationIgnored：Task 不是 UI 状态，不应触发 Observation 追踪
    @ObservationIgnored
    private var recognitionTask: Task<Void, Never>?
    /// 相册图片加载任务句柄（连续切换图片时取消前一个，避免竞态）
    /// @ObservationIgnored：Task 不是 UI 状态，不应触发 Observation 追踪
    @ObservationIgnored
    private var photoLoadTask: Task<Void, Never>?
    /// 保存任务句柄（页面退出时可取消，避免状态不一致）
    @ObservationIgnored
    private var saveTask: Task<Void, Never>?
    /// 草稿保存任务句柄（onDisappear 触发，best-effort）
    @ObservationIgnored
    private var draftSaveTask: Task<Void, Never>?
    /// 导航延迟任务句柄（保存成功后等待触觉反馈）
    @ObservationIgnored
    private var navigateTask: Task<Void, Never>?

    // MARK: - Initialization

    /// 创建采集结果 ViewModel
    /// - Parameters:
    ///   - content: OCR 识别的初始文本
    ///   - image: 拍摄图片（纯文字题为 `nil`）
    ///   - repositories: 仓库容器（用于读取分类选项并保存题目）
    ///   - ocrService: OCR 识别服务
    ///   - analyticsService: 分析服务
    ///   - imageStorage: 图片存储服务，默认使用 `ImageStorage()`
    ///   - router: 采集流程路由器
    public init(
        content: String,
        image: UIImage?,
        repositories: RepositoryContainer,
        ocrService: OCRServiceProtocol,
        analyticsService: AnalyticsServiceProtocol,
        imageStorage: ImageStorage = ImageStorage(),
        router: CaptureRouter
    ) {
        self.content = content
        self.image = image
        self.repositories = repositories
        self.ocrService = ocrService
        self.analyticsService = analyticsService
        self.imageStorage = imageStorage
        self.router = router
    }

    // MARK: - Public API

    /// 取消进行中的异步任务（由 View 的 onDisappear 调用）
    ///
    /// 不取消 `draftSaveTask`：草稿保存是 best-effort 操作，
    /// 即使页面消失也应允许其完成，否则用户的编辑内容会丢失。
    public func cancelTasks() {
        recognitionTask?.cancel()
        recognitionTask = nil
        photoLoadTask?.cancel()
        photoLoadTask = nil
        saveTask?.cancel()
        saveTask = nil
        navigateTask?.cancel()
        navigateTask = nil
    }

    /// 加载默认表单数据
    public func loadFormData() {
        do {
            availableSubjects = try repositories.subject.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
            availableSources = try repositories.source.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
            availableGrades = try repositories.grade.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
            availableTags = try repositories.tag.fetchAllModels().sorted(by: { $0.name < $1.name })
        } catch {
            SnapDrillLogger.generic.error("加载下拉表单失败: \(error.localizedDescription)")
            errorMessage = L10n.Errors.formDataLoadFailed
            showErrorAlert = true
        }
    }

    /// 创建新学科并选中
    public func confirmNewSubject() {
        let trimmed = newSubjectName.trimmingCharacters(in: .whitespaces)
        newSubjectName = ""
        guard !trimmed.isEmpty else { return }
        do {
            let model = SubjectModel(name: trimmed, icon: "book", colorHex: "#808080", sortOrder: availableSubjects.count)
            try repositories.subject.insertAndSave(model)
            availableSubjects = try repositories.subject.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
            selectedSubject = trimmed
        } catch {
            SnapDrillLogger.generic.error("新建学科失败: \(error.localizedDescription)")
            self.errorMessage = L10n.Errors.createTaxonomyFailed(trimmed)
            self.showErrorAlert = true
        }
    }

    /// 创建新来源并选中
    public func confirmNewSource() {
        let trimmed = newSourceName.trimmingCharacters(in: .whitespaces)
        newSourceName = ""
        guard !trimmed.isEmpty else { return }
        do {
            let model = SourceModel(name: trimmed)
            try repositories.source.insertAndSave(model)
            availableSources = try repositories.source.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
            selectedSource = trimmed
        } catch {
            SnapDrillLogger.generic.error("新建来源失败: \(error.localizedDescription)")
            self.errorMessage = L10n.Errors.createTaxonomyFailed(trimmed)
            self.showErrorAlert = true
        }
    }

    /// 创建新年级并选中
    public func confirmNewGrade() {
        let trimmed = newGradeName.trimmingCharacters(in: .whitespaces)
        newGradeName = ""
        guard !trimmed.isEmpty else { return }
        do {
            let model = GradeModel(name: trimmed)
            try repositories.grade.insertAndSave(model)
            availableGrades = try repositories.grade.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
            grade = trimmed
        } catch {
            SnapDrillLogger.generic.error("新建年级失败: \(error.localizedDescription)")
            self.errorMessage = L10n.Errors.createTaxonomyFailed(trimmed)
            self.showErrorAlert = true
        }
    }

    /// 处理裁切结果
    public func handleImageCrop(_ croppedImage: UIImage) {
        self.image = croppedImage
        self.isCropping = false

        recognitionTask?.cancel()
        recognitionTask = Task {
            await reRecognizeText(from: croppedImage)
        }
    }

    /// 取消裁切
    public func cancelCrop() {
        self.isCropping = false
    }

    /// 保存预览草稿（async，文件 I/O 在后台执行；测试可直接 await）
    public func generateDraftIfNeeded() async {
        // 有图片或有文字内容时都保存草稿，防止意外退出时内容丢失
        let hasContent = !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !isSaved, image != nil || hasContent {
            await CaptureDraftService.shared.saveDraft(image: image, content: content, subject: selectedSubject)
        }
    }

    /// 触发草稿保存并存储 Task 句柄（由 View 的 onDisappear 调用）
    public func saveDraftOnDisappear() {
        draftSaveTask = Task {
            await generateDraftIfNeeded()
        }
    }

    /// 触发保存并存储 Task 句柄（由 View 调用，替代裸 Task 包裹）
    ///
    /// 使用 `isSaving` 布尔锁而非 `Task.cancel()` 防双击：
    /// `saveResult()` 内部无 `checkCancellation()` 检查点，cancel 无法实际阻止旧任务执行。
    public func save() {
        guard !isSaving else { return }
        isSaving = true
        saveTask = Task {
            defer { self.isSaving = false }
            await saveResult()
        }
    }

    /// 保存正式题目
    public func saveResult() async {
        AppActivityTracker.shared.begin(.capturing)
        defer { AppActivityTracker.shared.end(.capturing) }

        // 声明在 do 块外，确保 catch 中可访问以清理孤儿文件
        var savedImagePath: String?
        var savedAnswerImagePath: String?

        do {
            // 业务规则：题目文字和图片至少有一个
            let contentValue = content.isEmpty ? nil : content
            guard contentValue != nil || image != nil else {
                throw NSError(
                    domain: "SnapDrill",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: L10n.Errors.contentAndImageEmpty]
                )
            }

            // 解析并同步标签（纯内存操作，fetchOrCreateModel 不再内部 save）
            var finalTagModels: [TagModel] = []
            for name in tagList {
                let tagModel = try repositories.tag.fetchOrCreateModel(name: name, colorHex: "#CCCCCC")
                finalTagModels.append(tagModel)
            }

            // 持久化题目截图，获取本地相对路径
            if let img = image {
                savedImagePath = try await imageStorage.saveImage(img)
            }

            // 持久化答案图片
            if let answerImg = answerImage {
                savedAnswerImagePath = try await imageStorage.saveImage(answerImg)
            }

            // 构造 @Model 对象并插入（纯内存），再统一 saveContext
            let model = ReviewItemModel(
                content: contentValue,
                imagePath: savedImagePath,
                subject: selectedSubject,
                source: selectedSource,
                tags: finalTagModels,
                answerText: answerText.isEmpty ? nil : answerText,
                answerImagePath: savedAnswerImagePath,
                difficulty: difficulty.rawValue,
                grade: grade
            )
            repositories.review.insert(model)
            try repositories.review.saveContext()

            handleSaveSuccess()

        } catch {
            // 回滚 mainContext：清除本次操作插入的脏 Tag 和脏 ReviewItemModel。
            // 单用户本地优先架构下，saveResult 执行期间 mainContext 不存在其他并发未保存变更，
            // rollback 影响范围仅限本次调用，不会丢失其他模块的数据。
            repositories.review.rollbackContext()
            await cleanupOrphanImages(imagePath: savedImagePath, answerImagePath: savedAnswerImagePath)
            SnapDrillLogger.generic.error("保存失败: \(error.localizedDescription)")
            self.errorMessage = L10n.Errors.saveFailed
            self.showErrorAlert = true
        }
    }

    // MARK: - Private Helpers

    /// 保存成功后的善后：通知、推断持久化、埋点、引导检查
    private func handleSaveSuccess() {
        isSaved = true
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)

        // 自动推断：持久化本次选择，下次录入时自动填充
        UserDefaults.standard.set(selectedSubject, forKey: UDKey.lastSelectedSubject)
        UserDefaults.standard.set(selectedSource, forKey: UDKey.lastSelectedSource)

        // 埋点
        analyticsService.track(.captureSaved, parameters: [
            "subject": selectedSubject,
            "source": selectedSource,
            "difficulty": String(difficulty.rawValue)
        ])
        analyticsService.track(.reviewItemCreated, parameters: [
            "has_image": image != nil ? "true" : "false",
            "has_content": !content.isEmpty ? "true" : "false"
        ])

        // Profile 级字段配置引导：首次保存后提示，展示期间暂缓导航
        if profileTipState.showFieldConfigTip {
            showFieldConfigTip = true
            // 导航在 dismissFieldConfigTip() 中触发
        } else {
            navigateAfterSave()
        }
    }

    /// 保存成功后的导航：短暂延迟让触觉反馈生效，再执行退栈
    private func navigateAfterSave() {
        CaptureDraftService.shared.clearDraft()

        // 延迟 0.3s 让触觉反馈生效，用户可感知保存成功
        navigateTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            performNavigation()
        }
    }

    /// 执行实际的退栈导航
    private func performNavigation() {
        // 连续裁剪模式：同步设置标志（供 CaptureView 的 path onChange 判断是否保留原图），
        // 退栈后延迟触发裁剪器弹出，避免退栈动画与 fullScreenCover 在同帧竞争
        if router.originalAlbumImage != nil {
            router.shouldContinuousCrop = true
            if !router.path.isEmpty {
                router.path.removeLast()
            }
        } else if router.pdfDocument != nil || router.scannedPages != nil {
            // PDF / 文档扫描模式：仅退栈，回到页面选择器（让用户继续选下一页）
            if !router.path.isEmpty {
                router.path.removeLast()
            }
        } else {
            // 拍照/手动/粘贴板模式：退栈并重新打开摄像头
            if !router.path.isEmpty {
                router.path.removeLast()
            }
            router.shouldReopenScanner = true
        }
    }

    /// 清理保存失败时已写入磁盘的孤儿图片文件（best-effort，async 避免阻塞主线程）
    private func cleanupOrphanImages(imagePath: String?, answerImagePath: String?) async {
        if let path = imagePath {
            try? await imageStorage.deleteImage(path: path)
        }
        if let path = answerImagePath {
            try? await imageStorage.deleteImage(path: path)
        }
    }

    private func processSelectedPhoto() {
        guard let item = answerPhotoItem else { return }
        photoLoadTask?.cancel()
        photoLoadTask = Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let loadedImage = UIImage(data: data) {
                    self.answerImage = loadedImage
                }
            } catch {
                SnapDrillLogger.generic.error("加载图片失败: \(error.localizedDescription)")
            }
        }
    }

    /// 关闭字段配置引导提示，然后触发导航
    public func dismissFieldConfigTip() {
        showFieldConfigTip = false
        profileTipState.markFieldConfigSeen()
        navigateAfterSave()
    }

    private func reRecognizeText(from img: UIImage) async {
        isRecognizing = true
        defer { isRecognizing = false }

        do {
            guard let cgImage = img.cgImage else { return }
            try Task.checkCancellation()
            let newText = try await ocrService.recognizeText(from: cgImage)
            try Task.checkCancellation()
            self.content = newText
        } catch {
            SnapDrillLogger.generic.warning("重新识别失败: \(error.localizedDescription)")
        }
    }
}
