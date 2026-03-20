//
//  LibraryEditViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  题目编辑 ViewModel，直接操作 ReviewItemModel 进行持久化。
//

import SwiftUI
import SnapDrillData
import SnapDrillCore

/// 题目编辑 ViewModel
///
/// 管理现有题目的编辑状态，包括图片替换（含 OCR 重新识别）、分类信息更新和持久化保存。
@Observable
@MainActor
public final class LibraryEditViewModel {

    // MARK: - State

    /// 题目正文（`nil` 表示纯图片题）
    public var content: String
    /// 答案文本
    public var answer: String
    /// 当前选中的学科名称
    public var selectedSubject: String
    /// 当前选中的来源名称
    public var selectedSource: String
    /// 当前选中的年级名称
    public var grade: String
    /// 标签列表（字符串形式）
    public var tagList: [String]
    /// 题目难度
    public var difficulty: Difficulty

    /// 当前显示的题目图片（新选择或原始图片）
    public var displayedImage: UIImage?
    /// 答案图片（新选择的，未持久化）
    public var answerDisplayedImage: UIImage?
    /// 用户主动移除答案图片时置 true，save() 据此清空 answerImagePath
    public var isAnswerImageCleared: Bool = false
    /// 是否正在执行 OCR 或图片处理操作
    public var isProcessing = false
    /// 是否已正常保存（用于触发返回导航）
    public var isSavedNormally = false
    /// 是否正在保存中（双击防护）
    public var isSaving = false
    /// 保存失败时的错误信息
    public var showErrorAlert = false
    /// 保存失败时的错误描述
    public var errorMessage = ""
    /// 是否正在显示图片裁剪界面
    public var isCropping = false
    /// 待裁剪的图片（显示裁剪界面时有值）
    public var imageToCrop: UIImage?

    /// 可选学科列表
    public var subjects: [SubjectModel] = []
    /// 可选来源列表
    public var sources: [SourceModel] = []
    /// 可选年级列表
    public var grades: [GradeModel] = []
    /// 可选标签列表
    public var allTags: [TagModel] = []

    // MARK: - Dependencies

    private let item: ReviewItemModel
    private let repositories: RepositoryContainer
    private let imageStorage: ImageStorage
    private let ocrService: OCRServiceProtocol

    /// OCR 任务句柄（@MainActor 隔离，由 View 的 onDisappear 通过 cancelTasks() 取消）
    /// @ObservationIgnored：Task 不是 UI 状态，不应触发 Observation 追踪
    @ObservationIgnored
    private var ocrTask: Task<Void, Never>?

    /// 创建题目编辑 ViewModel
    /// - Parameters:
    ///   - item: 要编辑的题目模型
    ///   - repositories: 应用的数据仓库容器
    ///   - imageStorage: 图片存储服务，默认使用 `ImageStorage()`
    ///   - ocrService: OCR 识别服务，默认使用 `OCRService()`
    public init(
        item: ReviewItemModel,
        repositories: RepositoryContainer,
        imageStorage: ImageStorage = ImageStorage(),
        ocrService: OCRServiceProtocol = OCRService()
    ) {
        self.item = item
        self.repositories = repositories
        self.imageStorage = imageStorage
        self.ocrService = ocrService

        self.content = item.content ?? ""
        self.answer = item.answerText ?? ""
        self.selectedSubject = item.subject
        self.selectedSource = item.source
        self.grade = item.grade
        self.tagList = (item.tags ?? []).map { $0.name }
        self.difficulty = item.difficultyValue
    }

    // MARK: - Public API

    /// 加载图片和分类元数据（学科/来源/年级/标签）
    public func loadData() async {
        // 异步加载图片，避免同步 I/O 阻塞主线程（编辑页打开卡顿）
        if displayedImage == nil, let path = item.imagePath {
            displayedImage = await imageStorage.loadImageAsync(path: path)
        }
        if answerDisplayedImage == nil, let path = item.answerImagePath {
            answerDisplayedImage = await imageStorage.loadImageAsync(path: path)
        }

        do {
            self.subjects = try repositories.subject.fetchAllModels()
            self.sources = try repositories.source.fetchAllModels()
            self.grades = try repositories.grade.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
            self.allTags = try repositories.tag.fetchAllModels()
        } catch {
            SnapDrillLogger.generic.error("加载元数据失败: \(error.localizedDescription)")
        }
    }

    /// 移除答案图片
    public func removeAnswerImage() {
        answerDisplayedImage = nil
        isAnswerImageCleared = true
    }

    /// 设置新的答案图片
    public func handleNewAnswerImage(_ image: UIImage) {
        answerDisplayedImage = image
        isAnswerImageCleared = false
    }

    /// 替换题目图片并触发 OCR 重新识别
    public func handleNewImage(_ image: UIImage) {
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
    }

    /// 保存草稿（预留接口，暂无实现）
    public func saveDraftIfNeeded() {
        // 后续可扩展草稿逻辑
    }

    /// 将当前编辑内容持久化到数据库
    ///
    /// 先异步写入图片文件，IO 完成后统一修改 `@Model` 属性再调用 `saveContext()`。
    /// 失败时自动 `rollbackContext()` 并清理孤儿图片文件。
    public func save() async {
        // 双击防护
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        // 业务规则验证先行
        let willHaveContent = !content.isEmpty
        let willHaveImage = displayedImage != nil
        guard willHaveContent || willHaveImage else {
            SnapDrillLogger.generic.warning("保存失败：题目文字和图片均为空。")
            return
        }

        // 记录旧图片路径，save 成功后删除（替换图片时清理旧文件）
        let oldImagePath = item.imagePath
        let oldAnswerImagePath = item.answerImagePath

        // 1. 先执行耗时异步 IO（@Model 属性尚未修改，不存在跨挂起点脏状态）
        let newImagePath: String?
        let newAnswerImagePath: String?
        do {
            (newImagePath, newAnswerImagePath) = try await persistImages()
        } catch {
            // IO 失败时 @Model 未被修改，无需 rollback，但须通知用户
            SnapDrillLogger.generic.error("保存图片失败，中断保存: \(error.localizedDescription)")
            errorMessage = L10n.Errors.saveFailed
            showErrorAlert = true
            return
        }

        // 2. IO 完成后集中修改 @Model 属性（纯内存同步操作，无 await）
        applyChangesToModel(newImagePath: newImagePath, newAnswerImagePath: newAnswerImagePath)

        // 3. 立即保存
        do {
            try repositories.review.saveContext()
            isSavedNormally = true
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
            deleteReplacedImages(
                oldImagePath: oldImagePath, newImagePath: newImagePath,
                oldAnswerPath: oldAnswerImagePath, newAnswerPath: newAnswerImagePath
            )
        } catch {
            // 回滚 mainContext：撤销本次所有内存变更（@Model 属性修改、Tag 插入）
            // 单用户本地架构下 rollback 影响范围仅限本次 save() 调用
            repositories.review.rollbackContext()
            if let path = newImagePath { bestEffortDeleteImage(path: path) }
            if let path = newAnswerImagePath { bestEffortDeleteImage(path: path) }
            SnapDrillLogger.generic.error("保存题目修改失败: \(error.localizedDescription)")
            errorMessage = L10n.Errors.saveFailed
            showErrorAlert = true
        }
    }

    // MARK: - Private Helpers

    /// 将编辑状态同步到 @Model 属性（纯内存操作，无 await）
    private func applyChangesToModel(newImagePath: String?, newAnswerImagePath: String?) {
        item.content = content.isEmpty ? nil : content
        item.answerText = answer.isEmpty ? nil : answer
        item.subject = selectedSubject
        item.source = selectedSource
        item.grade = grade
        item.difficultyValue = difficulty

        // 同步标签（fetchOrCreateModel 是纯内存操作）
        var finalTagModels: [TagModel] = []
        for name in tagList {
            do {
                let tagModel = try repositories.tag.fetchOrCreateModel(name: name, colorHex: "#9E9E9E")
                finalTagModels.append(tagModel)
            } catch {
                SnapDrillLogger.generic.error("同步标签失败: \(error.localizedDescription)")
            }
        }
        item.tags = finalTagModels

        // 设置图片路径
        if let path = newImagePath { item.imagePath = path }
        if let path = newAnswerImagePath {
            item.answerImagePath = path
        } else if isAnswerImageCleared {
            item.answerImagePath = nil
        }
    }

    /// 持久化题目图片和答案图片，返回新写入的路径。
    /// 不修改 @Model 属性（由 save() 在 IO 完成后统一赋值）。
    /// 答案图片保存失败时自动清理已写入的题目图片，防止孤儿文件。
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
                // 清理已写入的题目图片（孤儿文件）
                if let path = imagePath { bestEffortDeleteImage(path: path) }
                SnapDrillLogger.generic.error("保存答案图片失败: \(error.localizedDescription)")
                throw error
            }
        }

        return (imagePath, answerPath)
    }

    /// save 成功后删除被替换的旧图片文件（best-effort）
    /// 注：主图片不允许清空（UI 只提供替换功能），无需处理主图片被清空的情况
    private func deleteReplacedImages(
        oldImagePath: String?,
        newImagePath: String?,
        oldAnswerPath: String?,
        newAnswerPath: String?
    ) {
        if newImagePath != nil, let old = oldImagePath { bestEffortDeleteImage(path: old) }
        // 答案图片：被替换或被主动移除时均删除旧文件
        if newAnswerPath != nil || isAnswerImageCleared, let old = oldAnswerPath {
            bestEffortDeleteImage(path: old)
        }
    }

    /// 删除图片文件，失败时记录日志（best-effort，不向上抛出；async 避免阻塞主线程）
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
