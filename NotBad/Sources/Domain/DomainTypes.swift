//
//  DomainTypes.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/9/12.
//

import Foundation

// MARK: - 枚举类型定义
public enum MasteryLevel: String, CaseIterable, Codable {
    case notMastered = "not_mastered"
    case unclear = "unclear"
    case mastered = "mastered"
}

public enum Subject: String, CaseIterable, Codable {
    case math = "math"
    case chinese = "chinese"
    case english = "english"
    case physics = "physics"
    case chemistry = "chemistry"
    case biology = "biology"
}

public enum ParentShareStatus: String, Codable {
    case none = "none"
    case summary = "summary"
    case oneTime = "one_time"
    case itemLevel = "item_level"
}

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
