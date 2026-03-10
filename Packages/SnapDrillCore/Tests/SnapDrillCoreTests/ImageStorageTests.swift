//
//  ImageStorageTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/03/10.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ImageStorage 文件 I/O 与缩放逻辑测试。

import Testing
import Foundation
#if canImport(UIKit)
import UIKit
#endif
@testable import SnapDrillCore

@Suite("ImageStorage 单元测试")
struct ImageStorageTests {

    private let storage = ImageStorage()

    // MARK: - deleteImage

    @Test("deleteImage 删除已存在的文件")
    func deleteImage_existingFile_removesIt() async throws {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesDir = documentsURL.appendingPathComponent("images")
        try fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)

        let filename = "test_delete_\(UUID().uuidString).jpg"
        let fileURL = imagesDir.appendingPathComponent(filename)
        try Data("fake image".utf8).write(to: fileURL)
        #expect(fileManager.fileExists(atPath: fileURL.path))

        try await storage.deleteImage(path: "images/\(filename)")
        #expect(!fileManager.fileExists(atPath: fileURL.path))
    }

    @Test("deleteImage 文件不存在时静默返回")
    func deleteImage_nonexistentFile_noError() async throws {
        try await storage.deleteImage(path: "images/nonexistent_\(UUID().uuidString).jpg")
    }

    // MARK: - loadImage

    @Test("loadImage 路径无效时返回 nil")
    func loadImage_invalidPath_returnsNil() {
        let result = storage.loadImage(path: "images/does_not_exist.jpg")
        #expect(result == nil)
    }

    // MARK: - resizedIfNeeded & saveImage（UIKit 平台）

    #if canImport(UIKit)
    @Test("resizedIfNeeded 长边未超限时返回原图")
    func resizedIfNeeded_withinLimit_returnsOriginal() {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 200), format: format)
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 200))
        }

        let result = ImageStorage.resizedIfNeeded(image, maxLongSide: 2000)
        #expect(result === image)
    }

    @Test("resizedIfNeeded 长边超限时等比缩放到目标像素")
    func resizedIfNeeded_exceedsLimit_scalesDown() {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 2000), format: format)
        let image = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 3000, height: 2000))
        }

        let result = ImageStorage.resizedIfNeeded(image, maxLongSide: 2000)
        let resultPixelWidth = result.size.width * result.scale
        let resultPixelHeight = result.size.height * result.scale
        let longSide = max(resultPixelWidth, resultPixelHeight)

        #expect(abs(longSide - 2000) <= 1)
        let ratio = resultPixelWidth / resultPixelHeight
        #expect(abs(ratio - 1.5) < 0.01)
    }

    @Test("resizedIfNeeded 高 scale 图片按物理像素计算")
    func resizedIfNeeded_highScale_usesPixelDimensions() {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 800), format: format)
        let image = renderer.image { ctx in
            UIColor.green.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 800, height: 800))
        }

        #expect(image.scale == 3.0)
        let result = ImageStorage.resizedIfNeeded(image, maxLongSide: 2000)
        let resultLongSide = max(result.size.width * result.scale, result.size.height * result.scale)
        #expect(abs(resultLongSide - 2000) <= 1)
    }

    @Test("resizedIfNeeded 输出 scale 为 1.0")
    func resizedIfNeeded_outputScale_isOne() {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2000, height: 1000), format: format)
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 2000, height: 1000))
        }

        let result = ImageStorage.resizedIfNeeded(image, maxLongSide: 2000)
        #expect(result.scale == 1.0)
    }

    @Test("saveImage 保存后 loadImage 可读回")
    func saveImage_thenLoad_roundTrip() async throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 50, height: 50), format: format)
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 50, height: 50))
        }

        let path = try await storage.saveImage(image)
        #expect(path.hasPrefix("images/"))
        #expect(path.hasSuffix(".jpg"))

        let loaded = storage.loadImage(path: path)
        #expect(loaded != nil)

        // 清理
        try await storage.deleteImage(path: path)
    }
    #endif
}
