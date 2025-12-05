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
/// - 验证输入
/// - 创建实体
/// - 保存到仓库
@MainActor
final class CreateReviewItemUseCase: CreateReviewItemUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let repository: ReviewItemRepositoryProtocol
    
    // MARK: - Initialization
    
    init(repository: ReviewItemRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - CreateReviewItemUseCaseProtocol
    
    func execute(input: CreateReviewItemInput) async throws -> ReviewItem {
        // 验证输入
        try input.validate()
        
        // 创建实体
        let item = ReviewItem(
            title: input.title.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: input.imageData,
            subject: input.subject,
            grade: input.grade,
            difficulty: input.difficulty,
            errorType: input.errorType,
            knowledgePoints: input.knowledgePoints,
            note: input.note
        )
        
        // 保存
        do {
            try repository.save(item)
            return item
        } catch {
            throw CreateReviewItemError.saveFailed(underlying: error)
        }
    }
    
    func execute(
        ocrResult: OCRResult,
        imageData: Data
    ) async throws -> ReviewItem {
        // 从 OCR 结果提取标题
        let title = extractTitle(from: ocrResult)
        
        // 推断学科，默认为其他
        let subject = ocrResult.inferredSubject ?? .other
        
        // 创建输入
        let input = CreateReviewItemInput(
            title: title,
            imageData: imageData,
            subject: subject,
            grade: .grade7, // 默认年级，可后续修改
            knowledgePoints: ocrResult.inferredKnowledgePoints
        )
        
        return try await execute(input: input)
    }
    
    // MARK: - Private Methods
    
    /// 从 OCR 结果提取标题
    private func extractTitle(from result: OCRResult) -> String {
        let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 取第一行作为标题
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        
        // 限制长度
        if firstLine.count > 50 {
            return String(firstLine.prefix(50)) + "..."
        }
        
        return firstLine.isEmpty ? "未命名题目" : firstLine
    }
}
