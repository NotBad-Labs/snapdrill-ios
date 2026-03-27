//
//  TestHelpers.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/03/09.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ViewModel 测试共用辅助工具：Mock 对象、Seed 函数。
//

import Foundation
import UIKit
@testable import SnapDrillCore
@testable import SnapDrillData
@testable import SnapDrillFeatureCapture

// MARK: - Polling Helper

/// 轮询等待条件满足，替代 Task.sleep 固定等待
///
/// 每 10ms 检查一次条件，条件满足立即返回；超时则抛出错误。
/// 比固定 sleep 更确定性（条件满足即返回）且更快（不必等满固定时长）。
///
/// - Parameters:
///   - timeout: 最大等待时间（默认 2 秒，覆盖 CI 慢速场景）
///   - description: 超时时的错误描述
///   - condition: 检查条件闭包
func waitUntil(
    timeout: Duration = .seconds(2),
    _ description: String = "条件未在超时前满足",
    condition: @escaping () -> Bool
) async throws {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        guard ContinuousClock.now < deadline else {
            struct WaitTimeoutError: Error, CustomStringConvertible {
                let description: String
            }
            throw WaitTimeoutError(description: description)
        }
        try await Task.sleep(for: .milliseconds(10))
    }
}

// MARK: - Image Helper

/// 创建 1x1 测试图片（无文件 IO）
func createTestImage() -> UIImage {
    UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
    let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    UIGraphicsEndImageContext()
    return image
}

// MARK: - Mock OCR Service

/// OCR 服务 Mock（可配置返回值和错误）
final class MockOCRServiceShared: OCRServiceProtocol, @unchecked Sendable {
    // @unchecked Sendable：测试专用 Mock，单线程 @MainActor 环境下安全
    var recognizeTextResult: String = ""
    var recognizeTextError: Error?
    var recognizeTextCallCount = 0

    func recognizeText(from image: CGImage) async throws -> String {
        recognizeTextCallCount += 1
        if let error = recognizeTextError {
            throw error
        }
        return recognizeTextResult
    }
}

// MARK: - Seed Helpers

/// 在 Repository 中插入默认学科、来源和年级（多数 ViewModel 测试需要）
func seedDefaultTaxonomy(repos: RepositoryContainer) throws {
    let subject = SubjectModel(name: "数学", icon: "function", colorHex: "#FF0000", sortOrder: 0)
    try repos.subject.insertAndSave(subject)

    let source = SourceModel(name: "试卷")
    try repos.source.insertAndSave(source)

    let grade = GradeModel(name: "三年级")
    try repos.grade.insertAndSave(grade)
}
