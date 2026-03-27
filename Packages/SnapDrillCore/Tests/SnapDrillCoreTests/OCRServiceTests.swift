//
//  OCRServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  OCR 服务单元测试，依赖 UIKit 渲染测试图片，仅在 iOS 环境下运行。
//

import Testing
import UIKit
@testable import SnapDrillCore

struct OCRServiceTests {

    private func createSolidColorImage(size: CGSize, color: UIColor) throws -> CGImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        guard let cgImage = image.cgImage else { throw NSError(domain: "test", code: -1) }
        return cgImage
    }

    private func createTextImage(text: String, size: CGSize = CGSize(width: 300, height: 100)) throws -> CGImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            (text as NSString).draw(in: textRect, withAttributes: attributes)
        }
        guard let cgImage = image.cgImage else { throw NSError(domain: "test", code: -1) }
        return cgImage
    }

    // MARK: - Core Functionality

    @Test("验证清晰的文字图片能够被正确识别出内容，防范连白板图片都通过的假象")
    func recognizeStandardText() async throws {
        let service = OCRService()
        let cgImage = try createTextImage(text: "Hello World")

        let result = try await service.recognizeText(from: cgImage)

        // 我们不再使用毫无意义的 XCTAssertNotNil(result)。
        // OCR 至少要把部分文字抠出来，即便不是完美的，也应该包含核心词。
        #expect(result.contains("Hello") || result.contains("World"), "OCR 连非常基础的 Hello World 都未能解析。返回结果: \(result)")
    }

    // MARK: - Boundary Conditions

    @Test("极端：分辨率极小（如 1x1 或 10x10）毫无特征的点不可识别，应静默返回空而不崩溃")
    func recognizeMicroNoisyImage() async throws {
        let service = OCRService()
        let microImage = try createSolidColorImage(size: CGSize(width: 5, height: 5), color: .black)

        let result = try await service.recognizeText(from: microImage)
        #expect(result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @Test("纯空白图片：解析应快速退出并返回空字符串")
    func recognizeEmptyWhiteImage() async throws {
        let service = OCRService()
        let blankImage = try createSolidColorImage(size: CGSize(width: 500, height: 500), color: .white)

        let result = try await service.recognizeText(from: blankImage)
        #expect(result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
