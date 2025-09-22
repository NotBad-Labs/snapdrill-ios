//
//  CaptureReviewItemUseCase.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import Foundation

/// 捕获复习项用例
/// Application Service，协调Domain Services来完成复杂的业务流程
final class CaptureReviewItemUseCase {
    
    // MARK: - Dependencies
    private let reviewItemService: ReviewItemService
    
    // MARK: - Initialization
    init(reviewItemService: ReviewItemService) {
        self.reviewItemService = reviewItemService
    }
    
    // MARK: - Use Cases
    
    /// 处理OCR捕获的复习项
    /// 注意：OCR文本不再自动解析，需要用户手动提供所有信息
    /// - Parameters:
    ///   - ocrText: OCR识别的原始文本（仅作为参考）
    ///   - userInput: 用户手动输入的完整信息
    /// - Returns: 创建的复习项ID
    func captureFromOCR(
        ocrText: String,
        userInput: ReviewItemUserInput
    ) async throws -> ReviewItemID {
        // 1. 验证用户输入的完整性
        guard !userInput.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !userInput.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CaptureError.missingRequiredFields
        }
        
        // 2. 直接使用用户提供的信息创建复习项
        return try await reviewItemService.createReviewItem(
            question: userInput.question,
            answer: userInput.answer,
            subject: userInput.subject.rawValue,
            difficulty: userInput.difficulty.rawValue,
            tags: Array(userInput.tags),
            notes: userInput.notes
        )
    }
    
    /// 处理用户手动输入的复习项
    /// - Parameter userInput: 用户输入的数据
    /// - Returns: 创建的复习项ID
    func captureFromUserInput(
        _ userInput: ReviewItemUserInput
    ) async throws -> ReviewItemID {
        // 1. 验证必要字段
        guard !userInput.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !userInput.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CaptureError.missingRequiredFields
        }
        
        // 2. 直接创建复习项（不再需要解析增强）
        return try await reviewItemService.createReviewItem(
            question: userInput.question,
            answer: userInput.answer,
            subject: userInput.subject.rawValue,
            difficulty: userInput.difficulty.rawValue,
            tags: Array(userInput.tags),
            notes: userInput.notes
        )
    }
}

// MARK: - Data Transfer Objects

/// 用户输入的复习项数据
struct ReviewItemUserInput {
    let question: String
    let answer: String
    let subject: ReviewItem.Subject
    let difficulty: ReviewItem.Difficulty
    let tags: Set<String>
    let notes: String?
}

/// 复习项草稿（用于展示给用户确认）
/// 注意：此结构体已不再使用，因为不再需要解析
struct ReviewItemDraft {
    let question: String
    let answer: String
    let subject: ReviewItem.Subject
    let difficulty: ReviewItem.Difficulty
    let tags: Set<String>
    let notes: String?
    
    var isValid: Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Errors

enum CaptureError: Error, LocalizedError {
    case missingRequiredFields
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredFields:
            return "请填写完整的题目和答案"
        }
    }
}