//
//  OCRServiceMock.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  OCR 服务 Mock 实现，用于单元测试和 SwiftUI Preview。
//

import CoreGraphics
import Foundation

/// OCR 服务 Mock 实现
///
/// 不依赖 Vision 框架，按调用前注入的 `simulatedText` / `simulatedDocument` 返回固定结果。
/// 适用于单元测试与 Preview。
public actor OCRServiceMock: OCRServiceProtocol {

    public var simulatedText: String
    public var simulatedDocument: DocumentRecognitionResult
    public var simulatedError: Error?

    /// `recognizeText` 调用次数
    public private(set) var recognizeTextCallCount = 0

    /// `recognizeDocument` 调用次数
    public private(set) var recognizeDocumentCallCount = 0

    public init(
        simulatedText: String = "",
        simulatedDocument: DocumentRecognitionResult = .empty,
        simulatedError: Error? = nil
    ) {
        self.simulatedText = simulatedText
        self.simulatedDocument = simulatedDocument
        self.simulatedError = simulatedError
    }

    public func recognizeText(from cgImage: CGImage) async throws -> String {
        recognizeTextCallCount += 1
        if let error = simulatedError { throw error }
        return simulatedText
    }

    public func recognizeDocument(from cgImage: CGImage) async throws -> DocumentRecognitionResult {
        recognizeDocumentCallCount += 1
        if let error = simulatedError { throw error }
        return simulatedDocument
    }

    public func setSimulatedText(_ text: String) {
        simulatedText = text
    }

    public func setSimulatedError(_ error: Error?) {
        simulatedError = error
    }
}
