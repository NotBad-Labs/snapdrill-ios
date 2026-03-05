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

/// 采集结果预览与编辑的 ViewModel
@MainActor
@Observable
public final class CaptureResultViewModel {

    // MARK: - Properties

    public var content: String
    public var image: UIImage?

    // 分类信息
    public var selectedSubject: String = "数学"
    public var selectedSource: String = "试卷"
    public var tagList: [String] = []
    public var tagInputText: String = ""

    // 详情表单
    public var answerText: String = ""
    public var difficulty: Difficulty = .one
    public var grade: String = ""
    public var answerImage: UIImage?

    // 相册选择器状态
    public var answerPhotoItem: PhotosPickerItem? {
        didSet {
            processSelectedPhoto()
        }
    }

    // UI 状态
    public var isRecognizing = false
    public var isCropping = false
    public var isSaved = false
    public var showErrorAlert = false
    public var errorMessage: String?

    // 新建分类 Alert 状态
    public var showNewSubjectAlert = false
    public var newSubjectName = ""
    public var showNewSourceAlert = false
    public var newSourceName = ""
    public var showNewGradeAlert = false
    public var newGradeName = ""

    // 下拉表单数据（@Model 类型）
    public private(set) var availableSubjects: [SubjectModel] = []
    public private(set) var availableSources: [SourceModel] = []
    public private(set) var availableGrades: [GradeModel] = []
    public private(set) var availableTags: [TagModel] = []

    // MARK: - Dependencies

    private let repositories: RepositoryContainer
    private let ocrService: OCRServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let imageStorage: ImageStorage
    private let router: CaptureRouter

    /// 识别任务句柄
    private var recognitionTask: Task<Void, Never>?

    // MARK: - Initialization

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

    /// 加载默认表单数据
    public func loadFormData() {
        do {
            availableSubjects = try repositories.subject.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
            availableSources = try repositories.source.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
            availableGrades = try repositories.grade.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
            availableTags = try repositories.tag.fetchAllModels().sorted(by: { $0.name < $1.name })
        } catch {
            SnapDrillLogger.generic.error("加载下拉表单失败: \(error.localizedDescription)")
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

    /// 保存预览草稿（离开时触发）
    public func generateDraftIfNeeded() {
        if !isSaved, let img = image, !content.isEmpty {
            CaptureDraftService.shared.saveDraft(image: img, content: content)
        }
    }

    /// 保存正式题目
    public func saveResult() async {
        isSaved = true

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
                    userInfo: [NSLocalizedDescriptionKey: "题目文字和图片不能同时为空"]
                )
            }

            // 解析并同步标签
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

            // 构造 @Model 对象并插入
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
            try repositories.review.insertAndSave(model)

            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)

            // 埋点
            analyticsService.track(
                .captureSaved,
                parameters: [
                    "subject": selectedSubject,
                    "source": selectedSource,
                    "difficulty": String(difficulty.rawValue)
                ]
            )

            // 清理并返回
            CaptureDraftService.shared.clearDraft()
            router.path.removeLast(router.path.count)

        } catch {
            // 清理已写入磁盘但未成功关联到 @Model 的孤儿图片文件
            if let path = savedImagePath {
                try? imageStorage.deleteImage(path: path)
            }
            if let path = savedAnswerImagePath {
                try? imageStorage.deleteImage(path: path)
            }
            SnapDrillLogger.generic.error("保存失败: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
            isSaved = false
        }
    }

    // MARK: - Private Helpers

    private func processSelectedPhoto() {
        guard let item = answerPhotoItem else { return }
        Task {
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
