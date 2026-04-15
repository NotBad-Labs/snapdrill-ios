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
import UIKit
@testable import SnapDrillCore

@Suite("ImageStorage 单元测试")
struct ImageStorageTests {

    // 使用临时目录隔离测试，避免依赖 UserDefaults.activeProfileId
    private let testDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageStorageTests_\(UUID().uuidString)")
    private var storage: ImageStorage { ImageStorage(baseDirectory: testDir) }

    // MARK: - deleteImage

    @Test("deleteImage 删除已存在的文件")
    func deleteImage_existingFile_removesIt() async throws {
        let fileManager = FileManager.default
        let imagesDir = testDir.appendingPathComponent("images")
        try fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)

        let filename = "test_delete_\(UUID().uuidString).jpg"
        let fileURL = imagesDir.appendingPathComponent(filename)
        try Data("fake image".utf8).write(to: fileURL)
        #expect(fileManager.fileExists(atPath: fileURL.path))

        try await storage.deleteImage(path: "images/\(filename)")
        #expect(!fileManager.fileExists(atPath: fileURL.path))

        // 清理
        try? fileManager.removeItem(at: testDir)
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

    // MARK: - compressedJPEGData & saveImage

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
        #expect(image.scale == 3.0)

        let data = try #require(ImageStorage.compressedJPEGData(from: image, maxLongSide: 2000, quality: 0.8))
        let decoded = try #require(UIImage(data: data))

        let longSide = max(decoded.size.width, decoded.size.height)
        #expect(abs(longSide - 2000) <= 1)
    }

    @Test("saveImage 保存后 loadImage 可读回")
    func saveImage_thenLoad_roundTrip() async throws {
        let path = try await storage.saveImage(createTestImage(width: 50, height: 50))
        #expect(path.hasPrefix("images/"))
        #expect(path.hasSuffix(".jpg"))

        let loaded = storage.loadImage(path: path)
        #expect(loaded != nil)

        // 清理
        try await storage.deleteImage(path: path)
        try? FileManager.default.removeItem(at: testDir)
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
}
