//
//  MarkAsReviewedUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation
import SwiftData

actor MarkAsReviewedUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute(_ question: Question) async throws {
        question.isReviewed = true
        question.reviewedAt = Date()
        question.reviewCount += 1
        
        try modelContext.save()
    }
    
    func unmarkAsReviewed(_ question: Question) async throws {
        question.isReviewed = false
        question.reviewedAt = nil
        // 保留 reviewCount，因为这是历史记录
        
        try modelContext.save()
    }
}