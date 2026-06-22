//
//  ContentTaggingService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  端侧 AI 内容标注服务，使用 FoundationModels 框架自动建议分类和难度。
//

import Foundation
import FoundationModels

// MARK: - 标注结果

/// AI 建议的资料元数据
nonisolated public struct ContentTagSuggestion: Sendable, Equatable {
    /// 建议主分类（如"题目"、"文档"）
    public let category: String
    /// 建议难度（1-5）
    public let difficulty: Int

    public init(category: String, difficulty: Int) {
        self.category = category
        self.difficulty = difficulty
    }
}

// MARK: - 服务协议

/// 内容标注服务协议
///
/// 从资料文本中自动推断分类和难度。
/// 设备不支持 Apple Intelligence 时返回 nil。
public protocol ContentTaggingServiceProtocol: Sendable {
    /// 从资料文本推断分类和难度
    ///
    /// - Parameter text: OCR 识别的题目文本
    /// - Returns: AI 建议的元数据，设备不支持或推断失败时返回 nil
    func suggestTags(for text: String) async -> ContentTagSuggestion?
}

// MARK: - 生产实现

/// 端侧 AI 内容标注服务
///
/// 使用 `FoundationModels` 框架的 `contentTagging` adapter，
/// 在设备端推断资料分类和难度等级。全部数据本地处理，离线可用。
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
                instructions: "根据资料内容判断分类和难度。分类从以下选择：题目、文档、票据、培训、工作、其他。难度 1-5，1 最简单 5 最难。"
            )

            let response = try await session.respond(
                to: text,
                generating: TaggingResult.self
            )

            let result = response.content
            let clampedDifficulty = max(1, min(5, result.difficulty))
            return ContentTagSuggestion(category: result.category, difficulty: clampedDifficulty)
        } catch {
            SnapDrillLogger.generic.error("AI 标注失败: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - FoundationModels 结构化输出

@Generable
struct TaggingResult {
    @Guide(description: "资料分类，如题目、文档、票据、培训、工作、其他")
    var category: String
    @Guide(description: "难度等级 1-5，1 最简单 5 最难")
    var difficulty: Int
}

// MARK: - Mock

/// 内容标注服务 Mock（测试用，@MainActor 隔离替代 @unchecked Sendable）
@MainActor
public final class ContentTaggingServiceMock: ContentTaggingServiceProtocol {
    public var suggestResult: ContentTagSuggestion?
    public var suggestCallCount = 0

    public init() {}

    public func suggestTags(for text: String) async -> ContentTagSuggestion? {
        suggestCallCount += 1
        return suggestResult
    }
}
