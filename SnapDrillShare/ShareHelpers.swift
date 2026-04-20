//
//  ShareHelpers.swift
//  SnapDrillShare
//
//  Created by NotBad Labs on 2026/04/20.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Share Extension 内部纯函数与可注入 helper，便于单元测试覆盖关键路径。
//

import UIKit
import os

// MARK: - 图像降采样

/// 防 Share Extension OOM 的图像降采样工具。
///
/// Extension 内存预算约 120MB，5000x8000 原图解码后约 160MB，必然 OOM。
/// JPEG 编码前必须把长边压到 maxDimension 以内。
@MainActor
enum ShareImageDownsampler {
    /// 若图片长边 ≤ maxDimension 直接返回原图，否则按比例缩到长边 = maxDimension。
    ///
    /// renderer 显式用 scale=1，确保 1 point = 1 pixel：
    /// 默认会用屏幕 scale（如 3x），结果 JPEG 像素是 maxDimension × 3，OOM 防护失效。
    static func resizeIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - URL Scheme 构造

/// 构造主 App 唤起 URL（snapdrill://share?file=<name>）。
///
/// 用 URLComponents 而非字符串拼接，自动处理 percent-encoding，
/// 防止文件名含 `&` `?` 等特殊字符时 URL 被截断。
enum ShareDeepLinkBuilder {
    static let defaultScheme = "snapdrill"
    static let defaultHost = "share"
    static let fileQueryKey = "file"

    /// 构造 deep link URL。空文件名返回 nil。
    static func makeURL(
        fileName: String,
        scheme: String = defaultScheme,
        host: String = defaultHost
    ) -> URL? {
        guard !fileName.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [URLQueryItem(name: fileQueryKey, value: fileName)]
        return components.url
    }
}

// MARK: - 共享容器写入

/// 把 NSItemProvider 返回的 item 写入 App Groups 共享容器。
///
/// 优先级：URL（直接拷贝，零内存解码）→ Data（直接写入字节）→ UIImage（降采样后 JPEG 编码）。
/// 全程避免大图原始解码以防 Extension OOM。
///
/// 通过注入 `containerURLProvider` 与 `fileNameProvider` 可在测试中用临时目录替代真实 App Group。
@MainActor
struct SharedContainerImageWriter {
    typealias ContainerURLProvider = @MainActor (String) -> URL?
    typealias FileNameProvider = @MainActor () -> String

    private let appGroupID: String
    private let containerURLProvider: ContainerURLProvider
    private let fileNameProvider: FileNameProvider
    private let downsampleMaxDimension: CGFloat
    private let logger: Logger?

    init(
        appGroupID: String = "group.com.snapdrill.app",
        containerURLProvider: @escaping ContainerURLProvider = { id in
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
        },
        fileNameProvider: @escaping FileNameProvider = { Self.makeFileName() },
        downsampleMaxDimension: CGFloat = 2048,
        logger: Logger? = nil
    ) {
        self.appGroupID = appGroupID
        self.containerURLProvider = containerURLProvider
        self.fileNameProvider = fileNameProvider
        self.downsampleMaxDimension = downsampleMaxDimension
        self.logger = logger
    }

    /// 默认文件名生成：UUID + .jpg
    static func makeFileName(id: UUID = UUID()) -> String {
        id.uuidString + ".jpg"
    }

    /// 把 item 写入容器，返回文件名（成功）或 nil（失败）。
    func save(item: NSSecureCoding?) -> String? {
        guard let containerURL = containerURLProvider(appGroupID) else {
            logger?.error("无法获取 App Groups 共享容器路径")
            return nil
        }

        let fileName = fileNameProvider()
        let destURL = containerURL.appendingPathComponent(fileName)

        if let url = item as? URL {
            return copyFromURL(url, to: destURL, fileName: fileName)
        }

        if let data = item as? Data {
            return writeData(data, to: destURL, fileName: fileName)
        }

        if let image = item as? UIImage {
            return encodeAndWrite(image, to: destURL, fileName: fileName)
        }

        logger?.warning("无法从 item 中提取图片数据")
        return nil
    }

    private func copyFromURL(_ url: URL, to destURL: URL, fileName: String) -> String? {
        do {
            try FileManager.default.copyItem(at: url, to: destURL)
            logger?.info("通过文件拷贝保存图片: \(fileName)")
            return fileName
        } catch {
            logger?.error("文件拷贝失败: \(error.localizedDescription)")
            return nil
        }
    }

    private func writeData(_ data: Data, to destURL: URL, fileName: String) -> String? {
        do {
            try data.write(to: destURL, options: .atomic)
            logger?.info("通过 Data 直接写入保存图片: \(fileName)")
            return fileName
        } catch {
            logger?.error("Data 写入失败: \(error.localizedDescription)")
            return nil
        }
    }

    private func encodeAndWrite(_ image: UIImage, to destURL: URL, fileName: String) -> String? {
        let safeImage = ShareImageDownsampler.resizeIfNeeded(image, maxDimension: downsampleMaxDimension)
        guard let data = safeImage.jpegData(compressionQuality: 0.85) else {
            logger?.warning("UIImage JPEG 编码失败")
            return nil
        }
        do {
            try data.write(to: destURL, options: .atomic)
            logger?.info("通过 UIImage fallback 保存图片: \(fileName)")
            return fileName
        } catch {
            logger?.error("UIImage JPEG 写入失败: \(error.localizedDescription)")
            return nil
        }
    }
}
