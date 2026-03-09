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
@MainActor
func seedDefaultTaxonomy(repos: RepositoryContainer) throws {
    let subject = SubjectModel(name: "数学", icon: "function", colorHex: "#FF0000", sortOrder: 0)
    try repos.subject.insertAndSave(subject)

    let source = SourceModel(name: "试卷")
    try repos.source.insertAndSave(source)

    let grade = GradeModel(name: "三年级")
    try repos.grade.insertAndSave(grade)
}
