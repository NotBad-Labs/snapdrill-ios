//
//  QuestionSplittingService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  端侧 AI 内容分割服务，使用 FoundationModels 框架从整页 OCR 文本提取独立条目。
//  Issue #626 PoC：评估边界检测准确率 >= 80%（10 份真实资料）则正式纳入。
//

import Foundation
import FoundationModels

// MARK: - 分割结果

/// AI 提取的单个题目
nonisolated public struct ExtractedQuestionItem: Sendable, Equatable {
    /// 题目完整文本（含题号和题干）
    public let text: String
    /// 题目序号（1-based）
    public let ordinal: Int

    public init(text: String, ordinal: Int) {
        self.text = text
        self.ordinal = ordinal
    }
}

// MARK: - 服务协议

/// 题目分割服务协议
///
/// 从整页 OCR 文本中提取独立题目列表。
/// 设备不支持 Apple Intelligence 时返回空数组。
public protocol QuestionSplittingServiceProtocol: Sendable {
    /// 从整页 OCR 文本中提取独立题目
    ///
    /// - Parameter text: 整页 OCR 识别后的文本（通常来自 RecognizeDocumentsRequest.transcript）
    /// - Returns: 提取的题目列表；空文本、设备不支持或推断失败时返回空数组
    func split(documentText text: String) async -> [ExtractedQuestionItem]
}

// MARK: - 生产实现

/// 端侧 AI 题目分割服务
///
/// 使用 `FoundationModels` 框架的默认 SystemLanguageModel，
/// 在设备端从整页 OCR 文本中提取独立题目。全部数据本地处理，离线可用。
public actor QuestionSplittingService: QuestionSplittingServiceProtocol {

    public init() {}

    public func split(documentText text: String) async -> [ExtractedQuestionItem] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        guard SystemLanguageModel.default.isAvailable else {
            SnapDrillLogger.generic.info("FoundationModels 不可用，跳过题目分割。")
            return []
        }

        do {
            let session = LanguageModelSession(
                instructions: """
                从 OCR 文本中提取每条独立内容项，例如题目、清单项或小节。

                规则：
                1. 若原文有编号（如"1."、"①"），保留编号和完整正文
                2. 若内容项包含选项或子段落，保留在同一项内
                3. 编号缺失时按上下文顺序推断
                4. 不要合并多个内容项、不要拆分单个内容项
                5. 空白或无法识别的段落跳过，不产出内容项
                6. 内容项顺序必须和原文一致
                """
            )

            let response = try await session.respond(
                to: trimmed,
                generating: ExtractedQuestionsPayload.self
            )

            return response.content.questions.map {
                ExtractedQuestionItem(
                    text: $0.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    ordinal: max(1, $0.ordinal)
                )
            }
        } catch {
            SnapDrillLogger.generic.error("AI 题目分割失败: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - FoundationModels 结构化输出

@Generable
struct ExtractedQuestionsPayload {
    @Guide(
        description: "从文档中提取的独立题目列表，按原文顺序返回",
        .maximumCount(50)
    )
    var questions: [ExtractedQuestionPayload]
}

@Generable
struct ExtractedQuestionPayload {
    @Guide(description: "题目完整文本，包含题号（如有）和题干，保留原文格式")
    var text: String
    @Guide(description: "题目序号，从 1 开始；若原文有题号则沿用")
    var ordinal: Int
}

// MARK: - Mock

/// 题目分割服务 Mock（测试用，@MainActor 隔离替代 @unchecked Sendable）
@MainActor
public final class QuestionSplittingServiceMock: QuestionSplittingServiceProtocol {
    public var splitResult: [ExtractedQuestionItem] = []
    public var splitCallCount = 0
    public var lastReceivedText: String?

    public init() {}

    public func split(documentText text: String) async -> [ExtractedQuestionItem] {
        splitCallCount += 1
        lastReceivedText = text
        return splitResult
    }
}
