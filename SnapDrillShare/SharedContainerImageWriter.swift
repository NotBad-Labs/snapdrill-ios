//
//  SharedContainerImageWriter.swift
//  SnapDrillShare
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Share Extension 共享容器写入：URL/Data/UIImage 三段路径，全程避免大图原始解码以防 OOM。
//

import UIKit
import os

/// 把 NSItemProvider 返回的 item 写入 App Groups 共享容器。
///
/// 优先级：URL → Data → UIImage，三条路径均先降采样再写入 JPEG。
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
        guard let data = ShareImageDownsampler.downsampledJPEGData(
            from: url,
            maxDimension: downsampleMaxDimension,
            compressionQuality: 0.85
        ) else {
            logger?.error("URL 图片降采样失败: \(url.lastPathComponent)")
            return nil
        }
        do {
            try data.write(to: destURL, options: .atomic)
            logger?.info("通过 URL 降采样保存图片: \(fileName)")
            return fileName
        } catch {
            logger?.error("URL 降采样图片写入失败: \(error.localizedDescription)")
            return nil
        }
    }

    private func writeData(_ data: Data, to destURL: URL, fileName: String) -> String? {
        guard let safeData = ShareImageDownsampler.downsampledJPEGData(
            from: data,
            maxDimension: downsampleMaxDimension,
            compressionQuality: 0.85
        ) else {
            logger?.error("Data 图片降采样失败")
            return nil
        }
        do {
            try safeData.write(to: destURL, options: .atomic)
            logger?.info("通过 Data 降采样保存图片: \(fileName)")
            return fileName
        } catch {
            logger?.error("Data 降采样图片写入失败: \(error.localizedDescription)")
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
