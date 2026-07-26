//
//  LibraryEditViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  题目编辑 ViewModel，直接操作 ArchiveItemModel 进行持久化。
//  L3：分类改为动态维度（dimensions + selectedByDimension）。
//

import SwiftUI
import PhotosUI
import SnapDrillData
import SnapDrillCore
import SnapDrillUI

/// 题目编辑 ViewModel
@Observable
public final class LibraryEditViewModel {

    // MARK: - State

    enum MetadataLoadState: Equatable { case loading, ready, failed }

    /// 题目正文（`nil` 表示纯图片题）
    public var content: String
    /// 答案文本
    public var answer: String

    // 动态维度（L3：取代旧固定分类/来源/级别/标签字段）
    /// 当前所有命名维度（按 sortOrder）
    public private(set) var dimensions: [CategoryDimensionModel] = []
    /// 每维度的可选值（dimensionId → values）
    public private(set) var valuesByDimension: [UUID: [CategoryValueModel]] = [:]
    /// 每维度的选中值（dimensionId → selected valueIds；编辑时从 item.categoryValues 初始化）
    public private(set) var selectedByDimension: [UUID: Set<UUID>] = [:]
    private(set) var metadataLoadState: MetadataLoadState = .loading

    /// 当前显示的题目图片（新选择或原始图片）
    public var displayedImage: UIImage?
    /// 题目图片加载失败标志
    public var imageLoadFailed = false
    /// 答案图片（新选择的，未持久化）
    public var answerDisplayedImage: UIImage?
    /// 答案图片加载失败标志
    public var answerImageLoadFailed = false
    /// 用户主动移除答案图片时置 true，save() 据此清空 answerImagePath
    public var isAnswerImageCleared: Bool = false
    /// 是否正在执行 OCR 或图片处理操作
    public var isProcessing = false
    /// 是否正在加载新选择的题目图片
    public private(set) var isQuestionPhotoLoading = false
    /// 是否正在加载新选择的答案图片
    public private(set) var isAnswerPhotoLoading = false
    /// 任一相册选择仍在加载时，保存必须等待用户选择落到编辑状态。
    public var isPhotoLoading: Bool {
        isQuestionPhotoLoading || isAnswerPhotoLoading
    }
    /// 是否已正常保存（用于触发返回导航）
    public var isSavedNormally = false
    /// 是否正在保存中（双击防护）
    public var isSaving = false
    /// 保存失败时的错误信息
    public var showErrorAlert = false
    /// 保存失败时的错误描述
    public var errorMessage = ""

    // MARK: - Dependencies

    private let item: ArchiveItemModel
    private let repositories: RepositoryContainer
    private let imageStorage: ImageStorage
    private let ocrService: OCRServiceProtocol
    private let activityTracker: AppActivityTracker
    private let photoDataLoader: @Sendable (PhotosPickerItem) async throws -> Data?

    /// OCR 任务句柄（@MainActor 隔离，由 View 的 onDisappear 通过 cancelTasks() 取消）
    @ObservationIgnored
    private var ocrTask: Task<Void, Never>?
    @ObservationIgnored
    private var questionPhotoLoadTask: Task<Void, Never>?
    @ObservationIgnored
    private var questionPhotoLoadToken = UUID()
    @ObservationIgnored
    private var answerPhotoLoadTask: Task<Void, Never>?
    @ObservationIgnored private var answerPhotoLoadToken = UUID()
    @ObservationIgnored var metadataLoader: () throws -> [CategoryDimensionModel]
    @ObservationIgnored var initialImageLoader: (String) async -> UIImage?
    @ObservationIgnored var beginActivity: (AppActivity) -> Void

    /// 创建题目编辑 ViewModel
    public init(
        item: ArchiveItemModel,
        repositories: RepositoryContainer,
        imageStorage: ImageStorage = ImageStorage(baseDirectory: FileManager.default.temporaryDirectory),
        ocrService: OCRServiceProtocol = OCRService(),
        activityTracker: AppActivityTracker? = nil,
        photoDataLoader: @escaping @Sendable (PhotosPickerItem) async throws -> Data? = {
            try await $0.loadTransferable(type: Data.self)
        }
    ) {
        let resolvedActivityTracker = activityTracker ?? AppActivityTracker.shared
        self.item = item
        self.repositories = repositories
        self.imageStorage = imageStorage
        self.ocrService = ocrService
        self.activityTracker = resolvedActivityTracker
        self.photoDataLoader = photoDataLoader
        self.metadataLoader = { try repositories.dimension.fetchAllModels() }
        self.initialImageLoader = { await imageStorage.loadImageAsync(path: $0) }
        self.beginActivity = { resolvedActivityTracker.begin($0) }

        self.content = item.content ?? ""
        self.answer = item.answerText ?? ""
        // 维度选中态在 loadData() 加载 dimensions 后从 item.categoryValues 初始化
    }

    // MARK: - Public API

    /// 先原子加载维度元数据，再异步加载图片。
    public func loadData() async {
        guard metadataLoadState != .ready else { return }
        metadataLoadState = .loading
        do {
            let loadedDimensions = try metadataLoader()
            let itemValues = item.categoryValues ?? []
            var values: [UUID: [CategoryValueModel]] = [:]
            var selected: [UUID: Set<UUID>] = [:]
            for dimension in loadedDimensions {
                values[dimension.id] = repositories.categoryValue.fetchAllModels(in: dimension)
                selected[dimension.id] = Set(
                    itemValues.filter { $0.dimension?.id == dimension.id }.map(\.id)
                )
            }
            dimensions = loadedDimensions
            valuesByDimension = values
            selectedByDimension = selected
            metadataLoadState = .ready
        } catch {
            metadataLoadState = .failed
            SnapDrillLogger.generic.error("加载维度失败: \(error.localizedDescription)")
            return
        }
        await loadImagesIfNeeded()
    }

    /// 异步加载题目/答案图片（避免同步 I/O 阻塞主线程）
    private func loadImagesIfNeeded() async {
        if displayedImage == nil, let path = item.imagePath {
            if let loaded = await initialImageLoader(path) {
                if displayedImage == nil {
                    displayedImage = loaded
                }
            } else if displayedImage == nil {
                imageLoadFailed = true
            }
        }
        if answerDisplayedImage == nil, !isAnswerImageCleared, let path = item.answerImagePath {
            if let loaded = await initialImageLoader(path) {
                if answerDisplayedImage == nil, !isAnswerImageCleared {
                    answerDisplayedImage = loaded
                }
            } else if answerDisplayedImage == nil, !isAnswerImageCleared {
                answerImageLoadFailed = true
            }
        }
    }

    // MARK: - 维度选择 / 新建（供 View 经 DimensionInputRow 驱动）

    /// 编辑页始终显示全部维度——保证用户能看到并修改题目已贴的任何标签，
    /// 不套采集页的极简缺省（PO 决策 3b：编辑页保留全部显示，避免隐藏已有标签）。
    public func isDimensionVisible(_: CategoryDimensionModel) -> Bool {
        true
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

    /// 切换某维度的值选中：单值替换（再点取消），多值切换
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

    /// 在某维度现场新建值并自动选中
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

    /// 移除答案图片
    public func removeAnswerImage() {
        cancelAnswerPhotoLoad()
        answerDisplayedImage = nil
        isAnswerImageCleared = true
    }

    /// 加载新选择的题目图片；成功后由 View 呈现裁剪器。
    @discardableResult
    public func loadQuestionPhoto(
        _ item: PhotosPickerItem,
        onLoaded: @escaping @MainActor (UIImage) -> Void
    ) -> Task<Void, Never>? {
        guard !isSaving, !isSavedNormally else { return nil }
        cancelQuestionPhotoLoad()
        let loadToken = UUID()
        questionPhotoLoadToken = loadToken
        isQuestionPhotoLoading = true
        let task = Task {
            defer {
                if self.questionPhotoLoadToken == loadToken {
                    self.questionPhotoLoadTask = nil
                    self.isQuestionPhotoLoading = false
                }
            }
            do {
                guard let image = try await loadSelectedPhoto(item) else {
                    guard isCurrentQuestionPhotoLoad(loadToken) else { return }
                    reportPhotoLoadFailure()
                    return
                }
                guard isCurrentQuestionPhotoLoad(loadToken) else { return }
                onLoaded(image)
            } catch is CancellationError {
                SnapDrillLogger.generic.info("题目图片加载任务已取消。")
            } catch {
                guard isCurrentQuestionPhotoLoad(loadToken) else { return }
                SnapDrillLogger.generic.error("加载题目图片失败: \(error.localizedDescription)")
                reportPhotoLoadFailure()
            }
        }
        questionPhotoLoadTask = task
        return task
    }

    /// 加载新选择的答案图片。
    @discardableResult
    public func loadAnswerPhoto(_ item: PhotosPickerItem) -> Task<Void, Never>? {
        guard !isSaving, !isSavedNormally else { return nil }
        cancelAnswerPhotoLoad()
        let loadToken = UUID()
        answerPhotoLoadToken = loadToken
        isAnswerPhotoLoading = true
        let task = Task {
            defer {
                if self.answerPhotoLoadToken == loadToken {
                    self.answerPhotoLoadTask = nil
                    self.isAnswerPhotoLoading = false
                }
            }
            do {
                guard let image = try await loadSelectedPhoto(item) else {
                    guard isCurrentAnswerPhotoLoad(loadToken) else { return }
                    reportPhotoLoadFailure()
                    return
                }
                guard isCurrentAnswerPhotoLoad(loadToken) else { return }
                self.answerDisplayedImage = image
                self.answerImageLoadFailed = false
                self.isAnswerImageCleared = false
            } catch is CancellationError {
                SnapDrillLogger.generic.info("答案图片加载任务已取消。")
            } catch {
                guard isCurrentAnswerPhotoLoad(loadToken) else { return }
                SnapDrillLogger.generic.error("加载答案图片失败: \(error.localizedDescription)")
                reportPhotoLoadFailure()
            }
        }
        answerPhotoLoadTask = task
        return task
    }

    /// 替换题目图片并触发 OCR 重新识别
    public func handleNewImage(_ image: UIImage) {
        cancelQuestionPhotoLoad()
        self.displayedImage = image
        self.isProcessing = true

        ocrTask?.cancel()
        ocrTask = Task {
            do {
                guard let cgImage = image.cgImage else { return }
                let recognizedText = try await ocrService.recognizeText(from: cgImage)
                guard !Task.isCancelled else { return }
                self.content = recognizedText
                self.isProcessing = false
            } catch is CancellationError {
                SnapDrillLogger.generic.info("编辑页 OCR 任务已取消。")
            } catch {
                SnapDrillLogger.generic.info("OCR 识别失败: \(error.localizedDescription)")
                self.isProcessing = false
            }
        }
    }

    /// 取消所有进行中的异步任务（由 View 的 onDisappear 调用）
    public func cancelTasks() {
        ocrTask?.cancel()
        ocrTask = nil
        cancelQuestionPhotoLoad()
        cancelAnswerPhotoLoad()
    }

    /// 保存草稿（预留接口，暂无实现）
    public func saveDraftIfNeeded() {
        // 后续可扩展草稿逻辑
    }

    /// 将当前编辑内容持久化到数据库
    public func save() async {
        guard metadataLoadState == .ready else {
            SnapDrillLogger.generic.warning("元数据未就绪，跳过保存。")
            return
        }
        guard !isSaving, !isPhotoLoading else { return }
        beginActivity(.capturing)
        defer { activityTracker.end(.capturing) }
        isSaving = true
        defer { isSaving = false }

        let willHaveContent = !content.isEmpty
        let willHaveImage = displayedImage != nil || item.imagePath != nil
        guard willHaveContent || willHaveImage else {
            SnapDrillLogger.generic.warning("保存失败：题目文字和图片均为空。")
            return
        }

        let oldImagePath = item.imagePath
        let oldAnswerImagePath = item.answerImagePath

        let newImagePath: String?
        let newAnswerImagePath: String?
        do {
            (newImagePath, newAnswerImagePath) = try await persistImages()
        } catch {
            SnapDrillLogger.generic.error("保存图片失败，中断保存: \(error.localizedDescription)")
            errorMessage = L10n.Errors.saveFailed
            showErrorAlert = true
            return
        }

        applyChangesToModel(newImagePath: newImagePath, newAnswerImagePath: newAnswerImagePath)

        do {
            try repositories.archive.saveContext()
            isSavedNormally = true
            NotificationCenter.default.post(name: .libraryDataDidChange, object: nil)
            deleteReplacedImages(
                oldImagePath: oldImagePath, newImagePath: newImagePath,
                oldAnswerPath: oldAnswerImagePath, newAnswerPath: newAnswerImagePath
            )
        } catch {
            repositories.archive.rollbackContext()
            if let path = newImagePath { bestEffortDeleteImage(path: path) }
            if let path = newAnswerImagePath { bestEffortDeleteImage(path: path) }
            SnapDrillLogger.generic.error("保存题目修改失败: \(error.localizedDescription)")
            errorMessage = L10n.Errors.saveFailed
            showErrorAlert = true
        }
    }

    // MARK: - Private Helpers

    private func loadSelectedPhoto(_ item: PhotosPickerItem) async throws -> UIImage? {
        guard let data = try await photoDataLoader(item) else { return nil }
        return UIImage(data: data)
    }

    private func isCurrentQuestionPhotoLoad(_ token: UUID) -> Bool {
        !Task.isCancelled && questionPhotoLoadToken == token
    }

    private func isCurrentAnswerPhotoLoad(_ token: UUID) -> Bool {
        !Task.isCancelled && answerPhotoLoadToken == token
    }

    private func cancelQuestionPhotoLoad() {
        questionPhotoLoadTask?.cancel()
        questionPhotoLoadTask = nil
        questionPhotoLoadToken = UUID()
        isQuestionPhotoLoading = false
    }

    private func cancelAnswerPhotoLoad() {
        answerPhotoLoadTask?.cancel()
        answerPhotoLoadTask = nil
        answerPhotoLoadToken = UUID()
        isAnswerPhotoLoading = false
    }

    private func reportPhotoLoadFailure() {
        errorMessage = L10n.Errors.imageLoadFailed
        showErrorAlert = true
    }

    /// 当前所有维度的选中值实例（扁平），写入 ArchiveItemModel.categoryValues
    private var selectedValues: [CategoryValueModel] {
        var result: [CategoryValueModel] = []
        for (dimId, valueIds) in selectedByDimension {
            let values = valuesByDimension[dimId] ?? []
            result.append(contentsOf: values.filter { valueIds.contains($0.id) })
        }
        // 丢弃已被管理页删除的值——本页缓存可能持有它处已删的 @Model，写回会复活值或造成悬挂引用
        return result.filter { !$0.isDeleted }
    }

    /// 将编辑状态同步到 @Model 属性（纯内存操作，无 await）
    private func applyChangesToModel(newImagePath: String?, newAnswerImagePath: String?) {
        item.content = content.isEmpty ? nil : content
        item.answerText = answer.isEmpty ? nil : answer
        // L3：分类经动态维度值；旧裸字符串字段不再写入
        item.categoryValues = selectedValues

        if let path = newImagePath { item.imagePath = path }
        if let path = newAnswerImagePath {
            item.answerImagePath = path
        } else if isAnswerImageCleared {
            item.answerImagePath = nil
        }
    }

    /// 持久化题目图片和答案图片，返回新写入的路径。
    private func persistImages() async throws -> (imagePath: String?, answerPath: String?) {
        var imagePath: String?
        if let newImage = displayedImage {
            do {
                imagePath = try await imageStorage.saveImage(newImage)
            } catch {
                SnapDrillLogger.generic.error("保存题目图片失败: \(error.localizedDescription)")
                throw error
            }
        }

        var answerPath: String?
        if let answerImg = answerDisplayedImage {
            do {
                answerPath = try await imageStorage.saveImage(answerImg)
            } catch {
                if let path = imagePath { bestEffortDeleteImage(path: path) }
                SnapDrillLogger.generic.error("保存答案图片失败: \(error.localizedDescription)")
                throw error
            }
        }

        return (imagePath, answerPath)
    }

    /// save 成功后删除被替换的旧图片文件（best-effort）
    private func deleteReplacedImages(
        oldImagePath: String?,
        newImagePath: String?,
        oldAnswerPath: String?,
        newAnswerPath: String?
    ) {
        if newImagePath != nil, let old = oldImagePath { bestEffortDeleteImage(path: old) }
        if newAnswerPath != nil || isAnswerImageCleared, let old = oldAnswerPath {
            bestEffortDeleteImage(path: old)
        }
    }

    /// 删除图片文件，失败时记录日志（best-effort，async 避免阻塞主线程）
    private func bestEffortDeleteImage(path: String) {
        Task {
            do {
                try await imageStorage.deleteImage(path: path)
            } catch {
                SnapDrillLogger.generic.error("清理图片文件失败: \(error.localizedDescription)")
            }
        }
    }
}
