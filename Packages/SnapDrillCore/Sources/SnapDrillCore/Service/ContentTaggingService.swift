//
//  ContentTaggingService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/04/16.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  端侧 AI 内容标注服务，使用 FoundationModels 框架自动建议学科和难度。
//

import Foundation
import FoundationModels

// MARK: - 标注结果

/// AI 建议的题目元数据
nonisolated public struct ContentTagSuggestion: Sendable, Equatable {
    /// 建议学科（如"数学"、"英语"）
    public let subject: String
    /// 建议难度（1-5）
    public let difficulty: Int

    public init(subject: String, difficulty: Int) {
        self.subject = subject
        self.difficulty = difficulty
    }
}

// MARK: - 服务协议

/// 内容标注服务协议
///
/// 从题目文本中自动推断学科和难度。
/// 设备不支持 Apple Intelligence 时返回 nil。
public protocol ContentTaggingServiceProtocol: Sendable {
    /// 从题目文本推断学科和难度
    ///
    /// - Parameter text: OCR 识别的题目文本
    /// - Returns: AI 建议的元数据，设备不支持或推断失败时返回 nil
    func suggestTags(for text: String) async -> ContentTagSuggestion?
}

// MARK: - 生产实现

/// 端侧 AI 内容标注服务
///
/// 使用 `FoundationModels` 框架的 `contentTagging` adapter，
/// 在设备端推断题目的学科分类和难度等级。全部数据本地处理，离线可用。
public actor ContentTaggingService: ContentTaggingServiceProtocol {

    public init() {}

    public func suggestTags(for text: String) async -> ContentTagSuggestion? {
        // 空文本无法推断
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        // 检查设备是否支持 Apple Intelligence
        guard SystemLanguageModel.default.isAvailable else {
            SnapDrillLogger.generic.info("FoundationModels 不可用，跳过自动标注。")
            return nil
        }

        do {
            let session = LanguageModelSession(
                model: SystemLanguageModel(useCase: .contentTagging),
                instructions: "根据题目内容判断学科和难度。学科从以下选择：数学、语文、英语、物理、化学、生物、历史、地理、政治。难度 1-5，1 最简单 5 最难。"
            )

            let response = try await session.respond(
                to: text,
                generating: TaggingResult.self
            )

            let result = response.content
            let clampedDifficulty = max(1, min(5, result.difficulty))
            return ContentTagSuggestion(subject: result.subject, difficulty: clampedDifficulty)
        } catch {
            SnapDrillLogger.generic.error("AI 标注失败: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - FoundationModels 结构化输出

@Generable
struct TaggingResult {
    @Guide(description: "学科分类，如数学、语文、英语、物理、化学、生物、历史、地理、政治")
    var subject: String
    @Guide(description: "难度等级 1-5，1 最简单 5 最难")
    var difficulty: Int
}

// MARK: - Mock

/// 内容标注服务 Mock（测试用）
public final class ContentTaggingServiceMock: ContentTaggingServiceProtocol, @unchecked Sendable {
    public var suggestResult: ContentTagSuggestion?
    public var suggestCallCount = 0

    public init() {}

    public func suggestTags(for text: String) async -> ContentTagSuggestion? {
        suggestCallCount += 1
        return suggestResult
    }
}
