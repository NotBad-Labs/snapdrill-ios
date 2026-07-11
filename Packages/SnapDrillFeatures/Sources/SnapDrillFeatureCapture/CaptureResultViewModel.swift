//
//  CaptureResultViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集结果预览与编辑的 ViewModel，直接通过 RepositoryContainer 保存题目内容与图片。
//  L3：分类改为动态维度（dimensions + selectedByDimension）。
//

import SwiftUI
import PhotosUI
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

/// 保存题目前置校验错误（typed throws 替代裸 NSError）
enum CaptureSaveError: LocalizedError {
    case contentAndImageEmpty
    var errorDescription: String? { L10n.Errors.contentAndImageEmpty }
}

/// 采集结果预览与编辑的 ViewModel
@Observable
public final class CaptureResultViewModel {

    // MARK: - Properties

    /// OCR 识别的题目文本（用户可编辑）
    public var content: String
    /// 题目截图（可为 `nil` 表示纯文字题）
    public var image: UIImage?

    // 动态维度（L3：取代固定分类/来源/级别/标签字段）
    /// 当前所有命名维度（按 sortOrder）
    public private(set) var dimensions: [CategoryDimensionModel] = []
    /// 每维度的可选值（dimensionId → values）
    public private(set) var valuesByDimension: [UUID: [CategoryValueModel]] = [:]
    /// 每维度的选中值（dimensionId → selected valueIds；单值维度 size<=1）
    public private(set) var selectedByDimension: [UUID: Set<UUID>] = [:]

    // 详情表单
    /// 答案文本
    public var answerText: String = ""
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
    /// 字段配置引导提示（由设备级 FeatureTipState 管理）
    public var showFieldConfigTip = false
    private let featureTipState = FeatureTipState()
    /// AI 标注是否正在进行
    public var isTagging = false

    // MARK: - Dependencies

    private let repositories: RepositoryContainer
    private let ocrService: OCRServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let imageStorage: ImageStorage
    private let router: CaptureRouter
    private let contentTaggingService: ContentTaggingServiceProtocol
    /// 草稿服务（S-D4-001 起从 ServiceContainer 注入，默认 .shared 兼容历史调用方）
    private let draftService: CaptureDraftServiceProtocol
    /// 活动追踪器（S-D4-001 起注入，避免静态单例污染测试）
    private let activityTracker: AppActivityTracker

    /// 识别任务句柄（@MainActor 隔离，由 View 的 onDisappear 通过 cancelTasks() 取消）
    @ObservationIgnored
    private var recognitionTask: Task<Void, Never>?
    @ObservationIgnored
    private var taggingTask: Task<Void, Never>?
    /// 相册图片加载任务句柄（连续切换图片时取消前一个，避免竞态）
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
    public init(
        content: String,
        image: UIImage?,
        repositories: RepositoryContainer,
        ocrService: OCRServiceProtocol,
        analyticsService: AnalyticsServiceProtocol,
        imageStorage: ImageStorage = ImageStorage(baseDirectory: FileManager.default.temporaryDirectory),
        contentTaggingService: ContentTaggingServiceProtocol = ContentTaggingService(),
        router: CaptureRouter,
        draftService: CaptureDraftServiceProtocol? = nil,
        activityTracker: AppActivityTracker? = nil
    ) {
        self.content = content
        self.image = image
        self.repositories = repositories
        self.ocrService = ocrService
        self.analyticsService = analyticsService
        self.imageStorage = imageStorage
        self.contentTaggingService = contentTaggingService
        self.router = router
        self.draftService = draftService ?? CaptureDraftService.shared
        self.activityTracker = activityTracker ?? AppActivityTracker.shared
    }

    // MARK: - Public API

    /// 取消进行中的异步任务（由 View 的 onDisappear 调用）
    public func cancelTasks() {
        recognitionTask?.cancel()
        recognitionTask = nil
        photoLoadTask?.cancel()
        photoLoadTask = nil
        saveTask?.cancel()
        saveTask = nil
        navigateTask?.cancel()
        navigateTask = nil
        taggingTask?.cancel()
        taggingTask = nil
    }

    /// 加载默认表单数据：拉取所有维度及其值，并触发 AI 标注
    public func loadFormData() {
        do {
            dimensions = try repositories.dimension.fetchAllModels()
            var values: [UUID: [CategoryValueModel]] = [:]
            for dim in dimensions {
                values[dim.id] = repositories.categoryValue.fetchAllModels(in: dim)
            }
            valuesByDimension = values
        } catch {
            SnapDrillLogger.generic.error("加载维度表单失败: \(error.localizedDescription)")
            errorMessage = L10n.Errors.formDataLoadFailed
            showErrorAlert = true
        }
        startAITagging()
    }

    /// AI 标注：有 OCR 文本时自动建议主分类维度的值（best-effort）
    private func startAITagging() {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        taggingTask?.cancel()
        taggingTask = Task {
            isTagging = true
            defer { isTagging = false }
            guard let suggestion = await contentTaggingService.suggestTags(for: content),
                  !Task.isCancelled else { return }
            applySuggestion(category: suggestion.category)
        }
    }

    /// 应用 AI 建议：category 命中主分类维度的同名值则选中（仅当该维度未选）。
    private func applySuggestion(category: String) {
        if let categoryDim = dimensions.first(where: { $0.systemKey == CategorySystemKey.category }),
           (selectedByDimension[categoryDim.id] ?? []).isEmpty,
           let value = (valuesByDimension[categoryDim.id] ?? []).first(where: { $0.name == category }) {
            selectedByDimension[categoryDim.id] = [value.id]
        }
    }

    // MARK: - 维度选择 / 新建（供 View 经 DimensionInputRow 驱动）

    /// 某维度是否在录入页可见（per-维度可见性；缺省走 defaultCaptureVisibility：
    /// 用户自建维度默认可见，内置维度默认隐藏；管理界面写入显式开关覆盖缺省）
    public func isDimensionVisible(_ dimension: CategoryDimensionModel) -> Bool {
        UserDefaults.standard.object(forKey: dimension.captureVisibilityKey) as? Bool ?? dimension.defaultCaptureVisibility
    }

    /// 映射成 UI 纯值模型（仅可见维度），供 DimensionInputRow 渲染
    public func visibleDimensionInputModels() -> [DimensionInputModel] {
        dimensions.filter { isDimensionVisible($0) }.map { dim in
            let options = (valuesByDimension[dim.id] ?? []).map { DimensionValueOption(id: $0.id, name: $0.name) }
            return DimensionInputModel(
                id: dim.id, title: dim.name, icon: dim.icon, isMultiValue: dim.isMultiValue, options: options
            )
        }
    }

    /// 某维度当前选中的值 id
    public func selectedIds(forDimension dimensionId: UUID) -> Set<UUID> {
        selectedByDimension[dimensionId] ?? []
    }

    /// 切换某维度的值选中：单值维度替换（再点取消），多值维度切换
    public func toggleValue(_ valueId: UUID, inDimension dimensionId: UUID) {
        guard let dim = dimensions.first(where: { $0.id == dimensionId }) else { return }
        var selected = selectedByDimension[dimensionId] ?? []
        if dim.isMultiValue {
            if selected.contains(valueId) { selected.remove(valueId) } else { selected.insert(valueId) }
        } else {
            selected = selected.contains(valueId) ? [] : [valueId]
        }
        selectedByDimension[dimensionId] = selected
    }

    /// 在某维度现场新建值并自动选中（纯内存 fetchOrCreate + save + 刷新该维度值）
    public func createValue(name: String, inDimension dimensionId: UUID) {
        guard let dim = dimensions.first(where: { $0.id == dimensionId }) else { return }
        do {
            let value = repositories.categoryValue.fetchOrCreate(name: name, in: dim)
            try repositories.categoryValue.saveContext()
            valuesByDimension[dimensionId] = repositories.categoryValue.fetchAllModels(in: dim)
            toggleValue(value.id, inDimension: dimensionId)
        } catch {
            SnapDrillLogger.generic.error("新建维度值失败: \(error.localizedDescription)")
            errorMessage = L10n.Errors.createTaxonomyFailed(name)
            showErrorAlert = true
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
        let hasContent = !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !isSaved, image != nil || hasContent {
            let categoryName = selectedName(forSystemKey: CategorySystemKey.category)
            await draftService.saveDraft(image: image, content: content, category: categoryName.isEmpty ? nil : categoryName)
        }
    }

    /// 触发草稿保存并存储 Task 句柄（由 View 的 onDisappear 调用）
    public func saveDraftOnDisappear() {
        draftSaveTask = Task {
            await generateDraftIfNeeded()
        }
    }

    /// 触发保存并存储 Task 句柄（由 View 调用，替代裸 Task 包裹）
    public func save() {
        guard !isSaving else { return }
        isSaving = true
        saveTask = Task {
            defer { self.isSaving = false }
            await saveResult()
        }
    }

    /// 保存正式题目（事务委托给无状态 CaptureSaveCoordinator）
    public func saveResult() async {
        activityTracker.begin(.capturing)
        defer { activityTracker.end(.capturing) }

        let coordinator = CaptureSaveCoordinator(repositories: repositories, imageStorage: imageStorage)
        let form = CaptureFormSnapshot(
            content: content,
            image: image,
            selectedValues: selectedValues,
            answerText: answerText,
            answerImage: answerImage
        )
        do {
            try await coordinator.save(form)
            handleSaveSuccess()
        } catch {
            SnapDrillLogger.generic.error("保存失败: \(error.localizedDescription)")
            self.errorMessage = L10n.Errors.saveFailed
            self.showErrorAlert = true
        }
    }

    /// 关闭字段配置引导提示，然后触发导航
    public func dismissFieldConfigTip() {
        showFieldConfigTip = false
        featureTipState.markFieldConfigSeen()
        navigateAfterSave()
    }

    // MARK: - Private Helpers

    /// 当前所有维度的选中值实例（扁平），供保存写入 ArchiveItemModel.categoryValues
    private var selectedValues: [CategoryValueModel] {
        var result: [CategoryValueModel] = []
        for (dimId, valueIds) in selectedByDimension {
            let values = valuesByDimension[dimId] ?? []
            result.append(contentsOf: values.filter { valueIds.contains($0.id) })
        }
        // 丢弃已被管理页删除的值——本页缓存可能持有它处已删的 @Model，写回会复活值或造成悬挂引用
        return result.filter { !$0.isDeleted }
    }

    /// 取某内置维度（按 systemKey）当前选中的首个值名（埋点/草稿用，无则空串）
    private func selectedName(forSystemKey key: String) -> String {
        guard let dim = dimensions.first(where: { $0.systemKey == key }),
              let valueId = selectedByDimension[dim.id]?.first,
              let value = (valuesByDimension[dim.id] ?? []).first(where: { $0.id == valueId })
        else { return "" }
        return value.name
    }

    /// 保存成功后的善后：通知、埋点、引导检查
    private func handleSaveSuccess() {
        isSaved = true
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)

        analyticsService.track(.captureSaved, parameters: [
            "category": selectedName(forSystemKey: CategorySystemKey.category),
            "source": selectedName(forSystemKey: CategorySystemKey.source)
        ])
        analyticsService.track(.reviewItemCreated, parameters: [
            "has_image": image != nil ? "true" : "false",
            "has_content": !content.isEmpty ? "true" : "false"
        ])

        if featureTipState.showFieldConfigTip {
            showFieldConfigTip = true
        } else {
            navigateAfterSave()
        }
    }

    /// 保存成功后的导航：短暂延迟让触觉反馈生效，再执行退栈
    private func navigateAfterSave() {
        draftService.clearDraft()
        navigateTask = Task {
            try? await Task.sleep(for: .milliseconds(300)) // best-effort: 取消即导航，延迟中断不影响正确性
            guard !Task.isCancelled else { return }
            router.popAfterSave(isUITesting: ProcessInfo.processInfo.arguments.contains("--uitesting"))
        }
    }

    private func processSelectedPhoto() {
        guard let item = answerPhotoItem else { return }
        photoLoadTask?.cancel()
        photoLoadTask = Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let loadedImage = UIImage(data: data) {
                    guard !Task.isCancelled else { return }
                    self.answerImage = loadedImage
                } else {
                    // 加载或解码失败但未抛错（loadTransferable 返回 nil / UIImage 解码失败）
                    guard !Task.isCancelled else { return }
                    self.errorMessage = L10n.Errors.imageDecodeFailed
                    self.showErrorAlert = true
                }
            } catch is CancellationError {
                SnapDrillLogger.generic.info("答案图加载任务已取消。")
            } catch {
                SnapDrillLogger.generic.error("加载图片失败: \(error.localizedDescription)")
                self.errorMessage = L10n.Errors.imageLoadFailed
                self.showErrorAlert = true
            }
        }
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
