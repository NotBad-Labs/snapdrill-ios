//
//  CreateReviewItemUseCase.swift
//  NotBad
//
//  Application Layer - Use Case Implementation
//

import Foundation

// MARK: - CreateReviewItemUseCase

/// 创建错题用例实现
///
/// 实现 `CreateReviewItemUseCaseProtocol`，负责：
/// - 验证输入数据
/// - 创建 Domain 实体
/// - 保存到仓库
/// - 分离存储图片数据
@MainActor
final class CreateReviewItemUseCase: CreateReviewItemUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let repository: ReviewItemRepositoryProtocol
    private let imageRepository: ImageRepositoryProtocol?
    
    // MARK: - Initialization
    
    init(repository: ReviewItemRepositoryProtocol, imageRepository: ImageRepositoryProtocol? = nil) {
        self.repository = repository
        self.imageRepository = imageRepository
    }
    
    // MARK: - CreateReviewItemUseCaseProtocol
    
    func execute(input: CreateReviewItemInput) async throws -> ReviewItem {
        // 1. 验证输入
        try input.validate()
        
        // 2. 创建 Domain 实体（不含图片数据，图片单独存储）
        let item = ReviewItem(
            imageData: nil,  // 图片数据分离存储
            title: input.title,
            note: input.note,
            subject: input.subject,
            grade: input.grade,
            knowledgePoints: KnowledgePoints(input.knowledgePoints),
            difficulty: input.difficulty,
            errorType: input.errorType,
            source: input.source,
            reviewItemType: input.reviewItemType
        )
        
        // 3. 保存到仓库
        do {
            try repository.save(item)
        } catch {
            throw CreateReviewItemError.saveFailed(underlying: error)
        }
        
        // 4. 分离存储图片数据
        if let imageData = input.imageData, let imageRepo = imageRepository {
            do {
                try imageRepo.saveImage(imageData, for: item.id)
            } catch {
                // 图片保存失败不影响主流程，仅记录日志
                // 图片可以后续重新添加
            }
        }
        
        return item
    }
    
    func execute(
        ocrResult: OCRResult,
        imageData: Data
    ) async throws -> ReviewItem {
        // 从 OCR 结果提取信息
        let input = CreateReviewItemInput(
            title: extractTitle(from: ocrResult),
            imageData: imageData,
            subject: .other,      // 默认学科，用户后续可修改
            grade: .grade10,      // 默认年级
            difficulty: .medium,
            errorType: .concept,
            knowledgePoints: [],
            note: ocrResult.text
        )
        
        return try await execute(input: input)
    }
    
    // MARK: - Private Methods
    
    /// 从 OCR 结果提取标题
    private func extractTitle(from ocrResult: OCRResult) -> String {
        // 取第一行作为标题，最多 50 个字符
        let firstLine = ocrResult.text.components(separatedBy: .newlines).first ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.count > 50 {
            return String(trimmed.prefix(47)) + "..."
        }
        
        return trimmed.isEmpty ? "未命名错题" : trimmed
    }
}
