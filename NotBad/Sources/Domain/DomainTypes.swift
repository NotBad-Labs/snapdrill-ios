//
//  DomainTypes.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/9/12.
//

import Foundation

// MARK: - 枚举类型定义
// 注意：MasteryLevel 和 ParentShareStatus 已在 ReviewItem.swift 中定义

public enum StudyResult: String, Codable, CaseIterable {
    case correct = "correct"
    case incorrect = "incorrect"
    case partial = "partial"
    case skipped = "skipped"
}

// MARK: - 错误类型定义
public enum OCRError: Error {
    case invalidImage
    case recognitionFailed
    case lowConfidence
}

public enum NetworkError: Error {
    case noConnection
    case timeout
    case invalidResponse
}

public enum SyncError: Error {
    case conflictDetected
    case quotaExceeded
    case cloudKitUnavailable
}
