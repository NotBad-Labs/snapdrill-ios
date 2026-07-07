//
//  ImageStorageTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ImageStorage 文件 I/O 与 ImageIO 下采样逻辑测试。

import Testing
import Foundation
import UIKit
import ImageIO
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
        #expect(storage.loadImage(path: "/etc/hosts") == nil)
        #expect(storage.loadImage(path: #"images\evil.jpg"#) == nil)
    }

    @Test("imageFileURL 返回已保存图片 URL 且拒绝路径穿越")
    func imageFileURL_existingFileAndTraversal() async throws {
        let path = try await storage.saveImage(createTestImage(width: 50, height: 50))
        defer { try? FileManager.default.removeItem(at: testDir) }

        let url = try #require(storage.imageFileURL(path: path))
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(storage.imageFileURL(path: "../outside.jpg") == nil)
        #expect(storage.imageFileURL(path: "/tmp/outside.jpg") == nil)
    }

    @Test("loadImage 拒绝路径穿越读取越界图片")
    func loadImage_rejectsTraversalToExistingOutsideImage() throws {
        let outsideURL = testDir.deletingLastPathComponent()
            .appendingPathComponent("outside_\(UUID().uuidString).jpg")
        defer { try? FileManager.default.removeItem(at: outsideURL) }

        let imageData = try #require(ImageStorage.compressedJPEGData(
            from: createTestImage(width: 10, height: 10),
            maxLongSide: 20,
            quality: 0.8
        ))
        try imageData.write(to: outsideURL)

        #expect(storage.loadImage(path: "../\(outsideURL.lastPathComponent)") == nil)
        #expect(storage.loadDownsampledImage(path: "../\(outsideURL.lastPathComponent)") == nil)
    }

    @Test("deleteImage 拒绝路径穿越删除越界文件")
    func deleteImage_rejectsTraversalToExistingOutsideFile() async throws {
        let outsideURL = testDir.deletingLastPathComponent()
            .appendingPathComponent("delete_victim_\(UUID().uuidString).jpg")
        defer { try? FileManager.default.removeItem(at: outsideURL) }

        try Data("do-not-delete".utf8).write(to: outsideURL)
        #expect(FileManager.default.fileExists(atPath: outsideURL.path))

        try await storage.deleteImage(path: "../\(outsideURL.lastPathComponent)")

        #expect(FileManager.default.fileExists(atPath: outsideURL.path))
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

    // MARK: - 隐私铁律：EXIF GPS 剥离（AGENTS「图片入库前经 ImageStorage 剥离 EXIF GPS/位置信息」）

    @Test("compressedJPEGData 剥离 EXIF GPS 位置元数据（隐私铁律）")
    func compressedJPEGData_stripsGPSLocation() throws {
        // 构造一张确实带 GPS 的源 JPEG（模拟用户从相册选入的带定位照片）
        let withGPS = try makeJPEGWithGPS(width: 120, height: 80)
        // 前置自检：源 JPEG 必须真的带 GPS 字典，否则后续断言无意义（防 tautology）
        try #require(gpsDictionary(of: withGPS) != nil, "测试前置失败：构造的源 JPEG 应携带 GPS 字典")

        let image = try #require(UIImage(data: withGPS))

        // 无缩放路径：长边未超限，直接 CGImageDestination 编码
        let small = try #require(ImageStorage.compressedJPEGData(from: image, maxLongSide: 2000, quality: 0.8))
        #expect(gpsDictionary(of: small) == nil, "无缩放路径输出不得包含 GPS 位置元数据")

        // 缩放路径：长边超限，走 ImageIO 下采样后再编码
        let scaled = try #require(ImageStorage.compressedJPEGData(from: image, maxLongSide: 64, quality: 0.8))
        #expect(gpsDictionary(of: scaled) == nil, "缩放路径输出不得包含 GPS 位置元数据")
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

    /// 构造一张写入了 GPS EXIF 字典的纯色 JPEG，用于验证后续编码剥离位置信息。
    private func makeJPEGWithGPS(width: Int, height: Int) throws -> Data {
        let image = createTestImage(width: CGFloat(width), height: CGFloat(height))
        let cgImage = try #require(image.cgImage)

        let data = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil)
        )
        let gps: [CFString: Any] = [
            kCGImagePropertyGPSLatitude: 37.7749,
            kCGImagePropertyGPSLatitudeRef: "N",
            kCGImagePropertyGPSLongitude: 122.4194,
            kCGImagePropertyGPSLongitudeRef: "W"
        ]
        let properties: [CFString: Any] = [kCGImagePropertyGPSDictionary: gps]
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }

    /// 读回 JPEG Data 的 GPS 字典（无则返回 nil）。
    private func gpsDictionary(of data: Data) -> [CFString: Any]? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }
        return properties[kCGImagePropertyGPSDictionary] as? [CFString: Any]
    }
}
