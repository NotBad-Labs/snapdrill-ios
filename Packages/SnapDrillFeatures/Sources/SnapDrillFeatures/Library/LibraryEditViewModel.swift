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

    @ObservationIgnored
    nonisolated(unsafe) private var ocrTask: Task<Void, Never>?

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

    deinit {
        ocrTask?.cancel()
    }

    public func saveDraftIfNeeded() {
        // 后续可扩展草稿逻辑
    }

    public func save() async {
        // 业务规则验证先行：在修改任何 @Model 属性之前完成，防止脏数据被意外持久化
        let willHaveContent = !content.isEmpty
        let willHaveImage = displayedImage != nil
        guard willHaveContent || willHaveImage else {
            SnapDrillLogger.generic.warning("保存失败：题目文字和图片均为空。")
            return
        }

        // 验证通过后再修改 @Model 属性
        item.content = content.isEmpty ? nil : content
        item.answerText = answer.isEmpty ? nil : answer
        item.subject = selectedSubject
        item.source = selectedSource
        item.grade = grade
        item.difficultyValue = difficulty

        // 同步标签（getOrCreate 确保 TagModel 存在）
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

        // 处理题目图片保存
        if let newImage = displayedImage {
            do {
                let newPath = try await imageStorage.saveImage(newImage)
                item.imagePath = newPath
            } catch {
                SnapDrillLogger.generic.error("保存题目图片失败: \(error.localizedDescription)")
            }
        }

        // 处理答案图片保存
        if let answerImg = answerDisplayedImage {
            do {
                let newPath = try await imageStorage.saveImage(answerImg)
                item.answerImagePath = newPath
            } catch {
                SnapDrillLogger.generic.error("保存答案图片失败: \(error.localizedDescription)")
            }
        } else if isAnswerImageCleared {
            item.answerImagePath = nil
        }

        do {
            try repositories.review.saveContext()
            isSavedNormally = true
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
        } catch {
            SnapDrillLogger.generic.error("保存题目修改失败: \(error.localizedDescription)")
        }
    }
}
