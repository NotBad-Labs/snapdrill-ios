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

@Observable
@MainActor
public final class LibraryEditViewModel {

    // MARK: - State

    public var content: String
    public var answer: String
    public var selectedSubject: String
    public var selectedSource: String
    public var grade: String
    public var tagList: [String]
    public var difficulty: Difficulty

    public var displayedImage: UIImage?
    /// 答案图片（新选择的，未持久化）
    public var answerDisplayedImage: UIImage?
    /// 用户主动移除答案图片时置 true，save() 据此清空 answerImagePath
    public var isAnswerImageCleared: Bool = false
    public var isProcessing = false
    public var isSavedNormally = false
    public var isCropping = false
    public var imageToCrop: UIImage?

    public var subjects: [SubjectModel] = []
    public var sources: [SourceModel] = []
    public var grades: [GradeModel] = []
    public var allTags: [TagModel] = []

    // MARK: - Dependencies

    private let item: ReviewItemModel
    private let repositories: RepositoryContainer
    private let imageStorage = ImageStorage()
    private let ocrService = OCRService()

    /// OCR 任务句柄（@MainActor 隔离，由 View 的 onDisappear 通过 cancelTasks() 取消）
    /// @ObservationIgnored：Task 不是 UI 状态，不应触发 Observation 追踪
    @ObservationIgnored
    private var ocrTask: Task<Void, Never>?

    public init(item: ReviewItemModel, repositories: RepositoryContainer) {
        self.item = item
        self.repositories = repositories

        self.content = item.content ?? ""
        self.answer = item.answerText ?? ""
        self.selectedSubject = item.subject
        self.selectedSource = item.source
        self.grade = item.grade
        self.tagList = (item.tags ?? []).map { $0.name }
        self.difficulty = item.difficultyValue
    }

    // MARK: - Public API

    public func loadData() {
        if displayedImage == nil, let path = item.imagePath {
            displayedImage = imageStorage.loadImage(path: path)
        }
        if answerDisplayedImage == nil, let path = item.answerImagePath {
            answerDisplayedImage = imageStorage.loadImage(path: path)
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

    public func saveDraftIfNeeded() {
        // 后续可扩展草稿逻辑
    }

    public func save() async {
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
            // IO 失败时 @Model 未被修改，无需 rollback，直接返回
            SnapDrillLogger.generic.error("保存图片失败，中断保存: \(error.localizedDescription)")
            return
        }

        // 2. IO 完成后集中修改 @Model 属性（纯内存同步操作，无 await）
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
            if let path = newImagePath { try? imageStorage.deleteImage(path: path) }
            if let path = newAnswerImagePath { try? imageStorage.deleteImage(path: path) }
            SnapDrillLogger.generic.error("保存题目修改失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

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
                if let path = imagePath { try? imageStorage.deleteImage(path: path) }
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
        if newImagePath != nil, let old = oldImagePath { try? imageStorage.deleteImage(path: old) }
        if newAnswerPath != nil, let old = oldAnswerPath { try? imageStorage.deleteImage(path: old) }
        if isAnswerImageCleared, let old = oldAnswerPath { try? imageStorage.deleteImage(path: old) }
    }
}
