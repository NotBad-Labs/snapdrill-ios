//
//  ImageStorageTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/03/10.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ImageStorage 文件 I/O 与 ImageIO 下采样逻辑测试。

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

    // MARK: - compressedJPEGData & saveImage（UIKit 平台）

    #if canImport(UIKit)
    @Test("compressedJPEGData 长边未超限时直接编码不缩放")
    func compressedJPEGData_withinLimit_noResize() throws {
        let image = createTestImage(width: 100, height: 200)

        let data = try #require(ImageStorage.compressedJPEGData(from: image, maxLongSide: 2000, quality: 0.8))
        let decoded = try #require(UIImage(data: data))

        #expect(abs(decoded.size.width - 100) <= 1)
        #expect(abs(decoded.size.height - 200) <= 1)
    }

    @Test("compressedJPEGData 长边超限时通过 ImageIO 下采样")
    func compressedJPEGData_exceedsLimit_scalesDown() throws {
        let image = createTestImage(width: 3000, height: 2000)

        let data = try #require(ImageStorage.compressedJPEGData(from: image, maxLongSide: 2000, quality: 0.8))
        let decoded = try #require(UIImage(data: data))

        let longSide = max(decoded.size.width, decoded.size.height)
        #expect(abs(longSide - 2000) <= 1)
        let ratio = decoded.size.width / decoded.size.height
        #expect(abs(ratio - 1.5) < 0.02)
    }

    @Test("compressedJPEGData 高 scale 图片按物理像素计算")
    func compressedJPEGData_highScale_usesPixelDimensions() throws {
        let image = createTestImage(width: 800, height: 800, scale: 3.0)
        // 物理像素 2400x2400，应触发缩放
        #expect(image.scale == 3.0)

        let data = try #require(ImageStorage.compressedJPEGData(from: image, maxLongSide: 2000, quality: 0.8))
        let decoded = try #require(UIImage(data: data))

        let longSide = max(decoded.size.width, decoded.size.height)
        #expect(abs(longSide - 2000) <= 1)
    }

    @Test("saveImage 保存后 loadImage 可读回")
    func saveImage_thenLoad_roundTrip() async throws {
        let image = createTestImage(width: 50, height: 50)

        let path = try await storage.saveImage(image)
        #expect(path.hasPrefix("images/"))
        #expect(path.hasSuffix(".jpg"))

        let loaded = storage.loadImage(path: path)
        #expect(loaded != nil)

        // 清理
        try await storage.deleteImage(path: path)
    }

    // MARK: - Test Helpers

    private func createTestImage(width: CGFloat, height: CGFloat, scale: CGFloat = 1.0) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
    #endif
}
