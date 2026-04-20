//
//  ShareHelpersTests.swift
//  SnapDrillShareTests
//
//  Created by NotBad Labs on 2026/04/20.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  覆盖 SnapDrillShare 内部 helper 三类风险：OOM 防护（降采样）、
//  URL Scheme 构造（防 query 截断）、共享容器写入（URL/Data/UIImage 三路径 + 失败兜底）。
//
//  注：测试 target 与 SnapDrillShare 共享 ShareHelpers.swift 源文件，
//  不依赖 .appex 链接，规避了 app extension 不能作为 unit test bundle target 的限制。
//

import Testing
import UIKit
import Foundation

// MARK: - ShareImageDownsampler

@MainActor
@Suite("ShareImageDownsampler")
struct ShareImageDownsamplerTests {
    /// 测试用图显式 scale=1，避免模拟器默认屏幕 scale（如 iPhone 17 = 3x）
    /// 让 point 与 pixel 数值脱节，干扰 pixel-based 降采样断言。
    private static func makeImage(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    @Test("小图（小于阈值）保持原尺寸")
    func smallImageReturnsOriginal() {
        let image = Self.makeImage(width: 1024, height: 768)
        let result = ShareImageDownsampler.resizeIfNeeded(image, maxDimension: 2048)
        #expect(result.size == CGSize(width: 1024, height: 768))
    }

    @Test("临界尺寸（等于阈值）不缩放")
    func exactThresholdReturnsOriginal() {
        let image = Self.makeImage(width: 2048, height: 1000)
        let result = ShareImageDownsampler.resizeIfNeeded(image, maxDimension: 2048)
        #expect(result.size == CGSize(width: 2048, height: 1000))
    }

    @Test("大正方形图缩到长边等于 maxDimension")
    func largeSquareScalesToMaxDimension() {
        let image = Self.makeImage(width: 4096, height: 4096)
        let result = ShareImageDownsampler.resizeIfNeeded(image, maxDimension: 2048)
        let longSide = max(result.size.width, result.size.height)
        #expect(abs(longSide - 2048) < 1.0)
    }

    @Test("大长方形图保持宽高比")
    func largeLandscapePreservesAspectRatio() {
        let image = Self.makeImage(width: 4000, height: 2000)
        let result = ShareImageDownsampler.resizeIfNeeded(image, maxDimension: 2048)
        let ratio = result.size.width / result.size.height
        let longSide = max(result.size.width, result.size.height)
        #expect(abs(ratio - 2.0) < 0.01)
        #expect(longSide <= 2048.5)
    }

    /// 关键反例：image.size 是 point（1500），但 image.scale=3 → 物理像素 4500。
    /// 旧实现按 point 判断会 guard pass（1500 < 2048）直接返回原图，
    /// JPEG 编码时仍按物理 4500 像素，OOM 防护失效。
    /// 新实现按 pixel 判断必须触发降采样，确保输出像素 ≤ maxDimension。
    @Test("scale=3 高密度图按 pixel 而非 point 判断")
    func highDensityImageUsesPixelThreshold() throws {
        // 用 format.scale=3 构造 1500 point × scale 3 = 4500 pixel 的 UIImage
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1500, height: 1000), format: format).image { ctx in
            UIColor.orange.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1500, height: 1000))
        }
        // 前置断言：确认构造的 image 真的是 scale=3
        #expect(image.scale == 3)
        let result = ShareImageDownsampler.resizeIfNeeded(image, maxDimension: 2048)
        // 输出像素长边应 ≤ 2048（验证：用了 pixel 判断 + scale=1 输出）
        let outputPixelLongSide = max(result.size.width * result.scale, result.size.height * result.scale)
        #expect(outputPixelLongSide <= 2048.5)
    }
}

// MARK: - ShareDeepLinkBuilder

@Suite("ShareDeepLinkBuilder")
struct ShareDeepLinkBuilderTests {
    @Test("有效 UUID 文件名构造 snapdrill://share?file=...")
    func validUUIDFilename() throws {
        let raw = "550E8400-E29B-41D4-A716-446655440000.jpg"
        let url = try #require(ShareDeepLinkBuilder.makeURL(fileName: raw))
        #expect(url.scheme == "snapdrill")
        #expect(url.host == "share")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems?.first?.value == raw)
    }

    @Test("特殊字符 percent-encode 后可解码回原值")
    func specialCharactersPercentEncoded() throws {
        let raw = "a b&c?.jpg"
        let url = try #require(ShareDeepLinkBuilder.makeURL(fileName: raw))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems?.first?.value == raw)
    }

    @Test("空文件名返回 nil")
    func emptyFilenameReturnsNil() {
        #expect(ShareDeepLinkBuilder.makeURL(fileName: "") == nil)
    }
}

// MARK: - SharedContainerImageWriter

@MainActor
@Suite(.serialized)
struct SharedContainerImageWriterTests {
    private static func makeWriter(
        tempDir: URL,
        fileName: String = "test.jpg",
        downsampleMax: CGFloat = 2048
    ) -> SharedContainerImageWriter {
        SharedContainerImageWriter(
            appGroupID: "test.group",
            containerURLProvider: { _ in tempDir },
            fileNameProvider: { fileName },
            downsampleMaxDimension: downsampleMax,
            logger: nil
        )
    }

    private static func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func makeJPEGData(width: CGFloat, height: CGFloat, color: UIColor) throws -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { ctx in
            color.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return try #require(image.jpegData(compressionQuality: 0.85))
    }

    @Test("URL 路径：拷贝源文件到容器")
    func urlPathCopiesFile() throws {
        let tempDir = try Self.makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcData = try Self.makeJPEGData(width: 100, height: 100, color: .blue)
        let srcURL = tempDir.appendingPathComponent("source.jpg")
        try srcData.write(to: srcURL)

        // 容器用 tempDir 的子目录，避免源文件与目标文件路径冲突
        let containerDir = tempDir.appendingPathComponent("container")
        try FileManager.default.createDirectory(at: containerDir, withIntermediateDirectories: true)
        let writer = SharedContainerImageWriter(
            appGroupID: "test.group",
            containerURLProvider: { _ in containerDir },
            fileNameProvider: { "dest.jpg" },
            downsampleMaxDimension: 2048,
            logger: nil
        )

        let result = writer.save(item: srcURL as NSURL)
        #expect(result == "dest.jpg")
        let destURL = containerDir.appendingPathComponent("dest.jpg")
        #expect(FileManager.default.fileExists(atPath: destURL.path))
    }

    @Test("Data 路径：原始字节写入容器（落盘字节与输入完全一致）")
    func dataPathWritesBytes() throws {
        let tempDir = try Self.makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcData = try Self.makeJPEGData(width: 100, height: 100, color: .green)
        let writer = Self.makeWriter(tempDir: tempDir, fileName: "data.jpg")
        let result = writer.save(item: srcData as NSData)
        #expect(result == "data.jpg")

        let destURL = tempDir.appendingPathComponent("data.jpg")
        let written = try Data(contentsOf: destURL)
        #expect(written == srcData)
    }

    @Test("UIImage fallback：降采样后 JPEG 写入，落盘解码长边 ≤ maxDimension")
    func uiImageFallbackDownsamples() throws {
        let tempDir = try Self.makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcImage = UIGraphicsImageRenderer(size: CGSize(width: 4000, height: 3000)).image { ctx in
            UIColor.purple.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 4000, height: 3000))
        }

        let writer = Self.makeWriter(tempDir: tempDir, fileName: "img.jpg", downsampleMax: 2048)
        let result = writer.save(item: srcImage)
        #expect(result == "img.jpg")

        let destURL = tempDir.appendingPathComponent("img.jpg")
        let writtenData = try Data(contentsOf: destURL)
        let decoded = try #require(UIImage(data: writtenData))
        let longSide = max(decoded.size.width, decoded.size.height)
        #expect(longSide <= 2048.5)
    }

    @Test("容器获取失败：返回 nil")
    func containerUnavailableReturnsNil() throws {
        let writer = SharedContainerImageWriter(
            appGroupID: "test.group",
            containerURLProvider: { _ in nil },
            fileNameProvider: { "x.jpg" },
            downsampleMaxDimension: 2048,
            logger: nil
        )
        let dummy = Data("fake".utf8)
        #expect(writer.save(item: dummy as NSData) == nil)
    }

    @Test("URL 路径源文件不存在：返回 nil（不崩溃 / 不误报成功）")
    func urlPathMissingSourceReturnsNil() throws {
        let tempDir = try Self.makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let missingURL = tempDir.appendingPathComponent("nonexistent.jpg")
        let writer = Self.makeWriter(tempDir: tempDir)
        #expect(writer.save(item: missingURL as NSURL) == nil)
    }
}

// MARK: - 文件名生成

@Suite("makeFileName")
struct MakeFileNameTests {
    @Test("UUID + .jpg 后缀")
    func uuidWithJPGSuffix() {
        let uuid = UUID()
        let name = SharedContainerImageWriter.makeFileName(id: uuid)
        #expect(name == uuid.uuidString + ".jpg")
    }

    @Test("两次调用生成不同文件名")
    func differentUUIDsDifferent() {
        let n1 = SharedContainerImageWriter.makeFileName()
        let n2 = SharedContainerImageWriter.makeFileName()
        #expect(n1 != n2)
    }
}
