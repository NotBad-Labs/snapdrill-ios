//
//  OCRService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  OCR 服务，封装 Vision 框架提供图片文字识别能力。
//

import UIKit
import Vision

/// 光学字符识别服务
///
/// 封装 Apple Vision 框架的 `RecognizeTextRequest`（iOS 18+ Swift-native API），
/// 提供异步的图片文字识别能力。
///
/// ## 功能
/// - 支持多语言识别（中文、英文）。
/// - 自动进行语言校正。
/// - 使用 `.accurate` 模式以确保最高识别率。
public actor OCRService: OCRServiceProtocol {

    // MARK: - Initialization

    /// 创建 OCR 服务实例
    public init() {}

    // MARK: - Public API

    /// 异步执行文本识别任务。
    ///
    /// - Parameter cgImage: 包含文字的图片（推荐经过文档扫描校正后的图片）
    /// - Returns: 识别出的所有文本，按行拼接，以换行符 `\n` 分隔
    /// - Throws: `OCRError` 如果识别请求失败
    public func recognizeText(from cgImage: CGImage) async throws -> String {
        // Swift-native Vision API（iOS 18+），无需 continuation 和 callback
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        // 中英文混合场景下显式指定优于自动检测，避免中文试卷上的英文被误判为全英文档
        request.recognitionLanguages = [.init(identifier: "zh-Hans"), .init(identifier: "en-US")]

        let observations = try await request.perform(on: cgImage)
        let recognizedStrings = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
        return recognizedStrings.joined(separator: "\n")
    }
}

/// OCR 识别操作错误
public enum OCRError: Error {
    /// 传入的图片无效或无法被 Vision 框架处理
    case invalidImage
}
